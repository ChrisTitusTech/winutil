Function Install-WinUtilProgramWinget {
    <#

    .SYNOPSIS
        Installs or uninstalls packages with WinGet and reports the outcome of each one

    .DESCRIPTION
        Emits one result object per package so the caller can tell what actually happened
        rather than assuming the run succeeded.

        Runs one winget command per package so a failure names the package that failed rather
        than the whole batch. Progress moves per package: winget hides its own progress bar once
        its output is redirected, so there is nothing to report from inside a single install.

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall", "Upgrade")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    # WinGet reports "there was nothing to do" through the exit code rather than as success
    $nothingToDo = @{
        -1978335135 = "already installed"
        -1978335189 = "no applicable update"
    }
    # The installer worked and wants a restart to finish. Windows reports that as its own exit
    # code rather than as zero, and treating it as a failure marks working installs as broken.
    $rebootExitCodes = @{
        3010 = "installed, a restart is needed to finish"
        1641 = "installed, the installer started a restart"
        # WinGet's own equivalents. -1978334966 is deliberately absent: it means a reboot is
        # required before the install can proceed, which is not a completed install.
        -1978334967 = "installed, a restart is needed to finish"
        -1978334965 = "installed, the installer started a restart"
    }

    foreach ($program in $Programs) {
        if ([string]::IsNullOrWhiteSpace($program) -or $program -eq "na") {
            continue
        }

        $source = "winget"
        if ($program.StartsWith("msstore:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $source = "msstore"
            $program = $program.Substring("msstore:".Length)
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package: $program (source: $source)"

        $outcome = "Failed"
        $detail = "no result"
        $exitCode = -1

        $arguments = switch ($Action) {
            "Uninstall" { @("uninstall", "--id", $program, "--source", $source, "--silent") }
            "Upgrade"   { @("upgrade", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent") }
            default     { @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent") }
        }

        $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            $outcome = "Succeeded"
            $detail = "exit code 0"
        } elseif ($rebootExitCodes.ContainsKey($exitCode)) {
            $outcome = "Succeeded"
            $detail = $rebootExitCodes[$exitCode]
        } elseif ($nothingToDo.ContainsKey($exitCode)) {
            $outcome = "Skipped"
            $detail = $nothingToDo[$exitCode]
        } else {
            $outcome = "Failed"
            $detail = Get-WinUtilWinGetErrorMessage -Code $exitCode
        }

        $level = if ($outcome -eq "Failed") { "ERROR" } else { "INFO" }
        Write-WinUtilLog -Level $level -Component "Package" -Message "$Action winget package $($outcome.ToLowerInvariant()): $program ($detail)"

        [pscustomobject]@{
            Package = $program
            Manager = "winget"
            Action = $Action
            ExitCode = $exitCode
            Outcome = $outcome
            Detail = $detail
        }
    }
}
