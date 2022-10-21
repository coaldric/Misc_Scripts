$time = get-date -Format ddMMMyy
$labname = "NotMyLab"
$domain = "123.ORG.AS.COM"

$addressspace = '12.12.0.0/16'
$firsttwooctets = $addressspace.Substring(0,5)
                                                                                                                                                                    
New-LabDefinition -name $labname -DefaultVirtualizationEngine HyperV -VmPath C:\AutomatedLab-VMs                                                                                                                        
Add-LabVirtualNetworkDefinition -Name $labname -AddressSpace $addressspace
Add-LabDomainDefinition -Name $domain -AdminUser 'notmyusername' -AdminPassword 'notmypassword'
Set-LabInstallationCredential -Username 'notmyusername' -Password 'notmypassword'

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:Memory' = 2048MB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Standard (Desktop Experience)'
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:DnsServer2' = "$firsttwooctets.10.10"
}                                                                                                                           

$VAROOT = Get-LabMachineRoleDefinition -Role RootDC @{
    DomainFunctionalLevel = 'Win2012R2'
    ForestFunctionalLevel = 'Win2012R2'
    SiteName = 'VA'
    SiteSubnet = "$firsttwooctets.10.0/24"
}

$VA = Get-LabMachineRoleDefinition -Role DC @{
    SiteName = 'VA'
}


$CA = Get-LabMachineRoleDefinition -Role DC @{
    SiteName = 'CA'
    SiteSubnet = "$firsttwooctets.30.0/24"
}

$DE = Get-LabMachineRoleDefinition -Role DC @{
    SiteName = 'DE'
    SiteSubnet = "$firsttwooctets.20.0/24"
}


#DCs
Add-LabMachineDefinition -name VADC1-$time -Roles $VAROOT -IpAddress "$firsttwooctets.10.10" -DnsServer1 "$firsttwooctets.10.10" -DnsServer2 "$firsttwooctets.10.11"
Add-LabMachineDefinition -name VADC2-$time -Roles $VA -IpAddress "$firsttwooctets.10.11" -DnsServer1 "$firsttwooctets.10.11" 
Add-LabMachineDefinition -name CADC1-$time -Roles $CA -IpAddress "$firsttwooctets.20.10" -DnsServer1 "$firsttwooctets.20.10"
Add-LabMachineDefinition -name CADC2-$time -Roles $CA -IpAddress "$firsttwooctets.20.11" -DnsServer1 "$firsttwooctets.20.11"
Add-LabMachineDefinition -name DEDC1-$time -Roles $DE -IpAddress "$firsttwooctets.30.10" -DnsServer1 "$firsttwooctets.30.10" 

#FSs
Add-LabMachineDefinition -name CAFS1-$time -Roles FileServer -IpAddress "$firsttwooctets.20.30" -DnsServer1 "$firsttwooctets.20.10" -DnsServer2 "$firsttwooctets.20.11"

#Clients
Add-LabMachineDefinition -name VAWK1-$time -OperatingSystem 'Windows 10 Pro' -IpAddress "$firsttwooctets.10.100" -IsDomainJoined -DnsServer1 "$firsttwooctets.10.10" -Memory 1GB

#install the lab
Install-Lab

#get lab after reboot
#get-lab -List
import-lab $labname

#get labvm rdp files
Get-LabVMRdpFile -All
