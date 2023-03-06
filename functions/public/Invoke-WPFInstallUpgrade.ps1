function Invoke-WPFInstallUpgrade {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>
    if(!(Test-WinUtilPackageManager -winget)){
        Write-Host "==========================================="
        Write-Host "--       Winget is not installed        ---"
        Write-Host "==========================================="
        return
    }

    if(Get-WinUtilInstallerProcess -Process $global:WinGetInstall){
        $msg = "Install process is currently running. Please check for a powershell window labled 'Winget Install'"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Update-WinUtilProgramWinget

    Write-Host "==========================================="
    Write-Host "--           Updates started            ---"
    Write-Host "-- You can close this window if desired ---"
    Write-Host "==========================================="
}