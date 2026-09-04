function Install-WinUtilProgramChoco {
    <#

    .SYNOPSIS
        Installs, upgrades or uninstalls packages with Chocolatey and reports each outcome

    .DESCRIPTION
        One package per call to choco, so the progress bar moves through the list and a failure
        names the package that failed rather than the whole batch. Choco's own output goes to the
        log instead of the console, the way the WinGet path reports.

    .PARAMETER Action
        Install, Upgrade or Uninstall.

    .PARAMETER Programs
        The package names. For Upgrade, the single entry "all" upgrades everything.

    .PARAMETER ProgressBase
        Where this call starts within the job's overall progress bar.

    .PARAMETER ProgressSpan
        How much of the overall bar these packages account for. Zero reports nothing.

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall", "Upgrade")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs,

        [int]$ProgressBase = 0,

        [int]$ProgressSpan = 0
    )

    # Chocolatey reports "nothing needed doing" and "it worked, now reboot" through exit codes
    # rather than as failures
    $rebootCodes = @{
        1641 = "installed, the installer started a restart"
        3010 = "installed, a restart is needed to finish"
    }
    $nothingToDo = @{
        2 = "nothing to do"
    }
    $verb = $Action.ToLowerInvariant()
    $chocoAvailable = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)

    $packages = @($Programs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $total = $packages.Count
    $index = 0

    foreach ($program in $packages) {
        $index++
        if ($ProgressSpan -gt 0 -and $total -gt 0) {
            $percent = $ProgressBase + [int]((($index - 1) / $total) * $ProgressSpan)
            Step-WinUtilJob -Status "$Action $program ($index/$total)" -Percent $percent
        }

        Write-WinUtilLog -Component "Package" -Message "$Action choco package: $program"

        # --no-progress stops choco redrawing a percentage line that only makes sense on a
        # console nobody is watching
        $arguments = @($verb, $program, "-y", "--no-progress")
        # Each worker runspace has its own global scope. Reset the native-command result there so
        # command-not-found cannot inherit a successful code from earlier work in the same pool.
        $global:LASTEXITCODE = $null
        if (-not $chocoAvailable) {
            $output = "Chocolatey is not installed or is not available on PATH."
            $exitCode = -1
        } else {
            $output = & choco @arguments 2>&1
            $exitCode = if ($null -eq $global:LASTEXITCODE) { -1 } else { [int]$global:LASTEXITCODE }
        }

        if ($exitCode -eq 0) {
            $outcome = "Succeeded"
            $detail = "exit code 0"
        } elseif ($rebootCodes.ContainsKey($exitCode)) {
            $outcome = "Succeeded"
            $detail = $rebootCodes[$exitCode]
        } elseif ($nothingToDo.ContainsKey($exitCode)) {
            $outcome = "Skipped"
            $detail = $nothingToDo[$exitCode]
        } else {
            $outcome = "Failed"
            $detail = if ($exitCode -eq -1) { "Chocolatey command did not start" } else { "exit code $exitCode" }
        }

        $level = if ($outcome -eq "Failed") { "ERROR" } else { "INFO" }
        Write-WinUtilLog -Level $level -Component "Package" -Message "$Action choco package $($outcome.ToLowerInvariant()): $program ($detail)"

        if ($outcome -eq "Failed") {
            # The reason is somewhere in choco's output, and without it the log says only that
            # a number came back
            foreach ($line in @($output | Select-Object -Last 15)) {
                $text = ([string]$line).Trim()
                if ($text) { Write-WinUtilLog -Level "WARN" -Component "Package" -Detail -Message $text }
            }
        }

        if ($ProgressSpan -gt 0 -and $total -gt 0) {
            Step-WinUtilJob -Status "$Action $program ($index/$total)" -Percent ($ProgressBase + [int](($index / $total) * $ProgressSpan))
        }

        [pscustomobject]@{
            Package = $program
            Manager = "choco"
            Action = $Action
            ExitCode = $exitCode
            Outcome = $outcome
            Detail = $detail
        }
    }
}
