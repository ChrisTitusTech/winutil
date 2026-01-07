# Set Hibernation as default (good for laptops)

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Most modern laptops have connected standby enabled which drains the battery, this sets hibernation as default which will not drain the battery. See issue https://github.com/ChrisTitusTech/Winutil/issues/1399

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Set Hibernation as default (good for laptops)",
  "Description": "Most modern laptops have connected standby enabled which drains the battery, this sets hibernation as default which will not drain the battery. See issue https://github.com/ChrisTitusTech/Winutil/issues/1399",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a014_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerSettings\\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\\7bc4a2f9-d8fc-4469-b07b-33eb785aaca0",
      "OriginalValue": "1",
      "Name": "Attributes",
      "Value": "2",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerSettings\\abfc2519-3608-4c2a-94ea-171b0ed546ab\\94ac6d29-73ce-41a6-809f-6363ba21b47e",
      "OriginalValue": "0",
      "Name": "Attributes ",
      "Value": "2",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "
      Write-Host \"Turn on Hibernation\"
      Start-Process -FilePath powercfg -ArgumentList \"/hibernate on\" -NoNewWindow -Wait

      # Set hibernation as the default action
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-ac 60\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-dc 60\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-ac 10\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-dc 1\" -NoNewWindow -Wait
      "
  ],
  "UndoScript": [
    "
      Write-Host \"Turn off Hibernation\"
      Start-Process -FilePath powercfg -ArgumentList \"/hibernate off\" -NoNewWindow -Wait

      # Set standby to detault values
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-ac 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-dc 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-ac 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-dc 15\" -NoNewWindow -Wait
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/LaptopHibernation"
}
```

</details>

## Invoke Script

```powershell

      Write-Host "Turn on Hibernation"
      Start-Process -FilePath powercfg -ArgumentList "/hibernate on" -NoNewWindow -Wait

      # Set hibernation as the default action
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-ac 60" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-dc 60" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-ac 10" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-dc 1" -NoNewWindow -Wait


```
## Undo Script

```powershell

      Write-Host "Turn off Hibernation"
      Start-Process -FilePath powercfg -ArgumentList "/hibernate off" -NoNewWindow -Wait

      # Set standby to detault values
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-ac 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-dc 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-ac 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-dc 15" -NoNewWindow -Wait


```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: Attributes

**Type:** DWord

**Original Value:** 1

**New Value:** 2

### Registry Key: Attributes

**Type:** DWord

**Original Value:** 0

**New Value:** 2



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

