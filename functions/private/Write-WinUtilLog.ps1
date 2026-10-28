function Write-WinUtilLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",

        [string]$Component = "WinUtil",

        # Continuation of an error already counted, such as a stack frame
        [switch]$Detail,

        [switch]$FileOnly
    )

    # UI performance diagnostics are useful to developers but are too noisy for the release
    # log. Compile.ps1 stamps local builds so DEBUG output cannot leak into CI artifacts.
    if ($Level -eq "DEBUG" -and ($null -eq $sync -or -not $sync.IsLocalCompile)) {
        return
    }

    if ($Level -eq "ERROR" -and -not $Detail -and $null -ne $sync.LoggedErrors) {
        $null = $sync.LoggedErrors.Add("[$Component] $Message")
    }

    # Global scope is per runspace, so this counter only ever sees errors logged by the
    # runspace that owns it: a job worker reads its own, and a tweak on the UI thread reads the
    # UI thread's
    if ($Level -eq "ERROR" -and -not $Detail) {
        $global:WinUtilJobErrorCount++
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $line = "[$timestamp] [$Level] [$Component] $Message"

    try {
        $writer = Get-WinUtilLogWriter
        if ($null -ne $writer) {
            [System.Threading.Monitor]::Enter($writer)
            try {
                $writer.WriteLine($line)
            } finally {
                [System.Threading.Monitor]::Exit($writer)
            }
        }
    } catch [System.IO.IOException] {
        Write-Verbose "Unable to write WinUtil log entry: $($_.Exception.Message)"
    } catch {
        Write-Warning "Unable to write WinUtil log entry: $($_.Exception.Message)"
    }

    if (-not $FileOnly) {
        Write-WinUtilHost $line
    }
}

# Opens the session log once for every runspace to share. Others can still read it, e.g. the environment report.
function Get-WinUtilLogWriter {
    $state = $sync
    if ($null -eq $state) {
        if ([string]::IsNullOrWhiteSpace($env:LocalAppData)) {
            return $null
        }
        if ($null -eq $script:WinUtilLogState) {
            $script:WinUtilLogState = [hashtable]::Synchronized(@{
                winutildir = Join-Path $env:LocalAppData "winutil"
            })
        }
        $state = $script:WinUtilLogState
    }

    $writer = $state.LogWriter
    if ($null -ne $writer -and $state.LogWriterPath -eq $state.logPath) {
        return $writer
    }

    [System.Threading.Monitor]::Enter($state.SyncRoot)
    try {
        if ([string]::IsNullOrWhiteSpace($state.logPath)) {
            if ([string]::IsNullOrWhiteSpace($state.winutildir)) {
                return $null
            }
            $state.logPath = Join-Path (Join-Path $state.winutildir "logs") "winutil_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log"
        }

        if ($null -ne $state.LogWriter -and $state.LogWriterPath -eq $state.logPath) {
            return $state.LogWriter
        }

        if ($null -ne $state.LogWriter) {
            $state.LogWriter.Dispose()
            $state.LogWriter = $null
        }

        $logDirectory = Split-Path -Path $state.logPath -Parent
        if (-not (Test-Path -LiteralPath $logDirectory)) {
            New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
        }

        $stream = [System.IO.FileStream]::new(
            $state.logPath,
            [System.IO.FileMode]::Append,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::Read)
        $newWriter = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
        $newWriter.AutoFlush = $true

        $state.LogWriterPath = $state.logPath
        $state.LogWriter = $newWriter
        return $newWriter
    } finally {
        [System.Threading.Monitor]::Exit($state.SyncRoot)
    }
}

# Lets go of the log file when WinUtil exits, so the terminal it ran in doesn't keep it locked
function Close-WinUtilLog {
    $state = if ($null -ne $sync) { $sync } else { $script:WinUtilLogState }
    if ($null -eq $state -or $null -eq $state.LogWriter) {
        return
    }

    $writer = $state.LogWriter
    [System.Threading.Monitor]::Enter($writer)
    try {
        $state.LogWriter = $null
        $state.LogWriterPath = $null
        $writer.Dispose()
    } finally {
        [System.Threading.Monitor]::Exit($writer)
    }
}

# Console-only output like banners and progress. Unlike Write-Host, a job won't log it.
function Write-WinUtilHost {
    param(
        [string]$Object = "",
        [Nullable[System.ConsoleColor]]$ForegroundColor,
        [Nullable[System.ConsoleColor]]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $Host.UI.RawUI
    if ($null -eq $rawUI -or ($null -eq $ForegroundColor -and $null -eq $BackgroundColor)) {
        if ($NoNewline) {
            $Host.UI.Write($Object)
        } else {
            $Host.UI.WriteLine($Object)
        }
        return
    }

    $foreground = if ($null -ne $ForegroundColor) { $ForegroundColor } else { $rawUI.ForegroundColor }
    $background = if ($null -ne $BackgroundColor) { $BackgroundColor } else { $rawUI.BackgroundColor }

    if ($NoNewline) {
        $Host.UI.Write($foreground, $background, $Object)
    } else {
        $Host.UI.WriteLine($foreground, $background, $Object)
    }
}

# Logs a warning, error or Write-Host record from another runspace, and shows it too unless -Shown says it already was
function Write-WinUtilStreamRecord {
    param(
        [Parameter(Mandatory)]
        $Record,

        [string]$Component = "WinUtil",

        [switch]$Shown
    )

    if ($Record -is [System.Management.Automation.WarningRecord]) {
        Write-WinUtilLog -Level "WARN" -Component $Component -Message $Record.Message -FileOnly:$Shown
    } elseif ($Record -is [System.Management.Automation.ErrorRecord]) {
        Write-WinUtilErrorRecord -ErrorRecord $Record -Component $Component -Context "Non-terminating error"
    } elseif ($Record -is [System.Management.Automation.InformationRecord]) {
        $message = $Record.MessageData

        if (-not $Shown -and $message -is [System.Management.Automation.HostInformationMessage]) {
            Write-WinUtilHost -Object $message.Message -ForegroundColor $message.ForegroundColor `
                -BackgroundColor $message.BackgroundColor -NoNewline:([bool]$message.NoNewLine)
        }

        $text = "$message".TrimEnd()
        if ($text) {
            Write-WinUtilLog -Component $Component -Message $text -FileOnly
        }
    }
}
