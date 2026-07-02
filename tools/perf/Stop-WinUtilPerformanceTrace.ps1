function Stop-WinUtilPerformanceTrace {
    param(
        [string]$Name = "Startup trace complete"
    )

    if (-not (Test-WinUtilPerformanceTrace) -or $null -eq $sync -or -not $sync.ContainsKey("PerformanceTrace")) {
        return
    }

    Write-WinUtilPerformanceCheckpoint -Name $Name

    if ($null -ne $sync.PerformanceTrace.Stopwatch) {
        $sync.PerformanceTrace.Stopwatch.Stop()
    }
}
