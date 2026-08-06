function Invoke-WPFInstall {
    <#
    .SYNOPSIS
        Installs the selected programs using winget, if one or more of the selected programs are already installed on the system, winget will try and perform an upgrade if there's a newer version to install.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [PSObject[]]$PackagesToInstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ })
    )

    if ($PackagesToInstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install or upgrade."
        Show-WinUtilMessage -Message $WarningMsg -Title "WinUtil" -Button "OK" -Icon "Warning"
        return
    }

    $ManagerPreference = $sync.preferences.packagemanager
    Write-WinUtilLog -Component "Install" -Message "Install requested for $(@($PackagesToInstall).Count) selected package(s) using preference: $ManagerPreference"

    Start-WinUtilJob -Name "Install" -Description "Installing apps" -DisableAppList -Parameters @{
        PackagesToInstall = $PackagesToInstall
        ManagerPreference = $ManagerPreference
    } -ScriptBlock {
        param($PackagesToInstall, $ManagerPreference)

        # Summarising the selection reads every package, so it runs here rather than on the UI thread
        $packageSummary = Get-WinUtilPackageLogSummary -Packages $PackagesToInstall -Preference $ManagerPreference
        Write-WinUtilLog -Component "Install" -Message "Install selected package(s): $($packageSummary -join '; ')"

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToInstall -Preference $ManagerPreference
        $packagesWinget = $packagesSorted['Winget']
        $packagesChoco = $packagesSorted['Choco']
        $totalPackages = @($packagesWinget).Count + @($packagesChoco).Count
        $completedPackages = 0
        Write-WinUtilLog -Component "Install" -Message "Install package manager split: winget=$(@($packagesWinget).Count), choco=$(@($packagesChoco).Count)"

        $results = @()

        if ($packagesWinget.Count -gt 0 -and $packagesWinget -ne "0") {
            Install-WinUtilWinget
            foreach ($program in $packagesWinget) {
                $position = $completedPackages + 1
                Write-WinUtilJobProgress -Status "Installing $program ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

                $results += Install-WinUtilProgramWinget -Action Install -Programs @($program)
                $completedPackages++
                Write-WinUtilJobProgress -Status "Installed $program ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
            }
        }

        if ($packagesChoco.Count -gt 0) {
            $position = $completedPackages + 1
            Write-WinUtilJobProgress -Status "Installing Chocolatey packages ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

            Install-WinUtilChoco
            $results += Install-WinUtilProgramChoco -Action Install -Programs $packagesChoco
            $completedPackages += @($packagesChoco).Count
            Write-WinUtilJobProgress -Status "Installed Chocolatey packages ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
        }

        Complete-WinUtilPackageRun -Action "Install" -Results $results
    }
}
