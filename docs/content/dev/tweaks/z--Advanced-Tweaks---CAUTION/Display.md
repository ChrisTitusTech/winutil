# Set Display for Performance

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Sets the system preferences to performance. You can do this manually with sysdm.cpl as well.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Set Display for Performance",
  "Description": "Sets the system preferences to performance. You can do this manually with sysdm.cpl as well.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a027_",
  "registry": [
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "DragFullWindows",
      "Value": "0",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "MenuShowDelay",
      "Value": "200",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop\\WindowMetrics",
      "OriginalValue": "1",
      "Name": "MinAnimate",
      "Value": "0",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Keyboard",
      "OriginalValue": "1",
      "Name": "KeyboardDelay",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ListviewAlphaSelect",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ListviewShadow",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarAnimations",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects",
      "OriginalValue": "1",
      "Name": "VisualFXSetting",
      "Value": "3",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\DWM",
      "OriginalValue": "1",
      "Name": "EnableAeroPeek",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarMn",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarDa",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ShowTaskViewButton",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Search",
      "OriginalValue": "1",
      "Name": "SearchboxTaskbarMode",
      "Value": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "Set-ItemProperty -Path \"HKCU:\\Control Panel\\Desktop\" -Name \"UserPreferencesMask\" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))"
  ],
  "UndoScript": [
    "Remove-ItemProperty -Path \"HKCU:\\Control Panel\\Desktop\" -Name \"UserPreferencesMask\""
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Display"
}
```

</details>

## Invoke Script

```powershell
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))

```
## Undo Script

```powershell
Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask"

```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: DragFullWindows

**Type:** String

**Original Value:** 1

**New Value:** 0

### Registry Key: MenuShowDelay

**Type:** String

**Original Value:** 1

**New Value:** 200

### Registry Key: MinAnimate

**Type:** String

**Original Value:** 1

**New Value:** 0

### Registry Key: KeyboardDelay

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ListviewAlphaSelect

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ListviewShadow

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: TaskbarAnimations

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: VisualFXSetting

**Type:** DWord

**Original Value:** 1

**New Value:** 3

### Registry Key: EnableAeroPeek

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: TaskbarMn

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: TaskbarDa

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ShowTaskViewButton

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SearchboxTaskbarMode

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

