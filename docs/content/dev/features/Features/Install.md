# Install Features

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Install Features",
  "category": "Features",
  "panel": "1",
  "Order": "a060_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/Install"
}
```

</details>

## Function: Invoke-WPFFeatureInstall

```powershell
function Invoke-WPFFeatureInstall {
    <#

    .SYNOPSIS
        Installs selected Windows Features

    #>

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFFeatureInstall] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $Features = (Get-WinutilCheckBoxes)["WPFFeature"]

    Invoke-WPFRunspace -ArgumentList $Features -DebugPreference $DebugPreference -ScriptBlock {
        param($Features, $DebugPreference)
        $sync.ProcessRunning = $true
        if ($Features.count -eq 1) {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }

        Invoke-WinutilFeatureInstall $Features

        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "None" -overlay "checkmark" })

        Write-Host "==================================="
        Write-Host "---   Features are Installed    ---"
        Write-Host "---  A Reboot may be required   ---"
        Write-Host "==================================="
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

