function Write-WinUtilLog {
    <#
    .SYNOPSIS
        Writes a timestamped WinUtil log entry to the active session log.

    .DESCRIPTION
        Called from the interface thread and from every job body. When Start-Transcript owns the
        active session log, entries go through the host so the transcript records them without a
        competing file write. Standalone callers use a named mutex to serialize direct appends.

    .PARAMETER Message
        The message to write.
    .PARAMETER Level
        The severity level for the log entry.
    .PARAMETER Component
        The WinUtil component producing the log entry.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",

        [string]$Component = "WinUtil",

        # Continuation of an error already counted, such as a stack frame
        [switch]$Detail
    )

    # UI performance diagnostics are useful to developers but are too noisy for the release
    # transcript. Compile.ps1 stamps local builds so DEBUG output cannot leak into CI artifacts.
    if ($Level -eq "DEBUG" -and ($null -eq $sync -or -not $sync.IsLocalCompile)) {
        return
    }

    if ($Level -eq "ERROR" -and -not $Detail -and $null -ne $sync.LoggedErrors) {
        $null = $sync.LoggedErrors.Add("[$Component] $Message")
    }

    if ($Level -eq "ERROR" -and -not $Detail -and $global:WinUtilIsJobWorker) {
        $global:WinUtilJobErrorCount++
    }

    try {
        # Single resolution chain instead of 4 separate if-blocks
        $logPath = $null
        $isTranscript = $false
        if ($null -ne $sync) {
            if ($sync.ContainsKey("logPath") -and -not [string]::IsNullOrWhiteSpace($sync.logPath)) {
                $logPath = $sync.logPath
            } elseif ($sync.ContainsKey("transcriptPath") -and -not [string]::IsNullOrWhiteSpace($sync.transcriptPath)) {
                $logPath = $sync.transcriptPath
            } elseif ($sync.ContainsKey("winutildir") -and -not [string]::IsNullOrWhiteSpace($sync.winutildir)) {
                $logPath = Join-Path (Join-Path $sync.winutildir "logs") "winutil_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
                $sync.logPath = $logPath
            }
            if ($sync.ContainsKey("transcriptPath") -and -not [string]::IsNullOrWhiteSpace($sync.transcriptPath) -and $logPath -eq $sync.transcriptPath) {
                $isTranscript = $true
            }
        }
        if ([string]::IsNullOrWhiteSpace($logPath) -and -not [string]::IsNullOrWhiteSpace($env:LocalAppData)) {
            if ([string]::IsNullOrWhiteSpace($script:WinUtilLogPath)) {
                $script:WinUtilLogPath = Join-Path (Join-Path (Join-Path $env:LocalAppData "winutil") "logs") "winutil_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
            }
            $logPath = $script:WinUtilLogPath
        }
        if ([string]::IsNullOrWhiteSpace($logPath)) { return }

        $logDir = Split-Path -Path $logPath -Parent
        if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

        $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [$Level] [$Component] $Message"

        if ($isTranscript) {
            Write-Host $line
            return
        }

        $mutex = [System.Threading.Mutex]::new($false, "WinUtilSessionLog")
        $held = $false
        try {
            try {
                $held = $mutex.WaitOne(2000)
            } catch [System.Threading.AbandonedMutexException] {
                # A thread died holding the mutex; ownership transfers to us either way
                $held = $true
            }

            if (-not $held) {
                # Writing anyway is what interleaves lines, and the wait only times out when
                # contention is at its worst
                Write-Host $line
                return
            }

            Add-Content -Path $logPath -Value $line -Encoding UTF8 -ErrorAction Stop
        } catch [System.IO.IOException], [System.UnauthorizedAccessException], [System.Security.SecurityException] {
            Write-Host $line
        } finally {
            if ($held) { $mutex.ReleaseMutex() }
            $mutex.Dispose()
        }
    } catch {
        Write-Warning "Unable to write WinUtil log entry: $($_.Exception.Message)"
    }
}
