# Undo Selected Tweaks

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Undo Selected Tweaks",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a042_",
  "Type": "Button",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Undoall"
}
```

</details>

## Function: Invoke-WPFundoall

```powershell
function Invoke-WPFundoall {
    <#

    .SYNOPSIS
        Undoes every selected tweak

    #>

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFundoall] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $tweaks = (Get-WinutilCheckBoxes)["WPFtweaks"]

    if ($tweaks.count -eq 0) {
        $msg = "Please check the tweaks you wish to undo."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ArgumentList $tweaks -DebugPreference $DebugPreference -ScriptBlock {
        param($tweaks, $DebugPreference)

        $sync.ProcessRunning = $true
        if ($tweaks.count -eq 1) {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }


        for ($i = 0; $i -lt $tweaks.Count; $i++) {
            Set-WinutilProgressBar -Label "Undoing $($tweaks[$i])" -Percent ($i / $tweaks.Count * 100)
            Invoke-Winutiltweaks $tweaks[$i] -undo $true
            $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -value ($i/$tweaks.Count) })
        }

        Set-WinutilProgressBar -Label "Undo Tweaks Finished" -Percent 100
        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "None" -overlay "checkmark" })
        Write-Host "=================================="
        Write-Host "---  Undo Tweaks are Finished  ---"
        Write-Host "=================================="

    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

