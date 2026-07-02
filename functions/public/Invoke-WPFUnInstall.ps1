function Invoke-WPFUnInstall {
    param(
        [Parameter(Mandatory=$false)]
        [PSObject[]]$PackagesToUninstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ })
    )
    <#

    .SYNOPSIS
        Uninstalls the selected programs
    #>

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFUnInstall] Install process is currently running"
        Show-WinUtilMessage -Message $msg -Title "Winutil" -Button "OK" -Icon "Warning"
        return
    }

    if ($PackagesToUninstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to uninstall"
        Show-WinUtilMessage -Message $WarningMsg -Title $AppTitle -Button "OK" -Icon "Warning"
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
    $packageSummary = Get-WinUtilPackageLogSummary -Packages $PackagesToUninstall -Preference $ManagerPreference
    Write-WinUtilLog -Component "Uninstall" -Message "Uninstall selected package(s): $($packageSummary -join '; ')"

    Invoke-WPFRunspace -ParameterList @(("PackagesToUninstall", $PackagesToUninstall),("ManagerPreference", $ManagerPreference)) -ScriptBlock {
        param($PackagesToUninstall, $ManagerPreference)

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToUninstall -Preference $ManagerPreference

        $packagesWinget = $packagesSorted['Winget']
        $packagesChoco = $packagesSorted['Choco']
        Write-WinUtilLog -Component "Uninstall" -Message "Uninstall package manager split: winget=$(@($packagesWinget).Count), choco=$(@($packagesChoco).Count)"

        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text "Uninstalling apps..."

            if ($packagesWinget -contains "Microsoft.Edge") {
                New-Item -Path "$Env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
            }

            # Uninstall all selected programs in new window
            if($packagesWinget.Count -gt 0) {
                Install-WinUtilProgramWinget -Action Uninstall -Programs $packagesWinget
            }
            if($packagesChoco.Count -gt 0) {
                Install-WinUtilProgramChoco -Action Uninstall -Programs $packagesChoco
            }
            Hide-WPFInstallAppBusy
            Write-Host "==========================================="
            Write-Host "--       Uninstalls have finished       ---"
            Write-Host "==========================================="
            Write-WinUtilLog -Component "Uninstall" -Message "Uninstall workflow completed."
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
            Write-WinUtilLog -Level "ERROR" -Component "Uninstall" -Message "Uninstall workflow failed: $($_.Exception.Message)"
           Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" }
        } finally {
            $sync.ProcessRunning = $False
        }

    }
}
