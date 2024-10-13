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

    if(($sync.ChocoRadioButton.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }
    $preferChoco = $sync.ChocoRadioButton.IsChecked
    $sync.ItemsControl.Dispatcher.Invoke([action]{  
        $sync.ItemsControl.Items | ForEach-Object   { $_.Visibility = [Windows.Visibility]::Collapsed}
        $null = $sync.itemsControl.Items.Add($sync.LoadingLabel)
    })
    Invoke-WPFRunspace -ArgumentList $checkbox, $preferChoco -ParameterList @(,("ShowOnlyCheckedApps",${function:Show-OnlyCheckedApps})) -DebugPreference $DebugPreference -ScriptBlock {
        param($checkbox, $preferChoco, $ShowOnlyCheckedApps,$DebugPreference)

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
        $sync.ItemsControl.Dispatcher.Invoke([action]{
            $ShowOnlyCheckedApps.Invoke($sync.SelectedApps, $sync.ItemsControl)
            $sync.ItemsControl.Items.Remove($sync.LoadingLabel)
        })
        Write-Host "Done..."
        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "None" })
    }
}
