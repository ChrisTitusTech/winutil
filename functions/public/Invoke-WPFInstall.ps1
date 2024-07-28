function Invoke-WPFInstall {
    <#

    .SYNOPSIS
        Installs the selected programs using winget, if one or more of the selected programs are already installed on the system, winget will try and perform an upgrade if there's a newer version to install.

    #>

    if($sync.ProcessRunning){
        $msg = "[Invoke-WPFInstall] An Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $PackagesToInstall = (Get-WinUtilCheckBoxes)["Install"]
    Write-Host $PackagesToInstall
    if ($PackagesToInstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install or upgrade"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }


    Invoke-WPFRunspace -ArgumentList $PackagesToInstall -DebugPreference $DebugPreference -ScriptBlock {
        param($PackagesToInstall, $DebugPreference)
        if ($PackagesToInstall.count -eq 1){
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }
        $packagesWinget, $packagesChoco = {
            $packagesWinget = [System.Collections.ArrayList]::new()
            $packagesChoco = [System.Collections.Generic.List`1[System.Object]]::new()
            foreach ($package in $PackagesToInstall) {
                if ($package.winget -eq "na") {
                    $packagesChoco.add($package)
                    Write-Host "Queueing $($package.choco) for Chocolatey install"
                } else {
                    $null = $packagesWinget.add($($package.winget))
                    Write-Host "Queueing $($package.winget) for Winget install"
                }
            }
            return $packagesWinget, $packagesChoco
        }.Invoke($PackagesToInstall)

        try{
            $sync.ProcessRunning = $true
            $errorPackages = @()
            if($packagesWinget.Count -gt 0){
                Install-WinUtilWinget
                $errorPackages += Invoke-WinUtilWingetProgram -Action Install -Programs $packagesWinget 
                $errorPackages| ForEach-Object {if($_.choco -ne "na") {$packagesChoco += $_}}
            }
            if($packagesChoco.Count -gt 0){
                Install-WinUtilChoco
                Install-WinUtilProgramChoco -ProgramsToInstall $packagesChoco
            }
            Write-Host "==========================================="
            Write-Host "--      Installs have finished          ---"
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
