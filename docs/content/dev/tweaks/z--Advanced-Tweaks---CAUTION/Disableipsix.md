# Disable IPv6

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables IPv6.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable IPv6",
  "Description": "Disables IPv6.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a023_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
      "Name": "DisabledComponents",
      "Value": "255",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "Disable-NetAdapterBinding -Name \"*\" -ComponentID ms_tcpip6"
  ],
  "UndoScript": [
    "Enable-NetAdapterBinding -Name \"*\" -ComponentID ms_tcpip6"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Disableipsix"
}
```

</details>

## Invoke Script

```powershell
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

```
## Undo Script

```powershell
Enable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: DisabledComponents

**Type:** DWord

**Original Value:** 0

**New Value:** 255



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

