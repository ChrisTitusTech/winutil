function Invoke-WPFGetInstalled {
    <#

    .SYNOPSIS
        Invokes the function that gets the checkboxes to check in a new runspace

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)

    if($sync.ProcessRunning){
        $msg = "[Invoke-WPFGetInstalled] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget"){
        return
    }

    Invoke-WPFRunspace -ArgumentList $checkbox -DebugPreference $DebugPreference -ScriptBlock {
        param($checkbox, $DebugPreference)

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
