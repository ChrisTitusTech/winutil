Function Install-WinUtilProgramWinget {
    <#

    .SYNOPSIS
        Installs or uninstalls packages with WinGet and reports the outcome of each one

    .DESCRIPTION
        Emits one result object per package so the caller can tell what actually happened
        rather than assuming the run succeeded.

        Prefers the Microsoft.WinGet.Client module, which reports download and install
        progress and returns a structured result. Falls back to the winget command line when
        the module is not available; that path can only report a package as started and
        finished, because winget hides its progress bar once its output is redirected.

    .PARAMETER ProgressBase
        Where this package starts within the job's overall progress bar.

    .PARAMETER ProgressSpan
        How much of the overall bar this package accounts for.

    .PARAMETER Label
        How the package should be named in the progress text. Callers working through a list
        pass the position in it, so the status keeps saying where the run is overall.

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs,

        [int]$ProgressBase = 0,

        [int]$ProgressSpan = 0,

        [string]$Label
    )

    # WinGet reports "there was nothing to do" through the exit code rather than as success
    $nothingToDo = @{
        -1978335135 = "already installed"
        -1978335189 = "no applicable update"
    }
    # The module says the same thing through a status name
    $nothingToDoStatus = @("NoApplicableUpgrade", "PackageAlreadyInstalled", "NoApplicableInstallers")

    # The installer worked and wants a restart to finish. Windows reports that as its own exit
    # code rather than as zero, and treating it as a failure marks working installs as broken.
    $rebootExitCodes = @{
        3010 = "installed, a restart is needed to finish"
        1641 = "installed, the installer started a restart"
    }

    $useModule = Install-WinUtilWinGetClient

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

        if ($useModule) {
            $parameters = @{
                Id = $program
                Source = $source
                Mode = "Silent"
                MatchOption = "EqualsCaseInsensitive"
            }

            # Both actions need to know whether the package is there before acting on it
            $existing = Invoke-WinUtilWinGetCommand -Command "Get-WinGetPackage" -Parameters @{
                Id = $program
                MatchOption = "EqualsCaseInsensitive"
                ErrorAction = "SilentlyContinue"
            }
            $isInstalled = @($existing).Count -gt 0 -and $null -ne @($existing)[0]

            if ($Action -eq "Uninstall") {
                if (-not $isInstalled) {
                    # Asking winget to remove something it cannot see is an error, but for the
                    # user the package is already gone
                    Write-WinUtilLog -Component "Package" -Message "Uninstall winget package skipped: $program (not installed)"
                    [pscustomobject]@{
                        Package = $program
                        Manager = "winget"
                        Action = $Action
                        ExitCode = 0
                        Outcome = "Skipped"
                        Detail = "not installed"
                    }
                    continue
                }
                $command = "Uninstall-WinGetPackage"
            } else {
                # Install-WinGetPackage re-downloads and re-runs the installer for a package
                # that is already present, so an install pass would reinstall everything the
                # machine already has. Update-WinGetPackage upgrades it or reports
                # NoApplicableUpgrade, which is what "install or upgrade" should mean.
                $command = if ($isInstalled) { "Update-WinGetPackage" } else { "Install-WinGetPackage" }
            }

            $progressLabel = if ($Label) { $Label } else { $program }
            $results = Invoke-WinUtilWinGetCommand -Command $command -Parameters $parameters `
                -ProgressBase $ProgressBase -ProgressSpan $ProgressSpan -Label $progressLabel
            $result = @($results)[0]

            if ($null -eq $result) {
                $outcome = "Failed"
                $detail = "the WinGet client returned nothing"
            } else {
                $status = [string]$result.Status
                $exitCode = [int]$result.InstallerErrorCode
                if ($status -eq "Ok" -and $exitCode -eq 0) {
                    $outcome = "Succeeded"
                    $detail = "status Ok"
                } elseif ($status -eq "Ok" -and $rebootExitCodes.ContainsKey($exitCode)) {
                    $outcome = "Succeeded"
                    $detail = $rebootExitCodes[$exitCode]
                } elseif ($nothingToDoStatus -contains $status) {
                    $outcome = "Skipped"
                    $detail = $status
                } else {
                    $outcome = "Failed"

                    # The module returns an HRESULT where the command line prints a sentence.
                    # It is the same number, so the same table explains it.
                    $wingetCode = 0
                    $extended = $result.ExtendedErrorCode
                    if ($extended -is [System.Exception]) {
                        $wingetCode = $extended.HResult
                    } elseif ($extended -and "$extended" -match '0x([0-9A-Fa-f]{8})') {
                        # These codes have the high bit set, so the unsigned value has to be
                        # wrapped rather than cast, which would overflow
                        $unsigned = [uint32]("0x$($Matches[1])")
                        $wingetCode = if ($unsigned -gt [int]::MaxValue) { [int]($unsigned - 4294967296) } else { [int]$unsigned }
                    }

                    $explanation = Get-WinUtilWinGetErrorMessage -Code $wingetCode
                    if (-not $explanation -and $exitCode -ne 0) {
                        $explanation = "The installer returned $exitCode."
                    }

                    $detail = if ($explanation) { "$status - $explanation" } else { "status $status" }
                }

                if ($result.RebootRequired) {
                    Write-WinUtilLog -Level "WARN" -Component "Package" -Message "$program needs a reboot to finish."
                }
            }
        } else {
            if ($Action -eq 'Install') {
                $arguments = @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent")
            } else {
                $arguments = @("uninstall", "--id", $program, "--source", $source, "--silent")
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
