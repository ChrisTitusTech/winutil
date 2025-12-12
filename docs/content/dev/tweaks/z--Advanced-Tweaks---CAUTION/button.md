# Run Tweaks

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Run Tweaks",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a041_",
  "Type": "Button",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/button"
}
```

</details>

## Function: Invoke-WPFtweaksbutton

```powershell
function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        Invokes the functions associated with each group of checkboxes

  #>

  if($sync.ProcessRunning) {
    $msg = "[Invoke-WPFtweaksbutton] Install process is currently running."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  $Tweaks = (Get-WinutilCheckBoxes)["WPFTweaks"]

  Set-WinutilDNS -DNSProvider $sync["WPFchangedns"].text

  if ($tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default") {
    $msg = "Please check the tweaks you wish to perform."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Write-Debug "Number of tweaks to process: $($Tweaks.Count)"

  Invoke-WPFRunspace -ArgumentList $Tweaks -DebugPreference $DebugPreference -ScriptBlock {
    param($Tweaks, $DebugPreference)
    Write-Debug "Inside Number of tweaks to process: $($Tweaks.Count)"

    $sync.ProcessRunning = $true

    if ($Tweaks.count -eq 1) {
        $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
    } else {
        $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
    }
    # Execute other selected tweaks

    for ($i = 0; $i -lt $Tweaks.Count; $i++) {
      Set-WinutilProgressBar -Label "Applying $($tweaks[$i])" -Percent ($i / $Tweaks.Count * 100)
      Invoke-WinutilTweaks $tweaks[$i]$sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -value ($i/$Tweaks.Count) })
    }
    Set-WinutilProgressBar -Label "Tweaks finished" -Percent 100
    $sync.ProcessRunning = $false
    $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -state "None" -overlay "checkmark" })
    Write-Host "================================="
    Write-Host "--     Tweaks are Finished    ---"
    Write-Host "================================="

    # $ButtonType = [System.Windows.MessageBoxButton]::OK
    # $MessageboxTitle = "Tweaks are Finished "
    # $Messageboxbody = ("Done")
    # $MessageIcon = [System.Windows.MessageBoxImage]::Information
    # [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
  }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

