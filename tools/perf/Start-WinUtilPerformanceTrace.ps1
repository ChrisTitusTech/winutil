function Start-WinUtilPerformanceTrace {
    if (-not (Test-WinUtilPerformanceTrace) -or $null -eq $sync) {
        return
    }

    if (-not $sync.ContainsKey("PerformanceTrace")) {
        $sync.PerformanceTrace = @{
            Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            LastElapsedMs = 0.0
        }
    }

    Write-WinUtilPerformanceCheckpoint -Name "Startup trace started"
}
