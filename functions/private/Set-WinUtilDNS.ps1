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

    if($DNSProvider -eq "Default") {
        Write-WinUtilLog -Component "DNS" -Message "DNS provider is Default; no DNS changes applied."
        return
    }

    try {
        $Adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        Write-Host "Ensuring DNS is set to $DNSProvider on the following interfaces:"
        Write-Host $($Adapters | Out-String)
        Write-WinUtilLog -Component "DNS" -Message "Setting DNS provider to $DNSProvider for $(@($Adapters).Count) active adapter(s)."

        if($DNSProvider -ne "DHCP") {
            $dns = $sync.configs.dns.$DNSProvider
            if($null -eq $dns) {
                Write-Warning "DNS provider $DNSProvider was not found in configuration."
                Write-WinUtilLog -Level "ERROR" -Component "DNS" -Message "DNS provider $DNSProvider was not found in configuration."
                return
            }
        }

        $dohSupported = [bool](Get-Command Add-DnsClientDohServerAddress -ErrorAction SilentlyContinue)
        $dnscacheBase = "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters"

        Foreach ($Adapter in $Adapters) {
            $interfaceParams = "$dnscacheBase\$($Adapter.InterfaceGuid)"

            if($DNSProvider -eq "DHCP") {
                Write-WinUtilLog -Component "DNS" -Message "Resetting DNS to DHCP on adapter $($Adapter.Name) (ifIndex: $($Adapter.ifIndex))."
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
                netsh interface ip set dnsservers name="$($Adapter.Name)" source=dhcp
                netsh interface ipv6 set dnsservers name="$($Adapter.Name)" source=dhcp

                if (Test-Path "$interfaceParams\DohInterfaceSettings") {
                    Remove-Item -Path "$interfaceParams\DohInterfaceSettings" -Recurse -Force -ErrorAction SilentlyContinue
                }
            } else {
                Write-WinUtilLog -Component "DNS" -Message "Setting IPv4 DNS on adapter $($Adapter.Name) (ifIndex: $($Adapter.ifIndex)) to $($dns.Primary), $($dns.Secondary)."
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ($dns.Primary, $dns.Secondary)
                Write-WinUtilLog -Component "DNS" -Message "Setting IPv6 DNS on adapter $($Adapter.Name) (ifIndex: $($Adapter.ifIndex)) to $($dns.Primary6), $($dns.Secondary6)."
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ($dns.Primary6, $dns.Secondary6)

                if ($dohSupported -and $dns.DohTemplate) {
                    $ips = @($dns.Primary, $dns.Secondary, $dns.Primary6, $dns.Secondary6) | Where-Object { $_ }
                    foreach ($ip in $ips) {
                        $existing = Get-DnsClientDohServerAddress -ServerAddress $ip -ErrorAction SilentlyContinue
                        if ($existing) {
                            Set-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $dns.DohTemplate -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction SilentlyContinue
                        } else {
                            Write-WinUtilLog -Component "DNS" -Message "Registering DoH template for $ip."
                            Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $dns.DohTemplate -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction SilentlyContinue
                        }
                        
                        $leaf = if ($ip.Contains(':')) { 'Doh6' } else { 'Doh' }
                        $regPath = "$interfaceParams\DohInterfaceSettings\$leaf\$ip"
                        
                        if (-not (Test-Path $regPath)) {
                            New-Item -Path $regPath -Force | Out-Null
                        }
                        New-ItemProperty -Path $regPath -Name "DohFlags" -Value 1 -PropertyType QWord -Force | Out-Null
                    }
                }
            }
        }
        if ($DNSProvider -ne "DHCP" -and $dohSupported -and $dns.DohTemplate) {
            Clear-DnsClientCache
        }
        Write-WinUtilLog -Component "DNS" -Message "DNS provider change completed: $DNSProvider"
    } catch {
        Write-Warning "Unable to set DNS Provider due to an unhandled exception."
        Write-Warning $psitem.Exception.StackTrace
        Write-WinUtilLog -Level "ERROR" -Component "DNS" -Message "Unable to set DNS provider $DNSProvider`: $($psitem.Exception.Message)"
    }
}
