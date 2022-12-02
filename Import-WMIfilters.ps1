$domain = (Get-ADDomainController).Domain

$wmiFilters = (Get-ChildItem -Path "C:\Temp\Oct 22 DISA STIG GPO Package 1012\mof").FullName

foreach ($wmiFilter in $wmiFilters) {
            (Get-Content $WMIFilter) -replace "security.local", "$domain" | Set-Content $WMIFilter 
            (Get-Content $WMIFilter) -replace "gpoimport.local", "$domain" | Set-Content $WMIFilter 

            # Import WMI Filters
            Write-Host -ForegroundColor Green "`t`tImporting WMI Filters"
            $null = mofcomp -N:root\Policy $WMIFilter
           
}