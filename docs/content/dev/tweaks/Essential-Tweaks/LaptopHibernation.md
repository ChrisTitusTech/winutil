---
title: "Set Hibernation as default (good for laptops)"
description: ""
---
```json
"WPFTweaksLaptopHibernation": {
    "Content": "Set Hibernation as default (good for laptops)",
    "Description": "Most modern laptops have connected standby enabled which drains the battery, this sets hibernation as default which will not drain the battery. See issue https://github.com/ChrisTitusTech/winutil/issues/1399",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a030_",
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
      powercfg.exe /hibernate on

      # Set hibernation as the default action
      powercfg.exe change standby-timeout-ac 60
      powercfg.exe change standby-timeout-dc 60
      powercfg.exe change monitor-timeout-ac 10
      powercfg.exe change monitor-timeout-dc 1
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Turn off Hibernation\"
      powercfg.exe /hibernate off

      # Set standby to default values
      powercfg.exe change standby-timeout-ac 15
      powercfg.exe change standby-timeout-dc 15
      powercfg.exe change monitor-timeout-ac 15
      powercfg.exe change monitor-timeout-dc 15
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
