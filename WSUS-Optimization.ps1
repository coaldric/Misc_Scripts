# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

#transcript for logging purpases
#Start-Transcript "C:\SuperApprove.txt" -Verbose


#Change server name and port number and $True if it is on SSL
#CAA:Corrected spacing
$Computer                       = $env:COMPUTERNAME
$Domain                         = $env:USERDNSDOMAIN
$FQDN                           = "$Computer" + "." + "$Domain"
[String]$updateServer1          = $FQDN
[Boolean]$useSecureConnection   = $False
[Int32]$portNumber              = 8530

#create counters 
#CAA:Updated verbs
$countapprove                   = 0
$countdenied                    = 0

# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")

# Connect to WSUS Server
#CAA:Updated variable names to be easier understood, changed write-host to write-output to allow for transciption
$updateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($updateServer1,$useSecureConnection,$portNumber)

write-output "<<<Connected to $updateserver1 sucessfully>>>"

$updatescope                    = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updates                        = $updateServer.GetUpdates($updatescope)
##$group = $updateServer.GetcomputerTargetGroups() |where {$_.Name -eq 'Download'}
#CAA:Updated functions: Changed variable names were applicable, changed write-host to write-output, standardized quotes, created script counter
Function Approve-Windows10
{
    foreach ($update in $updates)
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -like 'Windows 10, version 1903 and later' -and $update.Title -notlike '*ARM*' -and $update.Title -like '*20H2*' -and $update.Title -notlike '*x86-based*' -and $update.UpdateClassificationTitle -notlike 'Upgrades')
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Approve-Server
{
    foreach ($update in $updates)
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('Windows Server 2019','Windows Server 2016','Windows Server 2012R2') -and $update.Title -notlike '*ARM*')
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Approve-SQL
{
    foreach ($update in $updates)
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('Microsoft SQL Server 2019','Microsoft SQL Server 2017','Microsoft SQL Server 2016','Microsoft SQL Server 2014','Microsoft SQL Server 2012','Microsoft SQL Server Management Studio v17','Microsoft SQL Server Management Studio v18'))
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }

}

Function Approve-Edge
{  
    foreach ($update in $updates)
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('Microsoft Edge') -and $update.Title -like '*x64*' -and $update.Title -notlike '*Dev*' -and $update.Title -notlike '*Beta*')
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Approve-ServerApps
{
    foreach ($update in $updates)
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('1'))
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Approve-Office
{
    foreach ($update in $updates )
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('Office 2013','Office 2016','SharePoint Server 2019/Office Online Server'))
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Approve-Defender
{
    foreach ($update in $updates )
    {
        if ($update.IsSuperseded -ne 'True' -and $update.ProductTitles -in ('Microsoft Defender AntiVirus'))
        {
            write-out "Approved Update: $update.Title" 
            $script:countapprove++
        }
    }
}

Function Deny-Updates
{
    foreach ($update in $updates )
    {
        if ($update.IsSuperseded -eq 'True' -Or $update.Title -like '*Itanium*' -Or $update.Title -like '*Preview*' -Or $update.Title -like '*Only*')
        {
            write-out "Denied Update: $update.Title" 
            $script:countdenied++
        }
    }
}

Function Optimize-WSUS
{
#[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
#$wsus                                      = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
$cleanupScope                               = new-object Microsoft.UpdateServices.Administration.CleanupScope;
# $cleanupScope.DeclineSupersededUpdates    = $true # Performed by CM1906
# $cleanupScope.DeclineExpiredUpdates       = $true # Performed by CM1906
# $cleanupScope.CleanupObsoleteUpdates      = $true # Performed by CM1906
$cleanupScope.CompressUpdates               = $true
#$cleanupScope.CleanupObsoleteComputers     = $true
$cleanupScope.CleanupUnneededContentFiles   = $true
$cleanupManager                             = $updateServer.GetCleanupManager();
$cleanupManager.PerformCleanup($cleanupScope) | Out-File C:\WSUS\WsusClean.txt;
}

Function Approve-Test
{
    foreach ($update in $updates )
    {
        if ($update.Title -like '*KB5010580*')
        {$script:countapprove++}
    }
}


#Run'em
Approve-Windows10
Approve-Server
Approve-SQL
Approve-Office
Deny-Updates
#Optimize-WSUS
#Approve-Test
#Approve-Edge
#Approve-Defender

Write-Output "Total Updates Approved $countapprove"
Write-Output "Total Updates Approved $countdenied"

#write-host $update.State
#write-host $update.PublicationState

trap

{

write-output "Error Occurred"

write-output "Exception Message: "

write-output $_.Exception.Message

write-output $_.Exception.StackTrace

exit

}
#Stop-Transcript
# EOF