---
title: "Disable Teredo"
description: ""
---
```json
"WPFTweaksTeredo": {
    "Content": "Disable Teredo",
    "Description": "Teredo network tunneling is a ipv6 feature that can cause additional latency, but may cause problems with some games",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a024_",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
        "Name": "DisabledComponents",
        "Value": "1",
        "OriginalValue": "0",
        "Type": "DWord"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
