function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    # signed process exit codes for 0x8A15000F and 0x8A15000E.
    $sourceErrorExitCodes = @(-1978335217, -1978335218)

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

        if ($Action -eq 'Install' -and $source -eq 'winget' -and $process.ExitCode -in $sourceErrorExitCodes) {
            Write-WinUtilLog -Component "Package" -Message "WinGet source failure detected for $program. Repairing sources and retrying..."
            Ensure-WinUtilWingetSources
            $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru
            if ($process.ExitCode -in $sourceErrorExitCodes) {
                throw "WinGet source repair did not resolve the source failure for $program."
            }
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package completed: $program (exit code: $($process.ExitCode))"
    }
}
