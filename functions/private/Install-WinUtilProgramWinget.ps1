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

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs,

        [int]$ProgressBase = 0,

        [int]$ProgressSpan = 0
    )

    # WinGet reports "there was nothing to do" through the exit code rather than as success
    $nothingToDo = @{
        -1978335135 = "already installed"
        -1978335189 = "no applicable update"
    }
    # The module says the same thing through a status name
    $nothingToDoStatus = @("NoApplicableUpgrade", "PackageAlreadyInstalled", "NoApplicableInstallers")

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

            if ($Action -eq "Uninstall") {
                $command = "Uninstall-WinGetPackage"
            } else {
                # Install-WinGetPackage re-downloads and re-runs the installer for a package
                # that is already present, so an install pass would reinstall everything the
                # machine already has. Update-WinGetPackage upgrades it or reports
                # NoApplicableUpgrade, which is what "install or upgrade" should mean.
                $existing = Invoke-WinUtilWinGetCommand -Command "Get-WinGetPackage" -Parameters @{
                    Id = $program
                    MatchOption = "EqualsCaseInsensitive"
                    ErrorAction = "SilentlyContinue"
                }
                $command = if (@($existing).Count -gt 0 -and $null -ne @($existing)[0]) {
                    "Update-WinGetPackage"
                } else {
                    "Install-WinGetPackage"
                }
            }

            $results = Invoke-WinUtilWinGetCommand -Command $command -Parameters $parameters `
                -ProgressBase $ProgressBase -ProgressSpan $ProgressSpan -Label $program
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
                } elseif ($nothingToDoStatus -contains $status) {
                    $outcome = "Skipped"
                    $detail = $status
                } else {
                    $outcome = "Failed"
                    $detail = "status $status$(if ($exitCode -ne 0) { ", installer error $exitCode" })"
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
            } elseif ($nothingToDo.ContainsKey($exitCode)) {
                $outcome = "Skipped"
                $detail = $nothingToDo[$exitCode]
            } else {
                $outcome = "Failed"
                $detail = "exit code $exitCode"
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
