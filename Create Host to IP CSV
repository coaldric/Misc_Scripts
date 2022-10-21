<#
.SYNOPSIS
    Build a domain specific csv file for ESSP Host Certificate and Key Generation

.DESCRIPTION
    Script Requires AD and DNS PoSH modules. Builds a csv file of all enabled hosts
    that have logged in within the last 30 days with their FQDN and associated IP Address on
    the users Desktop as hosts.csv

.NOTES
    Author: CW2 Samuel Hart, Cody Aldrich (MSFT) - 21SEP2022
    v1.0
#>

#Scripte will only identify clients that have logged in within the last 30 days
$InactiveDate = (Get-Date).AddDays(-30)

#Builds initital array for exportable FQDN and IP content
$ExportableData = New-Object System.Collections.ArrayList

#Query domain for a list of active computers with corresponsing DNS Host Name entries
$ADComputers = Get-ADComputer -Filter {( ObjectClass -eq "Computer") -and (LastLogonTimestamp -gt $InactiveDate) -and (Enabled -eq $true) } | Select-Object -Expand DNSHostName

#Builds an array of exportable data for host and ip for csv creation
ForEach( $ADComputer in $ADComputers ){

    #Build an array of the DNS Forward lookup zone records and associated IP
    $DNSClientData = Resolve-DnsName $ADComputer -Type A -ErrorAction SilentlyContinue | Select-Object Name,IPaddress

    #Build an arrary of only resolvable clients
    if( $null -ne $DNSClientData ){
        $ExportableData.Add($DNSClientData) | out-null
    }
}

#Build and export a csv for ESSP implementation. Header and "s are removed for ease of use within ESSP environments
$ExportableData | ConvertTo-Csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Select-Object -Skip 1 | Set-Content -Path "$env:HOMEPATH\Desktop\hosts.csv"
