function Invoke-WPFInstall {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>

    if($sync.ProcessRunning){
        $msg = "Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $WingetInstall = Get-WinUtilCheckBoxes -Group "WPFInstall"

    if ($wingetinstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ArgumentList $WingetInstall -scriptblock {
        param($WingetInstall)
        try{
            $sync.ProcessRunning = $true

            # Ensure winget is installed
            Install-WinUtilWinget

            # Install all winget programs in new window
            Install-WinUtilProgramWinget -ProgramsToInstall $WingetInstall

            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Installs are Finished "
            $Messageboxbody = ("Done")
            $MessageIcon = [System.Windows.MessageBoxImage]::Information
        
            [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

            Write-Host "==========================================="
            Write-Host "--      Installs have finished          ---"
            Write-Host "==========================================="
        }
        Catch {
            Write-Host "==========================================="
            Write-Host "--      Winget failed to install        ---"
            Write-Host "==========================================="
        }
        $sync.ProcessRunning = $False
    }
}