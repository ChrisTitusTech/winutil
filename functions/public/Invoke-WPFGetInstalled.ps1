function Invoke-WPFGetInstalled {
    <#

    .DESCRIPTION
    placeholder

    #>
    param($checkbox)

    if($sync.ProcessRunning){
        $msg = "Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(!(Test-WinUtilPackageManager -winget) -and $checkbox -eq "winget"){
        Write-Host "==========================================="
        Write-Host "--       Winget is not installed        ---"
        Write-Host "==========================================="
        return
    }

    Invoke-WPFRunspace -ArgumentList $checkbox -ScriptBlock {
        param($checkbox)

        $sync.ProcessRunning = $true

        if($checkbox -eq "winget"){
            Write-Host "Getting Installed Programs..."
        }
        if($checkbox -eq "tweaks"){
            Write-Host "Getting Installed Tweaks..."
        }
        
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