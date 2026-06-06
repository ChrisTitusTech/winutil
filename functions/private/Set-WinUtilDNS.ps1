function Test-WinUtilAdapterDnsIsDhcp {
    param(
        [Parameter(Mandatory)]
        $Adapter
    )

    $interfaceGuid = $Adapter.InterfaceGuid
    if (-not $interfaceGuid) {
        return $false
    }

    $paths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{$interfaceGuid}"
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\{$interfaceGuid}"
    )

    $found = $false
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            continue
        }

        $found = $true
        $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($props -and -not [string]::IsNullOrWhiteSpace($props.NameServer)) {
            return $false
        }
    }

    return $found
}

function Test-WinUtilDnsAddressSetMatch {
    param(
        [string[]]$Current,
        [string[]]$Target
    )

    $normalizedCurrent = @($Current | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object)
    $normalizedTarget = @($Target | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object)

    if ($normalizedCurrent.Count -ne $normalizedTarget.Count) {
        return $false
    }

    for ($i = 0; $i -lt $normalizedCurrent.Count; $i++) {
        if ($normalizedCurrent[$i] -ne $normalizedTarget[$i]) {
            return $false
        }
    }

    return $true
}

function Set-WinUtilDnsClientServerAddress {
    param(
        [Parameter(Mandatory)]
        [int]$InterfaceIndex,
        [string]$AddressFamily,
        [string[]]$ServerAddresses,
        [switch]$ResetServerAddresses
    )

    $params = @{
        InterfaceIndex = $InterfaceIndex
        ErrorAction    = 'SilentlyContinue'
    }

    $command = Get-Command Set-DnsClientServerAddress
    $supportsAddressFamily = $command.Parameters.ContainsKey('AddressFamily')

    if ($ResetServerAddresses) {
        if ($supportsAddressFamily -and $AddressFamily) {
            Set-DnsClientServerAddress @params -AddressFamily $AddressFamily -ResetServerAddresses
        } else {
            Set-DnsClientServerAddress @params -ResetServerAddresses
        }
        return
    }

    if ($supportsAddressFamily -and $AddressFamily) {
        Set-DnsClientServerAddress @params -AddressFamily $AddressFamily -ServerAddresses $ServerAddresses
    } else {
        Set-DnsClientServerAddress @params -ServerAddresses $ServerAddresses
    }
}

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
    if($DNSProvider -eq "Default") {return}
    try {
        $Adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        Write-Host "Ensuring DNS is set to $DNSProvider on the following interfaces:"
        Write-Host $($Adapters | Out-String)

        Foreach ($Adapter in $Adapters) {
            if($DNSProvider -eq "DHCP") {
                if (Test-WinUtilAdapterDnsIsDhcp -Adapter $Adapter) {
                    Write-Host "Skip $($Adapter.Name) - already using DHCP DNS."
                } else {
                    Set-WinUtilDnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily 'IPv4' -ResetServerAddresses
                    Set-WinUtilDnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily 'IPv6' -ResetServerAddresses
                }
            } else {
                $targetDns4 = @("$($sync.configs.dns.$DNSProvider.Primary)", "$($sync.configs.dns.$DNSProvider.Secondary)")
                $targetDns6 = @("$($sync.configs.dns.$DNSProvider.Primary6)", "$($sync.configs.dns.$DNSProvider.Secondary6)")
                $currentDns4 = @(Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ServerAddresses)
                $currentDns6 = @(Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ServerAddresses)

                if (Test-WinUtilDnsAddressSetMatch -Current $currentDns4 -Target $targetDns4) {
                    Write-Host "Skip $($Adapter.Name) IPv4 DNS - already set to $DNSProvider."
                } else {
                    Set-WinUtilDnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily 'IPv4' -ServerAddresses $targetDns4
                }

                if (Test-WinUtilDnsAddressSetMatch -Current $currentDns6 -Target $targetDns6) {
                    Write-Host "Skip $($Adapter.Name) IPv6 DNS - already set to $DNSProvider."
                } else {
                    Set-WinUtilDnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily 'IPv6' -ServerAddresses $targetDns6
                }
            }
        }
    } catch {
        Write-Warning "Unable to set DNS Provider due to an unhandled exception."
        Write-Warning $psitem.Exception.Message
    }
}