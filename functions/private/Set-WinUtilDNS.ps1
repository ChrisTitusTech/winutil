function Set-WinUtilDNS ($DNSProvider) {
    foreach ($Adapter in Get-NetAdapter | Where-Object Status -eq "Up") {
        if ($DNSProvider -eq "DHCP") {
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
            Write-WinUtilLog -Component "DNS" -Message "DNS set to default."
        } else {
            $dns = $sync.configs.dns.$DNSProvider
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $dns.Primary, $dns.Secondary, $dns.Primary6, $dns.Secondary6
            Write-WinUtilLog -Component "DNS" -Message "Setting DNS provider to $DNSProvider.
        }
    }
}
