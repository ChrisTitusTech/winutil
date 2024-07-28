# Disable Microsoft Copilot


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Disables MS Copilot AI built into Windows since 23H2.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Microsoft Copilot",
  "Description": "Disables MS Copilot AI built into Windows since 23H2.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a025_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsCopilot",
      "Name": "TurnOffWindowsCopilot",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKCU:\\Software\\Policies\\Microsoft\\Windows\\WindowsCopilot",
      "Name": "TurnOffWindowsCopilot",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "Name": "ShowCopilotButton",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "InvokeScript": [
    "\r\n      Write-Host \"Remove Copilot\"\r\n      dism /online /remove-package /package-name:Microsoft.Windows.Copilot\r\n      "
  ],
  "UndoScript": [
    "\r\n      Write-Host \"Install Copilot\"\r\n      dism /online /add-package /package-name:Microsoft.Windows.Copilot\r\n      "
  ]
}
```
</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
### Walkthrough.
#### Registry Key: TurnOffWindowsCopilot
**Path:** HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: TurnOffWindowsCopilot
**Path:** HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: ShowCopilotButton
**Path:** HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

