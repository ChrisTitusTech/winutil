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

    $line = "-- $Message --"
    $border = "=" * $line.Length
    $colour = if ($Level -eq "ERROR") { "Red" } else { "Cyan" }

    Write-Host ""
    Write-Host $border -ForegroundColor $colour
    Write-Host $line -ForegroundColor $colour
    Write-Host $border -ForegroundColor $colour
}
