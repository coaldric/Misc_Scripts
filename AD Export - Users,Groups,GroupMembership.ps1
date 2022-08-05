<#
# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

.SYNOPSIS
    Export Object Metadata into CSV
.DESCRIPTION
    This script will export metadata from Active Directory. It targets Users, Groups, and the Group Membership for both Users and Groups. It will create a CSV file that can be used for importing to a new greenfield enviornment. 
.PARAMETER OU
    This is the DistinguishedName of the top level Organizational Unit that the users targeted for migration are located in. 
.PARAMETER Path
    This is the litteral path where the data will be exported to. 
.NOTES
    Author: Coaldric 05AUG2022
#>

[Cmdletbinding(SupportsShouldProcess)]
param(
    [Parameter(ValueFromPipeline = $true, HelpMessage = "What is the DN of the top level OU where the target users are located? Example: (OU=Test Accounts,DC=fabrikam,DC=com)")]
    [string]$OU     = "OU=Test Accounts,DC=contoso,DC=com",

    [Parameter(ValueFromPipeline = $false)]
    [string]$OUPath = "AD:\$OU",

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Where will the data be exported? Example: (C:\ExportData)")]
    [string]$Path   = "C:\ExportData"
)
    
$OUConfirm = Read-Host "OU Selected: $OU Is this correct? [y/n]"
if ( $OUConfirm -match "[yY]" ) {
} else {
    $OU = Read-Host "Please enter the target OU Distinguished Name (Example:`"OU=Test Accounts,DC=fabrikam,DC=com`")"
    $OU = $OU.trim('"')
    $OUPath = "AD:\$OU"
} 

#Test Path
if (-not (Test-Path -LiteralPath $Path)) {
    try {
        New-Item -Path $Path -ItemType Directory -Force  -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Write-Error -Message "Unable to create Directory '$Path'. Error was $_" -ErrorAction Stop
    }
} else {
Write-Output "Files will be exported here: $Path"
}

#Set File Paths
$UserPath         = $Path + '\' + 'Users.csv'
$GroupsPath       = $Path + '\' + 'Groups.csv'
$GroupMembersPath = $Path + '\' + 'GroupMembers.csv'

#Test OU Path
if (-not (Test-Path $OUPath)) {
    Write-Error -Message "OU Supplied $OU is invalid." -ErrorAction Stop
} else {
    Write-Output "Users, Groups, and Group Memberships will be exported from $OU"
}

#Gather Data
$Users          = Get-ADUser -Filter "enabled -eq '$true'" -SearchBase $OU -Properties * | Select-Object -Property City,Company,Country,Department,Description,DisplayName,DistinguishedName,EmailAddress,EmployeeNumber,GivenName,Initials,Name,OfficePhone,OtherName,PostalCode,SamAccountName,State,StreetAddress,Surname,Title,UserPrincipalName
$Groups         =  Get-ADGroup -Filter * -SearchBase $OU -Properties * 
$GroupMembers   = foreach ($Group in $Groups) {
    Get-ADGroupMember -Identity $Group | Select-Object @{Name='Group';Expression={$Group.Name}}, @{Name='Member';Expression={$_.SamAccountName}}
}

$UserCount          = ($users).count
$GroupCount         = ($Groups).count
$GroupMembersCount  = ($GroupMembers).count

#Export to CSV    
$Users          | export-csv -Path "$UserPath" -NoTypeInformation 
Write-Output $UserCount Users exported to $UserPath 
Write-Host $UserCount Users exported to $UserPath

$Groups         | Select-Object -Property DistinguishedName,GroupCategory,GroupScope,Name,ManagedBy | Export-Csv -Path $GroupsPath -NoTypeInformation
Write-Output $GroupCount Groups exported to $GroupsPath
Write-Host $GroupCount Groups exported to $GroupsPath

$GroupMembers   | Export-Csv -Path $GroupMembersPath -NoTypeInformation
Write-Output $GroupMembersCount Group Memberships exported to $GroupMembersPath
Write-Host $GroupMembersCount Group Memberships exported to $GroupMembersPath