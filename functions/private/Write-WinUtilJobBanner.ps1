function Write-WinUtilJobBanner {
    <#
        .SYNOPSIS
            Writes the boxed start, finish or failure line a job prints to the console

        .DESCRIPTION
            One place decides what a running operation looks like in the terminal, so every
            workflow announces itself the same way instead of hand-drawing its own box. Called
            by Start-WinUtilJob, not by job bodies.

        .PARAMETER Message
            The line to box, for example "Installing apps".

        .PARAMETER Level
            INFO for a normal banner, ERROR to colour it as a failure.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "ERROR")]
        [string]$Level = "INFO"
    )

    # A progress line is rewritten in place and left open, so the box would be drawn on top of it
    Complete-WinUtilConsoleProgress

    # Wrapped, because a failure listing several packages would otherwise draw a box wider
    # than the console
    $width = 76
    $words = $Message -split '\s+'
    $lines = [System.Collections.Generic.List[string]]::new()
    $current = ""
    foreach ($word in $words) {
        if ($current.Length -gt 0 -and ($current.Length + 1 + $word.Length) -gt $width) {
            $lines.Add($current)
            $current = $word
        } else {
            $current = if ($current.Length -eq 0) { $word } else { "$current $word" }
        }
    }
    if ($current.Length -gt 0) { $lines.Add($current) }

    $longest = ($lines | Measure-Object -Property Length -Maximum).Maximum
    $border = "=" * ($longest + 6)
    $colour = if ($Level -eq "ERROR") { "Red" } else { "Cyan" }

    Write-Host ""
    Write-Host $border -ForegroundColor $colour
    foreach ($line in $lines) {
        Write-Host ("-- {0}$(' ' * ($longest - $line.Length)) --" -f $line) -ForegroundColor $colour
    }
    Write-Host $border -ForegroundColor $colour
}
