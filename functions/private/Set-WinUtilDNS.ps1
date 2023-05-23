function Set-WinUtilDNS {
    <#
        .DESCRIPTION
        This function sets the DNS of all interfaces in the "Up" state using values from the DNS.Json file.

        .EXAMPLE
        Set-WinUtilDNS -DNSProvider "google"
    #>
    param($DNSProvider)

    if ($DNSProvider -eq "Default") { return }

    try {
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        Write-Host "Setting DNS to $DNSProvider on the following interfaces:"
        $Adapters | Format-Table

        foreach ($Adapter in $Adapters) {
            if ($DNSProvider -eq "DHCP") {
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
            }
            else {
                $PrimaryDNS = $sync.configs.dns.$DNSProvider.Primary
                $SecondaryDNS = $sync.configs.dns.$DNSProvider.Secondary
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ($PrimaryDNS, $SecondaryDNS)
            }
        }
    }
    catch {
        Write-Warning "Unable to set DNS Provider due to an unhandled exception"
        Write-Warning $Error[0].Exception.StackTrace
    }
}
