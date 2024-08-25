function Invoke-WPFFeatureInstall {
    <#

    .SYNOPSIS
        Installs selected Windows Features

    #>

    param (
        $FeatureConfig
    )

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFFeatureInstall] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($FeatureConfig) {
        $Features = $FeatureConfig
        $automation = $true
    } else {
        $Features = (Get-WinUtilCheckBoxes)["WPFFeature"]
        $automation = $false
    }

    Invoke-WPFRunspace -ArgumentList $Features, $automation -DebugPreference $DebugPreference -ScriptBlock {
        param($Features, $automation, $DebugPreference)
        $sync.ProcessRunning = $true
        if ($Features.count -eq 1) {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }

        Invoke-WinUtilFeatureInstall $Features

        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })

        Write-Host "==================================="
        Write-Host "---   Features are Installed    ---"
        Write-Host "---  A Reboot may be required   ---"
        Write-Host "==================================="
    }
}
