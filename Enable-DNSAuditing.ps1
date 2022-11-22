<#
# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
.SYNOPSIS
    Enable DNS Auditing on ADDS Integrated DNS Zones
.DESCRIPTION
    This script will enable auditing on Zone Creation and Deletion by Everyone in the Forest and Domain DNS Zones. 
.NOTES
    Author: Coaldric 22NOV022
#>

#Import required module
Import-Module ActiveDirectory

#set location to ActiveDirectory
Set-Location AD:

#Get AD Integrated DNS Partition DistinguishedNames
$ForestDNSZoneDN = (Get-ADDomain).subordinatereferences[0]
$DomainDNSZoneDN = (Get-ADDomain).subordinatereferences[1]

#Get ACLs
$ForestACL = Get-Acl -Path "CN=MicrosoftDNS,$ForestDNSZoneDN" -Audit
$DomainACL = Get-Acl -Path "CN=MicrosoftDNS,$DomainDNSZoneDN" -Audit

#Set prinicpal
$Everyone = [Security.Principal.NTAccount]'Everyone'

#Enable auditing for Everyone on DNS Zones
##Create Rules setting Everyone to be audited on any writeproperties and deletions for any objects and child objects
$RuleCreateZone = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($Everyone, 'CreateChild', 'Success', [guid]'e0fa1e8b-9b45-11d0-afdd-00c04fd930c9', [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All, [guid]'00000000-0000-0000-0000-000000000000')
$RuleDeleteZone = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($Everyone, 'ReadProperty, Delete, GenericExecute', 'Success', [guid]'00000000-0000-0000-0000-000000000000', [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents, [guid]'e0fa1e8b-9b45-11d0-afdd-00c04fd930c9')

##Add new rules to ACL
$ForestACL.AddAuditRule($RuleDeleteZone)
$ForestACL.AddAuditRule($RuleCreateZone)

$DomainACL.AddAuditRule($RuleDeleteZone)
$DomainACL.AddAuditRule($RuleCreateZone)

##Set new ACL
Set-Acl -Path "CN=MicrosoftDNS,$ForestDNSZoneDN" -AclObject $ForestACL -verbose
Set-Acl -Path "CN=MicrosoftDNS,$DomainDNSZoneDN" -AclObject $DomainACL -Verbose
