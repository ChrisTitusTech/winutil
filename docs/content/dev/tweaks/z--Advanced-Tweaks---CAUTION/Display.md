# Set Display for Performance

```json
"WPFTweaksDisplay": {
    "Content": "Set Display for Performance",
    "Description": "Sets the system preferences to performance. You can do this manually with sysdm.cpl as well.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a030_",
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
        "OriginalValue": "400",
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
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
