---
title: "Disable Teredo"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2067}
  "WPFTweaksTeredo": {
    "Content": "Disable Teredo",
    "Description": "Teredo network tunneling is a ipv6 feature that can cause additional latency, but may cause problems with some games",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
        "Name": "DisabledComponents",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0"
      }
    ],
    "InvokeScript": [
      "netsh interface teredo set state disabled"
    ],
    "UndoScript": [
      "netsh interface teredo set state default"
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
