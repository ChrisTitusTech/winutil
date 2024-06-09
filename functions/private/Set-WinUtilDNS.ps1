function Set-WinUtilDNS {
    <#

    .SYNOPSIS
        Sets the DNS of all interfaces that are in the "Up" state. It will lookup the values from the DNS.Json file

    .PARAMETER DNSProvider
        The DNS provider to set the DNS server to

    .EXAMPLE
        Set-WinUtilDNS -DNSProvider "google"

    #>
    param($DNSProvider)

    $dnsProviders = $sync.configs.dns.PSObject.Properties.Name

    Try{
        $Adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        Write-Host "Ensuring DNS is set to $DNSProvider on the following interfaces"
        Write-Host $($Adapters | Out-String)

        Foreach ($Adapter in $Adapters){
            switch ($DNSProvider) {
                "DHCP" {
                    Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
                }
                "Custom" {
                    $savedSettings = $global:previousDnsSettings | Where-Object { $_.AdapterName -eq $Adapter.Name }
    
                    if ($savedSettings) {
                        # Set the DNS server addresses for the adapter to the saved addresses
                        Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $savedSettings.DnsAddresses
                    }
                }
                default {
                    Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ("$($sync.configs.dns.$DNSProvider.Primary)", "$($sync.configs.dns.$DNSProvider.Secondary)")
                }
            }
        }
    }
    Catch{
        Write-Warning "Unable to set DNS Provider due to an unhandled exception"
        Write-Warning $_.Exception.Message
        Write-Warning $_.Exception.StackTrace
    }
}
