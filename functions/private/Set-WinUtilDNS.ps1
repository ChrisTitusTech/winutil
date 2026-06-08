function Set-WinUtilDNS ($DNSProvider) {
    foreach ($Adapter in Get-NetAdapter | Where-Object Status -eq "Up") {
        if ($DNSProvider -eq "DHCP") {
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
            Write-Host "DNS set to default"
        } else {
            $dns = $sync.configs.dns.$DNSProvider
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $dns.Primary, $dns.Secondary, $dns.Primary6, $dns.Secondary6
            Write-Host "DNS set to $DNSProvider"
        }
    }
}
