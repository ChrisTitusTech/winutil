function Get-WinUtilRecentLogs {
    <#
    .SYNOPSIS
        Concatenates WinUtil session logs from the last N days into a single text blob.

    .PARAMETER Days
        How many days back to include. Defaults to 7, matching what the support forum/server
        typically asks users for.

    .PARAMETER LogDirectory
        Overrides the log directory (normally $sync.winutildir\logs). Mainly for testing.
    #>
    param(
        [int]$Days = 7,
        [string]$LogDirectory
    )

    if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
        if ($null -eq $sync -or -not $sync.ContainsKey("winutildir") -or [string]::IsNullOrWhiteSpace($sync.winutildir)) {
            return ""
        }
        $LogDirectory = Join-Path $sync.winutildir "logs"
    }

    if (-not (Test-Path $LogDirectory)) {
        return ""
    }

    $cutoff = (Get-Date).AddDays(-$Days)
    $logFiles = Get-ChildItem -Path $LogDirectory -Filter "winutil_*.log" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $cutoff } |
        Sort-Object LastWriteTime

    $sections = foreach ($logFile in $logFiles) {
        "=== $($logFile.Name) ===`n$(Get-Content -Path $logFile.FullName -Raw)"
    }

    return ($sections -join "`n`n")
}
