# Disable Teredo

Last Updated: 2024-08-07


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Teredo network tunneling is a ipv6 feature that can cause additional latency.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Teredo",
  "Description": "Teredo network tunneling is a ipv6 feature that can cause additional latency.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
      "Name": "DisabledComponents",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "netsh interface teredo set state disabled"
  ],
  "UndoScript": [
    "netsh interface teredo set state default"
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Teredo"
}
```

</details>

## Invoke Script

```powershell
netsh interface teredo set state disabled

```
## Undo Script

```powershell
netsh interface teredo set state default

```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: DisabledComponents

**Type:** DWord

**Original Value:** 0

**New Value:** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

