<#
# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
.SYNOPSIS
    Import Object Metadata from a CSV
.DESCRIPTION
    This script will import metadata into Active Directory. It targets Users, Groups, and the Group Membership for both Users and Groups. It is intended for use in a greenfield environment. 
.PARAMETER UsersCSV
    This is the location of the CSV containing the user metadata.
.PARAMETER GroupsCSV
    This is the location of the CSV containing the groups metadata. 
.PARAMETER GroupMembersCSV
    This is the location of the CSV containing the group membership metadata.
.NOTES
    Author: Coaldric 05AUG2022
#>

[Cmdletbinding(SupportsShouldProcess)]
param(
    [Parameter(ValueFromPipeline = $true, HelpMessage = "Select the corrected Users CSV")]
    [String[]]$UsersCSV = $null,

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Select the corrected Groups CSV")]
    [String[]]$GroupsCSV = $null,

    [Parameter(ValueFromPipeline = $true, HelpMessage = "Select the Group Membership CSV")]
    [String[]]$GroupMembersCSV = $null
)

$UserCount          = New-Object System.Collections.ArrayList
$GroupCount         = New-Object System.Collections.ArrayList
$GroupCreatedCount  = New-Object System.Collections.ArrayList
$GroupMembersCount  = New-Object System.Collections.ArrayList

if ($null -eq $UsersCSV) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'Comma Seperated File (CSV) (*.csv)|*.csv'
        Title            = 'Select the corrected Users CSV'
    }
    $Result = $Dialog.ShowDialog()
    
    if ($Result -eq 'OK') {

        Try {
           $Users = Import-Csv -Path $Dialog.FileName
        }
        Catch {
            $Users = $null
            Break
        }
    }
    else {
        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}

if ($null -eq $GroupsCSV) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'Comma Seperated File (CSV) (*.csv)|*.csv'
        Title            = 'Select the corrected Groups CSV'
    }
    $Result = $Dialog.ShowDialog()
    
    if ($Result -eq 'OK') {

        Try {
            $Groups = Import-Csv -Path $Dialog.FileName
        }
        Catch {
            $Groups = $null
            Break
        }
    }
    else {
        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}

if ($null -eq $GroupMembersCSV) {

    Add-Type -AssemblyName System.Windows.Forms

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'Comma Seperated File (CSV) (*.csv)|*.csv'
        Title            = 'Select the corrected Groups CSV'
    }
    $Result = $Dialog.ShowDialog()
    
    if ($Result -eq 'OK') {

        Try {
            $GroupMembers = Import-Csv -Path $Dialog.FileName
        }
        Catch {
            $GroupMembers = $null
            Break
        }
    }
    else {
        #Shows upon cancellation of Save Menu
        Write-Host -ForegroundColor Yellow "Notice: No file(s) selected."
        Break
    }
}

Write-Output "Importing Users"
Write-Host "Importing Users"
foreach ($User in $Users) {
    $UserData = @{
        Name                    = $User.Name
        SamAccountName          = $User.SamAccountName
        UserPrincipalName       = $User.UserPrincipalName
        City                    = $User.City
        Company                 = $User.Company
        Country                 = $User.Country
        Department              = $User.Department
        Description             = $User.Description
        DisplayName             = $User.DisplayName
        EmailAddress            = $User.EmailAddress
        EmployeeNumber          = $User.EmployeeNumber
        GivenName               = $User.GivenName
        Initials                = $User.Initials
        OfficePhone             = $User.OfficePhone
        OtherName               = $User.OtherName
        PostalCode              = $User.PostalCode
        State                   = $User.State
        StreetAddress           = $User.StreetAddress
        Surname                 = $User.Surname
        Title                   = $User.Title
        Path                    = $User.Path
        AccountPassword         = (ConvertTo-SecureString "P@55w0rd4U" -AsPlainText -force)
        Enabled                 = $True
        PasswordNeverExpires    = $False
        changepasswordatlogon   = $true
        }
New-ADUser @UserData -PassThru
$UserCount.Add($user.UserPrincipalName) | Out-Null
}
Write-Output Created $UserCount.count Users
Write-Host Created $UserCount.count Users

foreach ($Group in $Groups){
    try{
    Get-ADGroup $Group.name
    $GroupCount.Add($Group.Name) | Out-Null
    }
    catch{
    New-ADGroup -Name $Group.Name -Path $Group.Path -GroupCategory $Group.GroupCategory -GroupScope $Group.GroupScope -ManagedBy $Group.ManagedBy
    $GroupCreatedCount.add($Group.Name) | Out-Null
    }
}
Write-Output Verified $GroupCount.count Groups
Write-Host Verified $GroupCount.count Groups

Write-Output Created $GroupCreatedCount.count Groups
Write-Host Created $GroupCreatedCount.count Groups

foreach ($GroupMember in $GroupMembers){
    Add-ADGroupMember -Identity $GroupMember.Group -Members $GroupMember.Member
    $GroupMembersCount.add($GroupMember.Member)
}
Write-Output Updated $GroupMembersCount.count Group Memberships
Write-Host Updated $GroupMembersCount.count Group Memberships

