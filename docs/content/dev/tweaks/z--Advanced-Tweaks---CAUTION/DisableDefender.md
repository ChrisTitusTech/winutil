# Disable Windows Defender (Security) - Not Recommended

```json
"WPFTweaksDisableDefender": {
    "Content": "Disable Windows Defender (Security) - Not Recommended",
    "Description": "Disable Windows Defender (Security)",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a026_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender",
        "Name": "DisableAntiSpyware",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender",
        "Name": "DisableAntiVirus",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender",
        "Name": "ServiceKeepAlive",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
