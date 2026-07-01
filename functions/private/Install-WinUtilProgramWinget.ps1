Function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

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
            Start-Process -FilePath winget -ArgumentList @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent") -NoNewWindow -Wait
        } else {
            Start-Process -FilePath winget -ArgumentList @("uninstall", "--id", $program, "--source", $source, "--silent") -NoNewWindow -Wait
        }
    }
}
