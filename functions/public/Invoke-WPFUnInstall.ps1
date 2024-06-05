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
        $WarningMsg = "Please select the program(s) to install"
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
        $packagesWinget, $packagesChoco = {
            $packagesWinget = [System.Collections.Generic.List`1[System.Object]]::new()
            $packagesChoco = [System.Collections.Generic.List`1[System.Object]]::new()
            foreach ($package in $PackagesToInstall) {
                if ($package.winget -eq "na") {
                    $packagesChoco.add($package)
                    Write-Host "Queueing $($package.choco) for Chocolatey Uninstall"
                } else {
                    $packagesWinget.add($package)
                    Write-Host "Queueing $($package.winget) for Winget Uninstall"
                }
            }
            return $packagesWinget, $packagesChoco
        }.Invoke($PackagesToInstall)
        try{
            $sync.ProcessRunning = $true

            # Install all selected programs in new window
            if($packagesWinget.Count -gt 0){
                Install-WinUtilProgramWinget -ProgramsToInstall $packagesWinget -Manage "Uninstalling"
            }
            if($packagesChoco.Count -gt 0){
                Install-WinUtilProgramChoco -ProgramsToInstall $packagesChoco -Manage "Uninstalling"
            }

            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Uninstalls are Finished "
            $Messageboxbody = ("Done")
            $MessageIcon = [System.Windows.MessageBoxImage]::Information

            [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

            Write-Host "==========================================="
            Write-Host "--       Uninstalls have finished       ---"
            Write-Host "==========================================="
        }
        Catch {
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
        }
        $sync.ProcessRunning = $False
    }
}