<#
# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
.SYNOPSIS
    Check and set MaxOfflineTimeinDays on all online DCs in the domain
.DESCRIPTION
    This script will set the maximum offline time in days for content freshness protention (MaxOfflineTimeinDays) to 365 days. This script should
    be run from a domain controller. WinRM must be enabled for this script to work. 
.NOTES
    Author: Coaldric 28NOV2022
#>

#Start transciption for logging
Start-Transcript

#Get domain controllers in domain
$domaincontrollers = (Get-ADDomain).ReplicaDirectoryServers

#Clear error log
$Error.Clear()

#Begin for each loop through domain controllers
foreach ( $domaincontroller in $domaincontrollers ) {
    ##Clear variables for each loop
    Clear-Variable GetMaxOfflineTimeinDays
    Clear-Variable MaxOfflineTimeInDays
    Clear-Variable GetNewMaxOfflineTimeinDays
    try {
        ###Try getting the MaxOfflineTimeinDays
        $GetMaxOfflineTimeinDays = Get-CimInstance -Namespace ROOT/microsoftdfs -ComputerName  $domaincontroller -Query "Select MaxOfflineTimeinDays from DfsrMachineConfig" -ErrorAction Stop | select-object MaxOfflineTimeInDays,PScomputerName
    } catch {
        ###Catch if unable to remotely capture the MaxOfflineTimeinDays value
        write-output "Error running Get-CimInstance on $domaincontroller. Please verify that WinRM is enabled and configured."
    }
    ##If try fails, this variable will be null
    if ( $GetMaxOfflineTimeinDays ) {
        $MaxOfflineTimeInDays = $GetMaxOfflineTimeinDays.MaxOfflineTimeInDays
        ###If MaxOfflineTimeinDays is NOT 365, set it to 365
        if ( $MaxOfflineTimeInDays -ne 365 )
        {
            try {
                Set-CimInstance -Namespace ROOT/microsoftdfs -ComputerName $domaincontroller -Query "Select MaxOfflineTimeInDays from DfsrMachineConfig" -Property @{MaxOfflineTimeInDays=365} -ErrorAction Stop
                $GetNewMaxOfflineTimeinDays = Get-CimInstance -Namespace ROOT/microsoftdfs -ComputerName  $domaincontroller -Query "Select MaxOfflineTimeinDays from DfsrMachineConfig" -ErrorAction Stop | select-object MaxOfflineTimeInDays,PScomputerName
                $NewMaxOfflineTimeInDays = $GetNewMaxOfflineTimeinDays.MaxOfflineTimeInDays
                write-output "MaxOfflineTimeInDays on $domaincontroller has changed from $MaxOfflineTimeInDays days to $NewMaxOfflineTimeInDays days"
            } catch {
                write-output "Error running Set-CimInstance on $domaincontroller. Please verify that WinRM is enabled and configured."
            }
        } else {
            write-output "MaxOfflineTimeInDays on $domaincontroller is already set to $MaxOfflineTimeInDays days."
        } 
    } else {
        write-output "Couldn't get the value of MaxOfflineTimeinDays from $domaincontroller."
    }
}
#Stop Transcription
Stop-Transcript