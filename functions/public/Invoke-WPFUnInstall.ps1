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
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($PackagesToUninstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to uninstall"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageboxTitle = "Are you sure?"
    $Messageboxbody = ("This will uninstall the following applications: `n $($PackagesToUninstall | Select-Object Name, Description| Out-String)")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    $confirm = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

    if($confirm -eq "No") {return}

    $ManagerPreference = $sync["ManagerPreference"]

    Invoke-WPFRunspace -ParameterList @(("PackagesToUninstall", $PackagesToUninstall),("ManagerPreference", $ManagerPreference)) -ScriptBlock {
        param($PackagesToUninstall, $ManagerPreference)

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToUninstall -Preference $ManagerPreference
        $packagesWinget = $packagesSorted[[PackageManagers]::Winget]
        $packagesChoco = $packagesSorted[[PackageManagers]::Choco]

        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text "Uninstalling apps..."

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
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" }
        } catch {
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
           Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" }
        }
        $sync.ProcessRunning = $False

    }
}
