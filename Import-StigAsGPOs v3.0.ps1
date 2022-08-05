<#
.SYNOPSIS
    Import GPOs from DISA for STIG compliance. 
.DESCRIPTION
    Import GPOs, WMI Filters, and Administrative Templates from DISA for STIG compliance. 
.PARAMETER CompressedZip
    This is the file path of the compressed zip file downloaded from cyber.mil/stigs/gpo.
.PARAMETER STIGPath
    This symbolic link will target the extracted files from the zip.
.NOTES
    Author: Coaldric 2/4/2020
    Collaborators: JBear 5/24/2018 - Created the original script Import-STIGgpo (https://github.com/Average-Bear/Import-STIGgpo)
                   Joe Prox 7/15/2013 - Created the function New-SymLink (https://gallery.technet.microsoft.com/scriptcenter/New-SymLink-60d2531e)
                   Jake Dean 2/4/2020 - Assisted with troubleshooting
                   Tim Medina 2/4/2020 - Assisted with troubleshooting
                   Dan Zinger 2/4/2020 - Assisted with troubleshooting
    Change Log:    
    Removed Migration Table and Backup Support. 
    Added function to create symbolic link without calling mklink.exe (function created by Boe Prox)     
    Added function to select zip file and extract it. Then create a symbolic link to the extracted files which shortens the paths and avoids errors due to paths exceeding maximums.
    Added function to stage SYSVOL by copying Administrative Templats from the local repo (C:\Windows\PolicyDefinitions) and the Administrative Templates extracted from the zip to the SYSVOL.
    Added function to import WMI Filters from extracted files. 
    Upcoming Changes
    Would like to add more info so the user can see what's being imported in each stage and if everything was successful. 
    Would like to add try/catch for areas where failures can occur. 
    Paths could be cleaned up a bit, currently using relitave paths in a lot of locations (e.g. $path\..); It works, but it isn't ideal. 
    Could link the WMI Filters to each cooresponding GPO
    Clean up; remove symobolic link/deleted extracted folders 

    I'd like to add a bunch of functionality to mine. Like, run the script, it asks you if you want to use a migration table and then it creates one for you automatically based on your domain information (DISA focused for my script)
I'm not really interested in adding any sort of linking, but the wmi filters I think should apply to all applicable GPOs. So I need to figure out that piece as well
And then checking for changes between import and existing gpos if they share the same name
I want to avoid an issue where they use the tool and they wipe out settings they've changed in the DISA gpos from before (since you know some folks will do that)
and further more, carry those changes forward if wanted
and maybe have a EZ mode and an Advance mode where EZ is just the basic import
#>

[Cmdletbinding(SupportsShouldProcess)]
param(
    [Parameter(ValueFromPipeline = $true, HelpMessage = "Select Compressed DISA STIGs")]
    [String[]]$compressedzip = $null,

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Enter STIG Directory")]
    [String[]]$STIGPath = "C:\Import-STIGasGPO",

    [ValidateSet("True", "False", 0, 1, "Yes", "Y", "No", "N")]
    [ValidateNotNullOrEmpty()]
    [string]$ImportAdminTemplates = "True",

    [ValidateSet("True", "False", 0, 1, "Yes", "Y", "No", "N")]
    [ValidateNotNullOrEmpty()]
    [string]$ImportWMIFilters = "True",

    [ValidateSet("True", "False", 0, 1, "Yes", "Y", "No", "N")]
    [ValidateNotNullOrEmpty()]
    [string]$ImportDISAGPOs = "True",

    [ValidateSet("True", "False", 0, 1, "Yes", "Y", "No", "N")]
    [ValidateNotNullOrEmpty()]
    [string]$NewCentralStore = "True",

    [ValidateSet("True", "False", 0, 1, "Yes", "Y", "No", "N")]
    [ValidateNotNullOrEmpty()]
    [string]$ConnectWMIFilterstoGPOs = "True",

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Enter Desired Domain")]
    [String[]]$Domain = (Get-ADDomainController).Domain,

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Enter Desired Forest")]
    [String[]]$Forest = (Get-ADDomainController).Forest
)
#transcript for logging purpases
Start-Transcript "C:\Import-STIG-Log.txt" -Verbose

#Import required modules
Import-Module ActiveDirectory
import-module GroupPolicy

#Convert switch values to boolean
function ConvertStringToBoolean ([string]$value) {
    $value = $value.ToLower();

    switch ($value) {
        "true" { return $true; }
        "1" { return $true; }
        "yes" { return $true; }
        "y" { return $true; }
        "false" { return $false; }
        "0" { return $false; }
        "no" { return $false; }
        "n" { return $false; }
    }
}

#variables
[bool]$ImportAdminTemplates     =   ConvertStringToBoolean($ImportAdminTemplates)
[bool]$ImportWMIFilters         =   ConvertStringToBoolean($ImportWMIFilters)
[bool]$ImportDISAGPOs           =   ConvertStringToBoolean($ImportDISAGPOs)
[bool]$NewCentralStore          =   ConvertStringToBoolean($NewCentralStore)
[bool]$ConnectWMIFilterstoGPOs  =   ConvertStringToBoolean($ConnectWMIFilterstoGPOs)

#prompts user to select the compressed ZIP Path
if ($null -eq $compressedzip) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'Compressed (zipped) Folder (*.zip)|*.zip'
        Title            = 'Select the Zip file downloaded from Cyber.Mil'
    }
    $Result = $Dialog.ShowDialog()
    
    if ($Result -eq 'OK') {

        Try {
            
            Expand-Archive -LiteralPath $dialog.FileName -DestinationPath "C:\Import-STIGasGPO" -force
            $STIGPath = "C:\Import-STIGasGPO"
        }
        Catch {

            $compressedzip = $null
            Break
        }
    }
    else {

        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}

#Create Migration Table
Function New-Migrationtable {

#Variables
$domainadmins = "$domain\Domain Admins"
$enterpriseadmins = "$forest\Enterprise Admins"
$Filename = "importstiggpos.migtable"
$migrationtable = $STIGPath + "\" + $Filename
$migtablecontent = @'
<?xml version="1.0" encoding="utf-16"?>
<MigrationTable xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.microsoft.com/GroupPolicy/GPOOperations/MigrationTable">
  <Mapping>
    <Type>Unknown</Type>
    <Source>ADD YOUR DOMAIN ADMINS</Source>
    <Destination>REPLACEDOMAIN</Destination>
  </Mapping>
  <Mapping>
    <Type>Unknown</Type>
    <Source>ADD YOUR ENTERPRISE ADMINS</Source>
    <Destination>REPLACEENTERPRISE</Destination>
  </Mapping>
</MigrationTable>
'@

New-Item -Path $STIGPath -Name $Filename -Force

Add-Content $migrationtable $migtablecontent

(Get-Content $migrationtable) -replace "REPLACEDOMAIN",$domainadmins | Set-content $migrationtable 
(Get-Content $migrationtable ) -replace "REPLACEENTERPRISE",$enterpriseadmins | Set-content $migrationtable 

}

#Create Central Store
#Need to add switch
#Need to add overwrite warnings/catches

function New-CentralStore {
$defaultDefPath = "C:\Windows\PolicyDefinitions\"
$domainDefPath = "\\$domain\SYSVOL\$domain\Policies\PolicyDefinitions"

    if ((test-path $domainDefPath) -eq $false ) {
        Write-Host -ForegroundColor Green "`tCopying Policy Definitions"
        $null = copy-item -path $defaultDefPath -Destination $domainDefPath -Recurse
    }

}
#Import ADMX/ADMLs to Central Store
#Need to add switch
function Import-AdministrativeTemplates {
    $AdminTypes = Get-ChildItem -Path $STIGPath -Directory | Where-object { $_.name -like "ADMX Templates" }
    
    foreach ($AdminType in $AdminTypes) 
    {
        $adminTemplates = (Get-ChildItem -Path "$($AdminType.fullName)\*\" -Recurse).FullName
        
        # Import Administrative Templates
        Write-Host -ForegroundColor Green "`t`tImporting Administrative Template Files."
    
        foreach ($adminTemplate in $adminTemplates ) 
        {

            $null = Copy-Item -Path "$adminTemplate" -Include "*.admx" -Destination "$domainDefPath"
            $null = Copy-Item -Path "$adminTemplate"-include "*.adml" -Destination "$domainDefPath\en-us"
        }
    }
}
#Import WMI Filters
#Need to add switch
function Import-WMIFilters {
    
    $StigTypes = Get-ChildItem -Path $STIGPath -Directory | Where-object { $_.name -notlike "ADMX Templates" }
    foreach ($STIGType in $StigTypes ) 
    {
        $wmiFilters = (Get-ChildItem -Path "$($STIGType.fullName)\WMI*\*").FullName

        foreach ($wmiFilter in $wmiFilters) 
        {
            (Get-Content $WMIFilter) -replace "security.local", "$domain" | Set-Content $WMIFilter 
            (Get-Content $WMIFilter) -replace "gpoimport.local", "$domain" | Set-Content $WMIFilter 

            # Import WMI Filters
            Write-Host -ForegroundColor Green "`t`tImporting WMI Filters"
            $null = mofcomp -N:root\Policy $WMIFilter
        }
    }   
}
#Import GPOs from the DISA Package
#Need to add switch
#Need to add functionality to check versions of GPOs and ask for over writes (55 Conflicts found, would you like to overwrite the existing GPOs? If You choose NO, you will be asked if you'd like to Choose for each, If No, operation will cancel)
#Might be able to check the file size of the CSVs to determin which GPOs have changed
function Import-DISAGPOs {
    $StigTypes = Get-ChildItem -Path $STIGPath -Directory | Where-object { $_.name -notlike "ADMX Templates" }
    foreach ( $STIGType in $StigTypes ) 
    {
        $gpofiles = (Get-ChildItem -Directory -Path "$($STIGType.fullname)\GPOs\*").FullName
        foreach ( $GPO in $gpofiles ) 
        {
            [XML]$XML = (Get-Content $GPO\Backup.xml)
            $GPOName = $((Select-XML -XML $XML -XPath "//*").Node.DisplayName.'#cdata-section')
            
            Write-Host -ForegroundColor Yellow "`tImporting $GPOName"

            # Import Group Policy Object
            Write-Host -ForegroundColor Green "`t`tImporting Group Policy Object"
            $null = Import-GPO -Domain $($Domain) -BackupGpoName $GPOName -TargetName $GPOName -Path $GPO\.. -CreateIfNeeded -MigrationTable $migrationtable
        }
    }
}

#Connect WMI Filters to GPOs - Untested
#Need to add switch
#need to validate the function to make it work
#-------------------------------------------------------------
function Connect-WMIFilters {
    param([String]$BackupLocation,[String]$LogFile);

    # Get the script path
    $ScriptPath = {Split-Path $MyInvocation.ScriptName}
    
    if ([String]::IsNullOrEmpty($BackupLocation))
    {
        $BackupLocation = $(&$ScriptPath) + "\GPOs\Backups";
    }
    
    $Manifest = $BackupLocation + "\manifest.xml";
    
    if ([String]::IsNullOrEmpty($LogFile))
    {
        $LogFile = $(&$ScriptPath) + "\LinkWMIFilters.txt";
    }
    set-content $LogFile $NULL;
    
    #-------------------------------------------------------------
    Write-Host -ForegroundColor Green "Importing the PowerShell modules..."
    
    # Import the Active Directory Module
    Import-Module ActiveDirectory -WarningAction SilentlyContinue
    if($Error.Count -eq 0) {
       #Write-Host "Successfully loaded Active Directory Powershell's module" -ForeGroundColor Green
    }else{
       Write-Host "Error while loading Active Directory Powershell's module : $Error" -ForeGroundColor Red
       exit
    }
    
    # Import the Group Policy Module
    Import-Module GroupPolicy -WarningAction SilentlyContinue
    if($Error.Count -eq 0) {
       #Write-Host "Successfully loaded Group Policy Powershell's module" -ForeGroundColor Green
    }else{
       Write-Host "Error while loading Group Policy Powershell's module : $Error" -ForeGroundColor Red
       exit
    }
    write-host " "
    
    #-------------------------------------------------------------
    
    $myDomain = [System.Net.NetworkInformation.IpGlobalProperties]::GetIPGlobalProperties().DomainName;
    $DomainDn = "DC=" + [String]::Join(",DC=", $myDomain.Split("."));
    $SystemContainer = "CN=System," + $DomainDn;
    $GPOContainer = "CN=Policies," + $SystemContainer;
    $WMIFilterContainer = "CN=SOM,CN=WMIPolicy," + $SystemContainer;
    
    try
    {
        if (![System.DirectoryServices.DirectoryEntry]::Exists("LDAP://" + $DomainDN))
        {
            write-host -ForegroundColor Red "Could not connect to LDAP path $DomainDN";
            write-host -ForegroundColor Red "Exiting Script";
            return;
        }
    }
    catch
    {
            write-host -ForegroundColor Red "Could not connect to LDAP path $DomainDN";
            write-host -ForegroundColor Red "Exiting Script";
            return;
    }
    
    # Get the current date
    get-Date | Out-File $LogFile
    
    [xml]$ManifestData = get-content $Manifest
    
    foreach ($item in $ManifestData.Backups.BackupInst) {
      $WMIFilterDisplayName = $NULL;
      $GPReportPath = $BackupLocation + "\" + $item.ID."#cdata-section" + "\gpreport.xml";
      [xml]$GPReport = get-content $GPReportPath;
      $WMIFilterDisplayName = $GPReport.GPO.FilterName;
      if ($WMIFilterDisplayName -ne $NULL) {
        $GPOName = $GPReport.GPO.Name;
        $GPO = Get-GPO $GPOName;
        $WMIFilter = Get-ADObject -Filter 'msWMI-Name -eq $WMIFilterDisplayName';
        $WMIFilterName = $WMIFilter.Name;
        $GPODN = "CN={" + $GPO.Id + "}," + $GPOContainer;
        $WMIFilterLinkValue = "[$myDomain;" + $WMIFilterName + ";0]";
        Try {
            Set-ADObject $GPODN -Add @{gPCWQLFilter=$WMIFilterLinkValue};
          }
        Catch {
            # Under some situations I've found that Set-ADObject will fail with the error: 
            # "Multiple values were specified for an attribute that can have only one value".
            # So we capture the error and retry using the -Replace parameter instead of the
            # -Add parameter.
            Set-ADObject $GPODN -Replace @{gPCWQLFilter=$WMIFilterLinkValue};
          }
        $Message = "The '$WMIFilterDisplayName' WMI Filter has been linked to the following GPO: $GPOName"
        write-host -ForeGroundColor Green $Message
        $Message | Out-File $LogFile -append
      }
    }
}


#Old Import function - only for reference
function Import-STIGasGPO {
    [Cmdletbinding(SupportsShouldProcess)]
    Param()

    $gpoTotal = 0
    Write-Host -ForegroundColor Yellow "`n`nBeginning Group Policy Object Import."
    
    # Import Policy Definitions
    $defaultDefPath = "C:\Windows\PolicyDefinitions\"
    $domainDefPath = "C:\Windows\SYSVOL\sysvol\$domain\PolicyDefinitions"

    if ((test-path $domainDefPath) -eq $false ) {
        Write-Host -ForegroundColor Green "`tCopying Policy Definitions"
        $null = copy-item -path $defaultDefPath -Destination $domainDefPath -Recurse
    
    }

    # Import STIG GPOs
    $StigTypes = Get-ChildItem -Path $STIGPath -Directory | Where-object { $_.name -notlike "ADMX Templates" }

    foreach ($STIGType in $StigTypes ) {
        $gpofiles = (Get-ChildItem -Directory -Path "$($STIGType.fullname)\GPOs\*").FullName
        $wmiFilters = (Get-ChildItem -Path "$($STIGType.fullName)\WMI*\*").FullName
        $GpoTotal += $gpofiles.count 

        Write-Host -ForegroundColor Yellow "Importing $($gpofiles.count) Group Policy objects for $($stigType.basename)" 
        
        foreach ($GPO in $gpofiles ) {
            [XML]$XML = (Get-Content $GPO\Backup.xml)
            $GPOName = $((Select-XML -XML $XML -XPath "//*").Node.DisplayName.'#cdata-section')
            
            Write-Host -ForegroundColor Yellow "`tImporting $GPOName"

            # Import Group Policy Object
            Write-Host -ForegroundColor Green "`t`tImporting Group Policy Object"
            $null = Import-GPO -Domain $($Domain) -BackupGpoName $GPOName -TargetName $GPOName -Path $GPO\.. -CreateIfNeeded -MigrationTable $migrationtable
        }

        foreach ($wmiFilter in $wmiFilters) {
            (Get-Content $WMIFilter) -replace "security.local", "$domain" | Set-Content $WMIFilter 
            (Get-Content $WMIFilter) -replace "gpoimport.local", "$domain" | Set-Content $WMIFilter 

            # Import WMI Filters
            Write-Host -ForegroundColor Green "`t`tImporting WMI Filters"
            $null = mofcomp -N:root\Policy $WMIFilter
           
        }
        $AdminTypes = Get-ChildItem -Path $STIGPath -Directory | Where-object { $_.name -like "ADMX Templates" }
    
        foreach ($AdminType in $AdminTypes) {
            $adminTemplates = (Get-ChildItem -Path "$($AdminType.fullName)\*\" -Recurse).FullName
            
            # Import Administrative Templates
            Write-Host -ForegroundColor Green "`t`tImporting Administrative Template Files."
        
            foreach ($adminTemplate in $adminTemplates ) {

                $null = Copy-Item -Path "$adminTemplate" -Include "*.admx" -Destination "$domainDefPath"
                $null = Copy-Item -Path "$adminTemplate"-include "*.adml" -Destination "$domainDefPath\en-us"
            }
        
        }
    }
       

    Write-Host -ForegroundColor Green "`n`nGroup Policy Import Complete!"
    Write-Host -ForegroundColor Green "Total GPOs Imported - $GpoTotal"
    Write-Host -ForegroundColor yellow "Performing Final Cleanup Actions: Removing all items stored under $STIGPath"        
}

#Calls functions; Import-STIGasGPO supports -WhatIf

if($ImportDISAGPOs -eq $true){New-Migrationtable}
if($NewCentralStore -eq $true){New-CentralStore}
if($ImportAdminTemplates -eq $true){Import-AdministrativeTemplates}
if($ImportWMIFilters -eq $true){Import-WMIFilters}
if($ImportDISAGPOs -eq $true){Import-DISAGPOs}
if($ConnectWMIFilterstoGPOs -eq $true){Connect-WMIFilters}

#Import-STIGasGPO
remove-item $STIGPath -Recurse
Stop-Transcript
Pause
clear-host