# Disable Windows Defender (Security) --- Not Recommended
```json
"WPFTweaksDisableDefender": {
    "Content": "Disable Windows Defender (Security) --- Not Recommended",
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
