function Test-WinUtilPerformanceTrace {
    $enabledValue = ([string]$env:WINUTIL_PERF_LOG).ToLowerInvariant()
    if ($enabledValue -in @("1", "true", "yes", "on")) {
        return $true
    }

    if ($null -ne $sync -and $sync.ContainsKey("PerformanceTraceEnabled")) {
        return [bool]$sync.PerformanceTraceEnabled
    }

    return $false
}
