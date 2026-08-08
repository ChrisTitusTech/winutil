function Write-WinUtilConsoleProgress {
    <#
        .SYNOPSIS
            Reports job progress on the console for runs that have no window

        .DESCRIPTION
            The progress bar is the only thing telling a user how far along a job is, so a
            headless run needs the same information in the only place it has. Package download
            progress arrives several times a second, which would bury everything else, so a line
            is printed when the wording changes or after a second of the same wording.
    #>
    param(
        [string]$Status,
        [int]$Percent = -1
    )

    if ([string]::IsNullOrWhiteSpace($Status) -and $Percent -lt 0) {
        return
    }

    if ($null -eq $sync.ConsoleProgressState) {
        $sync.ConsoleProgressState = [hashtable]::Synchronized(@{ LastText = ""; LastWrite = [datetime]::MinValue })
    }
    $state = $sync.ConsoleProgressState

    $text = if ([string]::IsNullOrWhiteSpace($Status)) { $state.LastText } else { $Status }
    if ([string]::IsNullOrWhiteSpace($text)) {
        return
    }

    $now = Get-Date
    $sameText = $text -eq $state.LastText
    if ($sameText -and ($now - $state.LastWrite).TotalMilliseconds -lt 1000) {
        return
    }

    $state.LastText = $text
    $state.LastWrite = $now

    $prefix = if ($Percent -ge 0) { "[{0,3}%] " -f $Percent } else { "[   =] " }
    Write-Host "$prefix$text" -ForegroundColor DarkCyan
}
