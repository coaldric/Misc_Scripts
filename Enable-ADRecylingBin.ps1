#set variables
$domain = Get-ADDomain
$domaindn = $domain.DistinguishedName
$domainname = $domain.name

Enable-ADOptionalFeature –Identity "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$domaindn" -Scope ForestOrConfigurationSet -Target "$domainname"