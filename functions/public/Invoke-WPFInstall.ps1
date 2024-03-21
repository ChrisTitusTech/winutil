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

    $WingetInstall = (Get-WinUtilCheckBoxes)["Install"]

    if ($wingetinstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install or upgrade"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ArgumentList $WingetInstall -DebugPreference $DebugPreference -ScriptBlock {
        param($WingetInstall, $DebugPreference)

        try{
            $sync.ProcessRunning = $true

            Install-WinUtilWinget
            Install-WinUtilProgramWinget -ProgramsToInstall $WingetInstall

            Write-Host "==========================================="
            Write-Host "--      Installs have finished          ---"
            Write-Host "==========================================="
        }
        Catch {
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
        }
        Start-Sleep -Seconds 5
        $sync.ProcessRunning = $False
    }
}
