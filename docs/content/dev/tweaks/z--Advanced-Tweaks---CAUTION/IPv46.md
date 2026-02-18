---
title: "Prefer IPv4 over IPv6"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2051}
  "WPFTweaksIPv46": {
    "Content": "Prefer IPv4 over IPv6",
    "Description": "To set the IPv4 preference can have latency and security benefits on private networks where IPv6 is not configured.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
        "Name": "DisabledComponents",
        "Value": "32",
        "Type": "DWord",
        "OriginalValue": "0"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
