function Test-WinUtilIpAddressBlocked {
    param(
        [Parameter(Mandatory)]
        [System.Net.IPAddress]$Address
    )

    if ($Address.IsIPv6LinkLocal -or $Address.IsIPv6SiteLocal) {
        return $true
    }

    if ([System.Net.IPAddress]::IsLoopback($Address)) {
        return $true
    }

    if ($Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
        $bytes = $Address.GetAddressBytes()

        # Unique local addresses (fc00::/7)
        if (($bytes[0] -band 0xFE) -eq 0xFC) {
            return $true
        }

        # IPv4-mapped IPv6 (::ffff:x.x.x.x)
        if ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0 -and
            $bytes[4] -eq 0 -and $bytes[5] -eq 0 -and $bytes[6] -eq 0 -and $bytes[7] -eq 0 -and
            $bytes[8] -eq 0 -and $bytes[9] -eq 0 -and $bytes[10] -eq 0xFF -and $bytes[11] -eq 0xFF) {
            $mapped = [System.Net.IPAddress]::new(@($bytes[12], $bytes[13], $bytes[14], $bytes[15]))
            return (Test-WinUtilIpAddressBlocked -Address $mapped)
        }
    }

    if ($Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
        $bytes = $Address.GetAddressBytes()
        if ($bytes[0] -eq 10) { return $true }
        if ($bytes[0] -eq 172 -and $bytes[1] -ge 16 -and $bytes[1] -le 31) { return $true }
        if ($bytes[0] -eq 192 -and $bytes[1] -eq 168) { return $true }
        if ($bytes[0] -eq 127) { return $true }
        if ($bytes[0] -eq 169 -and $bytes[1] -eq 254) { return $true }
        if ($bytes[0] -eq 0) { return $true }
    }

    return $false
}

function Test-WinUtilRemoteUrlAllowed {
    <#
    .SYNOPSIS
        Returns whether a remote config URL is allowed (blocks loopback/private targets).
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    try {
        $uri = [Uri]$Url
    } catch {
        return $false
    }

    if ($uri.Scheme -notin @('http', 'https')) {
        return $false
    }

    $hostName = $uri.Host
    if ([string]::IsNullOrWhiteSpace($hostName)) {
        return $false
    }

    if ($hostName -ieq 'localhost' -or $hostName -like '*.local') {
        return $false
    }

    if ($hostName -match '^\[?::1\]?$') {
        return $false
    }

    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($hostName)
    } catch {
        return $false
    }

    foreach ($address in $addresses) {
        if (Test-WinUtilIpAddressBlocked -Address $address) {
            return $false
        }
    }

    return $true
}

function Invoke-WinUtilSafeWebRequest {
    <#
    .SYNOPSIS
        Performs a web request with redirect validation against SSRF allowlist.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [int]$MaxRedirects = 5
    )

    $currentUri = $Uri

    for ($redirect = 0; $redirect -le $MaxRedirects; $redirect++) {
        if (-not (Test-WinUtilRemoteUrlAllowed -Url $currentUri)) {
            throw "Blocked remote URL: $currentUri"
        }

        try {
            return Invoke-WebRequest -Uri $currentUri -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop
        } catch [System.Net.WebException] {
            $response = $_.Exception.Response
            if ($null -eq $response) {
                throw
            }

            $statusCode = [int]$response.StatusCode
            if ($statusCode -notin @(301, 302, 303, 307, 308)) {
                throw
            }

            $location = $response.Headers['Location']
            if ([string]::IsNullOrWhiteSpace($location)) {
                throw
            }

            if ($location.StartsWith('/')) {
                $baseUri = [Uri]$currentUri
                $currentUri = ([Uri]::new($baseUri, $location)).AbsoluteUri
            } else {
                $currentUri = $location
            }
        }
    }

    throw "Exceeded maximum redirect count ($MaxRedirects) for $Uri"
}