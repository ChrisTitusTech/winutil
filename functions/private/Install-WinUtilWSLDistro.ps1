Function Install-WinUtilWSLDistro {
    <#
    .SYNOPSIS
        Installs a WSL distro via "wsl --install -d <distro>". Requires the WSL2 feature to
        already be enabled.

    .DESCRIPTION
        No catalog entry currently uses this (installType "wslDistro") - Debian, the original
        user, moved to a normal winget install (Debian.Debian) after the hang described below
        was confirmed to also happen from a genuinely interactive terminal (not just this app's
        background runspace), meaning the install mechanism wasn't actually the cause. Left in
        place rather than removed, in case a future catalog entry needs a distro that isn't
        separately available via winget.

        Bounded to several minutes via Invoke-WinUtilWithTimeout, not the few-second default
        used elsewhere for quick DISM/registry checks - downloading and registering a distro's
        filesystem image genuinely takes a while, and "wsl --install -d <distro>" can hang well
        beyond that: it normally auto-launches the distro afterward for first-run setup (create
        a UNIX username/password), an interactive prompt with no console attached in this app's
        background install runspace. Confirmed live: the distro had already finished
        registering (showed up in "wsl --list") while the install call itself never returned,
        leaving the app looking stalled with no further progress or log output.

        Verifies success afterward via Test-WinUtilWSLDistroInstalled rather than trusting
        wsl.exe's own exit behavior, for the same reason - a timeout here isn't necessarily a
        real failure, the distro may already be fully registered underneath it.

        Logs a periodic "still working" update via -OnWaiting while the install runs - the
        confirmed real case above produced zero console/progress feedback for its full 5-minute
        wait despite genuinely succeeding, which read as a stalled/broken app rather than a
        slow-but-working one.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    foreach ($package in $Packages) {
        $name = $package.content
        $distro = $package.distro

        if ([string]::IsNullOrWhiteSpace($distro)) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "WSL distro install for $name is missing distro."
            continue
        }

        Write-WinUtilLog -Component "Package" -Message "Installing WSL distro $distro ($name)"

        $output = Invoke-WinUtilWithTimeout -TimeoutSeconds 300 -DefaultValue $null -ArgumentList @($distro) -OnWaitingIntervalSeconds 20 -OnWaiting {
            param($elapsedSeconds)
            Write-WinUtilLog -Component "Package" -Message "Still installing WSL distro $distro ($($elapsedSeconds)s elapsed) - this can take several minutes, especially on a first install."
            Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Installing $name ($($elapsedSeconds)s elapsed, this can take several minutes)..."
        } -ScriptBlock {
            param($distro)
            try {
                return (& wsl --install -d $distro 2>&1 | Out-String).Trim()
            } catch {
                return $null
            }
        }

        if ($null -eq $output) {
            Write-WinUtilLog -Level "WARN" -Component "Package" -Message "wsl --install -d $distro did not finish within the expected time - checking whether it actually registered anyway (this is normal if it's waiting on the first-run username prompt, which can't be answered here)."
        } else {
            Write-WinUtilLog -Component "Package" -Message $(if ($output) { $output } else { "(wsl --install -d $distro completed with no console output)" })
        }

        if (Test-WinUtilWSLDistroInstalled -Distro $distro) {
            Write-WinUtilLog -Component "Package" -Message "$name ($distro) is installed and registered. If this was its first install, launch it once from the Start Menu (not via `"wsl -d $distro`" in an existing terminal - confirmed live to hang waiting on the interactive first-run prompt even there) to finish creating its Linux user account."
        } else {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "$name ($distro) does not appear to be registered after the install attempt."
        }
    }
}
