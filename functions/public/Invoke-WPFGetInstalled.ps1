function Invoke-WPFGetInstalled {
    <#
    TODO: Add the Option to use Chocolatey as Engine
    .SYNOPSIS
        Invokes the function that gets the checkboxes to check in a new runspace

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFGetInstalled] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(($sync.WPFpreferChocolatey.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }
    $preferChoco = $sync.WPFpreferChocolatey.IsChecked
    Invoke-WPFRunspace -ArgumentList $checkbox, $preferChoco -DebugPreference $DebugPreference -ScriptBlock {
        param($checkbox, $preferChoco, $DebugPreference)

        $sync.ProcessRunning = $true
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" })

        if($checkbox -eq "winget") {
            Write-Host "Getting Installed Programs..."
        }
        if($checkbox -eq "tweaks") {
            Write-Host "Getting Installed Tweaks..."
        }
        if ($preferChoco -and $checkbox -eq "winget") {
            $Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox "choco"
        }
        else{
            $Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox
        }

        $sync.form.Dispatcher.invoke({
            foreach($checkbox in $Checkboxes) {
                $sync.$checkbox.ischecked = $True
            }
        })

        Write-Host "Done..."
        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "None" })
    }
}
