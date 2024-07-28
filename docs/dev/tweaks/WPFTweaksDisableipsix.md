# Disable IPv6


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
  ]
}
```
</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
### Walkthrough.
#### Registry Key: DisabledComponents
**Path:** HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters

**Type:** DWord

**Original Value:** 0

**New Value:** 255



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

