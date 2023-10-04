function Invoke-WPFFeatureInstall {
        <#
    
        .DESCRIPTION
        GUI Function to install Windows Features
    
    #>

    if($sync.ProcessRunning){
        $msg = "Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $Features = Get-WinUtilCheckBoxes -Group "WPFFeature"

    Invoke-WPFRunspace -ArgumentList $Features -ScriptBlock {
        param($Features)

        $sync.ProcessRunning = $true

        Invoke-WinUtilFeatureInstall $Features

        $sync.ProcessRunning = $false
        Write-Host "==================================="
        Write-Host "---   Features are Installed    ---"
        Write-Host "---  A Reboot may be required   ---"
        Write-Host "==================================="
    
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "All features are now installed "
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
    
        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
    }
}