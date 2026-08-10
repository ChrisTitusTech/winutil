Function Install-WinUtilProgramWinget {
    <#
    .SYNOPSIS
        Installs or uninstalls the given winget package IDs.

    .DESCRIPTION
        Runs winget natively in WinUtil's own (elevated) process first - correct for
        machine-scope packages (e.g. VLC, whose own uninstaller needs admin rights to touch
        Program Files/HKLM). Only retries de-elevated, via Start-WinUtilProcessAsStandardUser,
        when winget's exit code specifically indicates the operation was blocked purely because
        of the wrong integrity context - not on every failure. Blindly de-elevating every winget
        call (an earlier version of this function did that) fixed per-user-scope packages like
        Vivaldi but broke machine-scope ones like VLC, whose bundled uninstaller then failed
        for lack of admin rights - trading one scope-mismatch bug for the opposite one.

    .OUTPUTS
        One [pscustomobject] per attempted program (blank/na entries are skipped, not
        included), each with .Program, .Success, and .ExitCode - so callers can report real
        per-item outcomes instead of assuming every attempt succeeded.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    # winget exit codes that mean "blocked purely by running in the wrong integrity context",
    # not a real install/uninstall failure - safe to retry once in the other context:
    #   0x8A15007D APPINSTALLER_CLI_ERROR_ADMIN_CONTEXT_ACTION_PROHIBITED (-1978335107) - a
    #     per-user-scope package refused because WinUtil is running elevated (the Vivaldi case).
    #   0x8A150056 APPINSTALLER_CLI_ERROR_INSTALLER_PROHIBITS_ELEVATION (-1978335146) - the
    #     installer itself refuses to run elevated.
    $wrongContextExitCodes = @(-1978335107, -1978335146)

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($program in $Programs) {
        if ([string]::IsNullOrWhiteSpace($program) -or $program -eq "na") {
            continue
        }

        $source = "winget"
        if ($program.StartsWith("msstore:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $source = "msstore"
            $program = $program.Substring("msstore:".Length)
        }

        if ($Action -eq 'Install') {
            $arguments = @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent")
        } else {
            $arguments = @("uninstall", "--id", $program, "--source", $source, "--silent")
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package: $program (source: $source)"

        $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru

        if ($wrongContextExitCodes -contains $process.ExitCode) {
            Write-WinUtilLog -Level "WARN" -Component "Package" -Message "$Action winget package: $program failed running elevated (exit code: $($process.ExitCode)) - retrying as standard user."
            $process = Start-WinUtilProcessAsStandardUser -FilePath winget -ArgumentList $arguments
        }

        $success = $process.ExitCode -eq 0
        if ($success) {
            Write-WinUtilLog -Component "Package" -Message "$Action winget package completed: $program"
        } else {
            $hint = if ($Action -eq 'Uninstall') {
                " If this keeps happening, try uninstalling it via Windows Settings > Apps instead."
            } else {
                ""
            }
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "$Action winget package FAILED: $program (exit code: $($process.ExitCode)).$hint"
        }

        $results.Add([pscustomobject]@{ Program = $program; Success = $success; ExitCode = $process.ExitCode })
    }

    return ,$results.ToArray()
}
