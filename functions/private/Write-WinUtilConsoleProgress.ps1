function Write-WinUtilConsoleProgress {
    <#
        .SYNOPSIS
            Reports job progress on the console for runs that have no window

        .DESCRIPTION
            The progress bar is the only thing telling a user how far along a job is, so a
            headless run needs the same information in the only place it has.

            On a console the line is rewritten in place, because a package that reports every
            few hundred milliseconds would otherwise scroll a screenful for one install. When
            output is redirected there is no cursor to move, so each update is its own line and
            they are throttled hard instead.
    #>
    param(
        [string]$Status,
        [int]$Percent = -1
    )

    if ([string]::IsNullOrWhiteSpace($Status) -and $Percent -lt 0) {
        return
    }

    if ($null -eq $sync.ConsoleProgressState) {
        $sync.ConsoleProgressState = [hashtable]::Synchronized(@{
            LastText = ""
            LastWrite = [datetime]::MinValue
            LineLength = 0
            LineOpen = $false
        })
    }
    $state = $sync.ConsoleProgressState

    $text = if ([string]::IsNullOrWhiteSpace($Status)) { $state.LastText } else { $Status }
    if ([string]::IsNullOrWhiteSpace($text)) {
        return
    }

    $redirected = [Console]::IsOutputRedirected
    $throttleMs = if ($redirected) { 1000 } else { 150 }

    $now = Get-Date
    $sinceLast = ($now - $state.LastWrite).TotalMilliseconds

    # Redirected output cannot be rewritten in place, so every update is its own line and the
    # throttle holds even when the text changed. A job reporting per package would otherwise
    # scroll a screenful.
    if ($redirected) {
        if ($sinceLast -lt $throttleMs) { return }
    } elseif ($text -eq $state.LastText -and $sinceLast -lt $throttleMs) {
        return
    }

    $state.LastText = $text
    $state.LastWrite = $now

    $prefix = if ($Percent -ge 0) { "[{0,3}%] " -f $Percent } else { "[   =] " }
    $line = "$prefix$text"

    if ($redirected) {
        Write-Host $line -ForegroundColor DarkCyan
        return
    }

    # Pad to the previous length so a shorter line does not leave the tail of the longer one
    $padding = [Math]::Max(0, $state.LineLength - $line.Length)
    Write-Host ("`r$line" + (" " * $padding)) -NoNewline -ForegroundColor DarkCyan
    $state.LineLength = $line.Length
    $state.LineOpen = $true
}

function Complete-WinUtilConsoleProgress {
    <#
        .SYNOPSIS
            Ends the progress line so the next thing printed starts on its own

        .DESCRIPTION
            The line is rewritten in place and therefore left without a newline. Anything else
            reaching the console has to close it first, or it lands on top of the progress.
    #>

    $state = $sync.ConsoleProgressState
    if ($null -eq $state -or -not $state.LineOpen) {
        return
    }

    Write-Host ""
    $state.LineOpen = $false
    $state.LineLength = 0
    $state.LastText = ""
}
