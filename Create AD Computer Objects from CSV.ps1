<#
# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
.SYNOPSIS
    Create AD computer objects from a CSV
.DESCRIPTION
    This script will create computer objects in Active Directory based on information provided in a CSV. 
.PARAMETER ComputersCSV
    This is the location of the CSV containing the computer names and locations. 
.NOTES
    Author: Coaldric 13OCT2022
#>

[Cmdletbinding(SupportsShouldProcess)]
param(
    [Parameter(ValueFromPipeline = $true, HelpMessage = "Select the corrected Computers CSV")]
    [String[]]$ComputersCSV = $null
)

$ComputerCount = New-Object System.Collections.ArrayList

if ($null -eq $ComputerCSV) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'Comma Seperated File (CSV) (*.csv)|*.csv'
        Title            = 'Select the CSV that contains your computer object information to be created'
    }
    $Result = $Dialog.ShowDialog()
    
    if ($Result -eq 'OK') {

        Try {
            $Computers = Import-Csv -Path $Dialog.FileName
        }
        Catch {
            $Computers = $null
            Break
        }
    }
    else {
        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}


Write-Output "Creating Computer Objects"
Write-Host "Creating Computer Objects"
foreach ($Computer in $Computers) {
    $ComputerData = @{
        Name                    = $User.Name
        SamAccountName          = $User.SamAccountName
        Path                    = $User.Path
        Enabled                 = $True
        PasswordNeverExpires    = $False
        }
New-ADComputer @ComputerData -PassThru
$ComputerCount.Add($computer.SamAccountName) | Out-Null
}
Write-Output Created $ComputerCount.count Computer Objects
Write-Host Created $ComputerCount.count Computer Objects

