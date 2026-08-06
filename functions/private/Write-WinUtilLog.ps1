function Write-WinUtilLog {
    <#

    .SYNOPSIS
        Writes a timestamped WinUtil log entry to the active session log.

    .DESCRIPTION
        Called from the interface thread and from every job body, so the append is serialized
        with a named mutex. The session log is deliberately not the file Start-Transcript owns:
        a transcript only records the runspace it was started on, so anything a job logged would
        otherwise never reach disk.

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

    if ($Level -eq "ERROR" -and -not $Detail -and $null -ne $sync.LoggedErrors) {
        $null = $sync.LoggedErrors.Add("[$Component] $Message")
    }

    try {
        $logPath = $null
        if ($null -ne $sync -and $sync.ContainsKey("logPath")) {
            $logPath = $sync.logPath
        }

        if ([string]::IsNullOrWhiteSpace($logPath) -and $null -ne $sync -and $sync.ContainsKey("winutildir")) {
            $logDirectory = Join-Path $sync.winutildir "logs"
            $logPath = Join-Path $logDirectory "winutil_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log"
            $sync.logPath = $logPath
        }

        if ([string]::IsNullOrWhiteSpace($logPath) -and -not [string]::IsNullOrWhiteSpace($env:LocalAppData)) {
            if ([string]::IsNullOrWhiteSpace($script:WinUtilLogPath)) {
                $logDirectory = Join-Path (Join-Path $env:LocalAppData "winutil") "logs"
                $script:WinUtilLogPath = Join-Path $logDirectory "winutil_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log"
            }
            $logPath = $script:WinUtilLogPath
        }

        if ([string]::IsNullOrWhiteSpace($logPath)) {
            return
        }

        $logDirectory = Split-Path -Path $logPath -Parent
        if (-not (Test-Path $logDirectory)) {
            New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $line = "[$timestamp] [$Level] [$Component] $Message"

        $mutex = [System.Threading.Mutex]::new($false, "WinUtilSessionLog")
        $held = $false
        try {
            try {
                $held = $mutex.WaitOne(2000)
            } catch [System.Threading.AbandonedMutexException] {
                # A thread died holding the mutex; ownership transfers to us either way
                $held = $true
            }

            Add-Content -Path $logPath -Value $line -Encoding UTF8 -ErrorAction Stop
        } catch [System.IO.IOException] {
            Write-Host $line
        } finally {
            if ($held) { $mutex.ReleaseMutex() }
            $mutex.Dispose()
        }
    } catch {
        Write-Warning "Unable to write WinUtil log entry: $($_.Exception.Message)"
    }
}
