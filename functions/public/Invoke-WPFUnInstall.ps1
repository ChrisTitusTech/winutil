function Invoke-WPFUnInstall {
    param(
        [Parameter(Mandatory=$false)]
        [PSObject[]]$PackagesToUninstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ })
    )
    <#

    .SYNOPSIS
        Uninstalls the selected programs
    #>

    if ($PackagesToUninstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to uninstall"
        Show-WinUtilMessage -Message $WarningMsg -Title "WinUtil" -Button "OK" -Icon "Warning"
        return
    }

    $ButtonType = "YesNo"
    $MessageboxTitle = "Are you sure?"
    $Messageboxbody = ("This will uninstall the following applications: `n $($PackagesToUninstall | Select-Object Name, Description| Out-String)")
    $MessageIcon = "Information"

    $confirm = Show-WinUtilMessage -Message $Messageboxbody -Title $MessageboxTitle -Button $ButtonType -Icon $MessageIcon

    if($confirm -eq "No") {return}

    $ManagerPreference = $sync.preferences.packagemanager
    Write-WinUtilLog -Component "Uninstall" -Message "Uninstall requested for $(@($PackagesToUninstall).Count) selected package(s) using preference: $ManagerPreference"

    Start-WinUtilJob -Name "Uninstall" -Description "Uninstalling apps" -DisableAppList -Parameters @{
        PackagesToUninstall = $PackagesToUninstall
        ManagerPreference = $ManagerPreference
    } -ScriptBlock {
        param($PackagesToUninstall, $ManagerPreference)

        $packageSummary = Get-WinUtilPackageLogSummary -Packages $PackagesToUninstall -Preference $ManagerPreference
        Write-WinUtilLog -Component "Uninstall" -Message "Uninstall selected package(s): $($packageSummary -join '; ')"

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToUninstall -Preference $ManagerPreference
        $packagesWinget = $packagesSorted['Winget']
        $packagesChoco = $packagesSorted['Choco']
        $totalPackages = @($packagesWinget).Count + @($packagesChoco).Count
        $completedPackages = 0
        Write-WinUtilLog -Component "Uninstall" -Message "Uninstall package manager split: winget=$(@($packagesWinget).Count), choco=$(@($packagesChoco).Count)"

        if ($packagesWinget -contains "Microsoft.Edge") {
            New-Item -Path "$Env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
        }

        $results = @()

        if ($packagesWinget.Count -gt 0) {
            foreach ($program in $packagesWinget) {
                $position = $completedPackages + 1
                Write-WinUtilJobProgress -Status "Uninstalling $program ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

                $slice = [int](100 / $totalPackages)
                $results += Measure-WinUtilStep -Scope "Uninstall" -Name "winget $program" -ScriptBlock {
                    Install-WinUtilProgramWinget -Action Uninstall -Programs @($program) `
                        -ProgressBase ([int](($completedPackages / $totalPackages) * 100)) -ProgressSpan $slice
                }
                $completedPackages++
                Write-WinUtilJobProgress -Status "Uninstalled $program ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
            }
        }

        if ($packagesChoco.Count -gt 0) {
            $position = $completedPackages + 1
            Write-WinUtilJobProgress -Status "Uninstalling Chocolatey packages ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

            $results += Measure-WinUtilStep -Scope "Uninstall" -Name "choco $($packagesChoco -join ', ')" -ScriptBlock {
                Install-WinUtilProgramChoco -Action Uninstall -Programs $packagesChoco
            }
            $completedPackages += @($packagesChoco).Count
            Write-WinUtilJobProgress -Status "Uninstalled Chocolatey packages ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
        }

        Complete-WinUtilPackageRun -Action "Uninstall" -Results $results
    }
}
