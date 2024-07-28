function Invoke-WPFUnInstall {
    <#

    .SYNOPSIS
        Uninstalls the selected programs

    #>

    if($sync.ProcessRunning){
        $msg = "[Invoke-WPFUnInstall] Install process is currently running"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $PackagesToInstall = (Get-WinUtilCheckBoxes)["Install"]

    if ($PackagesToInstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to uninstall"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageboxTitle = "Are you sure?"
    $Messageboxbody = ("This will uninstall the following applications: `n $($PackagesToInstall | Format-Table | Out-String)")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    $confirm = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

    if($confirm -eq "No"){return}


    Invoke-WPFRunspace -ArgumentList $PackagesToInstall -DebugPreference $DebugPreference -ScriptBlock {
        param($PackagesToInstall, $DebugPreference)
        if ($PackagesToInstall.count -eq 1){
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }
        $packagesWinget, $packagesChoco = {
            $packagesWinget = [System.Collections.Generic.List`1[System.Object]]::new()
            $packagesChoco = [System.Collections.Generic.List`1[System.Object]]::new()
            foreach ($package in $PackagesToInstall) {
                if ($package.winget -eq "na") {
                    $packagesChoco.add($package)
                    Write-Host "Queueing $($package.choco) for Chocolatey Uninstall"
                } else {
                    $packagesWinget.add($($package.winget))
                    Write-Host "Queueing $($package.winget) for Winget Uninstall"
                }
            }
            return $packagesWinget, $packagesChoco
        }.Invoke($PackagesToInstall)
        try{
            $sync.ProcessRunning = $true

            # Install all selected programs in new window
            if($packagesWinget.Count -gt 0){
                Invoke-WinUtilWingetProgram -Action Uninstall -Programs $packagesWinget
            }
            if($packagesChoco.Count -gt 0){
                Install-WinUtilProgramChoco -ProgramsToInstall $packagesChoco -Manage "Uninstalling"
            }

            Write-Host "==========================================="
            Write-Host "--       Uninstalls have finished       ---"
            Write-Host "==========================================="
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
        }
        Catch {
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
        $sync.ProcessRunning = $False

    }
}
