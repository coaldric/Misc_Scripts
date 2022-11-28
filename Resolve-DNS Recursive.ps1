# The script provided here is not supported under any Microsoft standard support program or service. All scripts are provided
# AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties
# of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or 
# delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample 
# scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

#$stopwatch = [system.diagnostics.stopwatch]::StartNew()
$forwardzones = (Get-DnsServerZone | Where-Object { $_.zonename -ne 'TrustAnchors' -and $_.zonename -notlike "*.in-addr.arpa" }).zonename
$Zones = New-Object System.Collections.ArrayList  
$myobjects = New-Object System.Collections.ArrayList

foreach ($forwardzone in $forwardzones) {
    $dns = Resolve-DnsName -Name $forwardzone -Type NS -DnsOnly -QuickTimeout -ErrorAction Stop
    $childzonenames = Get-DnsServerZoneDelegation -name $forwardzone | where-object { $_.name -ne "." }        
    foreach ($dnsnamehost in $dns.namehost) {   
        if ($null -ne $childzonenames) {
            $Zone = @{
                Connectiontest = (Test-NetConnection $dnsnamehost).PingSucceeded
                Name           = $forwardzone
                NameHost       = $dnsnamehost
                IP             = $IP = (Resolve-DnsName -Name $forwardzone -Type NS -DnsOnly -QuickTimeout -ErrorAction Stop).IPAddress -join ','
                ZoneInfo       = "$forwardzone is a Forward Zone"
            }
            $Zones.add($zone) | out-null
            foreach ($childzonename in $childzonenames) {
                $Zone = @{
                    Connectiontest = (Test-NetConnection $ChildZoneName.NameServer.RecordData.NameServer).PingSucceeded
                    Name           = $ChildZoneName.ChildZoneName
                    NameHost       = $ChildZoneName.NameServer.RecordData.NameServer
                    IP             = $ChildZoneName.IPAddress.RecordData.IPv4Address.IPAddressToString
                    ZoneInfo       = "Child of Parent Zone: $forwardzone"
                }
                $Zones.add($zone) | out-null
            }

        }
            
        else {
            $Zone = @{
                Connectiontest = (Test-NetConnection $dnsnamehost).PingSucceeded
                Name           = $forwardzone
                NameHost       = $dnsnamehost
                IP             = $IP = (Resolve-DnsName -Name $forwardzone -Type NS -DnsOnly -QuickTimeout -ErrorAction Stop).IPAddress -join ','
                ZoneInfo       = "$forwardzone is a Forward Zone"
            }
            $Zones.add($zone) | out-null
        }
    }       
}


foreach ($zone in $Zones) {
    $myobject = [PsCustomObject]@{
        Connected = $zone.Connectiontest
        ZoneName  = $zone.Name
        DNSServer = $zone.NameHost
        IP        = $zone.IP
        ZoneInfo  = $zone.ZoneInfo
    }
    $myobjects.add($myobject) | out-null
}

$myobjects | ft
#$myobjects | ft | Sort-Object -Property Zonename
#$myobject | Export-Csv "C:\Users\Administrator\Desktop\DNS-Info.csv" -NoTypeInformation -Append
#$ipHashes
#$stopwatch.stop()
#$stopwatch.Elapsed.TotalMilliseconds
#$stopwatch.Elapsed.Totalseconds