function Invoke-WPFGetInstalled {
    <#

    .DESCRIPTION
    GUI Function to install Windows Features

    #>
    param($checkbox)

    if($sync.ProcessRunning){
        $msg = "Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(!(Test-WinUtilPackageManager -winget)){
        Write-Host "==========================================="
        Write-Host "--       Winget is not installed        ---"
        Write-Host "==========================================="
        return
    }

    Invoke-WPFRunspace -ArgumentList $checkbox -ScriptBlock {
        param($checkbox)

        $sync.ProcessRunning = $true

        Write-Host "Getting Installed Programs..."
        $Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox
        
        $sync.form.Dispatcher.invoke({
            foreach($checkbox in $Checkboxes){
                $sync.$checkbox.ischecked = $True
            }
        })

        Write-Host "Done..."
        $sync.ProcessRunning = $false
    }
}




