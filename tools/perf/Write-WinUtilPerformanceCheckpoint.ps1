function Write-WinUtilPerformanceCheckpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Test-WinUtilPerformanceTrace) -or $null -eq $sync) {
        return
    }

    if (-not $sync.ContainsKey("PerformanceTrace") -or $null -eq $sync.PerformanceTrace.Stopwatch) {
        $sync.PerformanceTrace = @{
            Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            LastElapsedMs = 0.0
        }
    }

    $elapsedMs = [math]::Round($sync.PerformanceTrace.Stopwatch.Elapsed.TotalMilliseconds, 2)
    $deltaMs = [math]::Round($elapsedMs - [double]$sync.PerformanceTrace.LastElapsedMs, 2)
    $sync.PerformanceTrace.LastElapsedMs = $elapsedMs

    Write-WinUtilLog -Level "DEBUG" -Component "StartupPerf" -Message ("{0}: {1:N2} ms (+{2:N2} ms)" -f $Name, $elapsedMs, $deltaMs)
}
