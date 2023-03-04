function Invoke-WPFInstall {
    $WingetInstall = Get-WinUtilCheckBoxes -Group "WPFInstall"

    if ($wingetinstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(Get-WinUtilInstallerProcess -Process $global:WinGetInstall){
        $msg = "Install process is currently running. Please check for a powershell window labled 'Winget Install'"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    try{

        # Ensure winget is installed
        Install-WinUtilWinget

        # Install all winget programs in new window
        Install-WinUtilProgramWinget -ProgramsToInstall $WingetInstall  

        Write-Host "==========================================="
        Write-Host "--          Installs started            ---"
        Write-Host "-- You can close this window if desired ---"
        Write-Host "==========================================="
    }
    Catch [WingetFailedInstall]{
        Write-Host "==========================================="
        Write-Host "--      Winget failed to install        ---"
        Write-Host "==========================================="
    }
}