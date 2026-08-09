function Get-WinUtilDNSBenchmark {
    <#

    .SYNOPSIS
        Benchmarks neutral DNS providers by measuring TCP port 53 latency (RTT in ms) to determine the fastest DNS server.

    .PARAMETER TimeoutMs
        Maximum timeout in milliseconds for each connection test. Default is 1500ms.

    .OUTPUTS
        Array of PSCustomObjects containing Provider, PrimaryIP, and LatencyMs sorted by lowest latency.

    .EXAMPLE
        $results = Get-WinUtilDNSBenchmark
        $fastest = $results[0]

    #>
    [CmdletBinding()]
    param(
        [int]$TimeoutMs = 1500
    )

    Write-WinUtilLog -Component "DNS" -Message "Starting DNS latency benchmark scan (TCP port 53)..."

    $dnsConfigs = $sync.configs.dns
    if ($null -eq $dnsConfigs) {
        Write-Warning "DNS configurations not found in `$sync.configs.dns."
        Write-WinUtilLog -Level "ERROR" -Component "DNS" -Message "DNS configurations not found in `$sync.configs.dns."
        return @()
    }

    $results = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($prop in $dnsConfigs.PSObject.Properties) {
        $providerName = $prop.Name
        $primaryIp = $prop.Value.Primary
        if (-not $primaryIp) { continue }

        # Skip specialized policy/filtering variants (e.g. Malware, Adult, Family) for neutral auto-selection
        if ($providerName -like "*Malware*" -or $providerName -like "*Adult*" -or $providerName -like "*Family*") {
            continue
        }

        $latency = 9999
        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $asyncResult = $client.BeginConnect($primaryIp, 53, $null, $null)
            $success = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
            $stopwatch.Stop()

            if ($success -and $client.Connected) {
                try {
                    $client.EndConnect($asyncResult)
                } catch { }
                $latency = [int]$stopwatch.ElapsedMilliseconds
            } else {
                $latency = 9999
            }
        } catch {
            $latency = 9999
        } finally {
            if ($null -ne $client) {
                try { $client.Close() } catch { }
                try { $client.Dispose() } catch { }
            }
        }

        $results.Add([PSCustomObject]@{
            Provider  = $providerName
            PrimaryIP = $primaryIp
            LatencyMs = $latency
        })
    }

    $sortedResults = @($results | Sort-Object LatencyMs)
    if ($sortedResults.Count -gt 0 -and $sortedResults[0].LatencyMs -lt 9999) {
        $fastest = $sortedResults[0]
        Write-WinUtilLog -Component "DNS" -Message "DNS Benchmark completed. Fastest neutral provider: $($fastest.Provider) ($($fastest.LatencyMs) ms)"
    } else {
        Write-WinUtilLog -Component "DNS" -Message "DNS Benchmark completed. Could not determine latency for providers."
    }

    return $sortedResults
}
