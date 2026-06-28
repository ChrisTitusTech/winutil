---
title: "Enable Sudo (Win 11 24H2+)"
description: ""
---

```json {filename="config/tweaks.json"}
  "WPFTweaksEnableSudo": {
    "Content": "Enable Sudo (Win 11 24H2+)",
    "Description": "Enables native Sudo functionality in Windows (Inline mode). Requires Windows 11 Build 26045 (24H2) or higher.",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Sudo",
        "Name": "Enabled",
        "Value": "3",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
    "link": "https://winutil.christitus.com/dev/tweaks/essential-tweaks/enablesudo"
  },
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Sudo Modes

Windows offers three modes for Sudo:
- **`1`**: In a new window
- **`2`**: With input disabled
- **`3`**: Inline (similar to Linux)

This tweak sets the `Value` to `3` to enable **Inline mode**. This provides the most seamless and familiar experience, as it executes the elevated command in the exact same console window, just like `sudo` on Linux.
