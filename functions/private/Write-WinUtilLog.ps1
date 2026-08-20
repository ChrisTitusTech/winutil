function Write-WinUtilLog {
    <#
    .SYNOPSIS
        Writes a timestamped WinUtil log entry to the active session log.
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

        [string]$Component = "WinUtil"
    )

    try {
        # Single resolution chain instead of 4 separate if-blocks
        $logPath = $null
        $isTranscript = $false
        if ($null -ne $sync) {
            if ($sync.ContainsKey("logPath") -and -not [string]::IsNullOrWhiteSpace($sync.logPath)) {
                $logPath = $sync.logPath
            } elseif ($sync.ContainsKey("transcriptPath") -and -not [string]::IsNullOrWhiteSpace($sync.transcriptPath)) {
                $logPath = $sync.transcriptPath
            } elseif ($sync.ContainsKey("winutildir")) {
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
            if ($null -ne $sync -and $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher -and -not $sync.Form.Dispatcher.CheckAccess()) {
                $sync.Form.Dispatcher.Invoke([action]{ Write-Host $line })
            } else {
                Write-Host $line
            }
            return
        }

        try { Add-Content -Path $logPath -Value $line -Encoding UTF8 -ErrorAction Stop }
        catch [System.IO.IOException] { Write-Host $line }
    } catch {
        Write-Warning "Unable to write WinUtil log entry: $($_.Exception.Message)"
    }
}
