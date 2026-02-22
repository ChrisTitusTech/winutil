---
title: "Block Razer Software Installs"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1908}
  "WPFTweaksRazerBlock": {
    "Content": "Block Razer Software Installs",
    "Description": "Blocks ALL Razer Software installations. The hardware works fine without any software.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DriverSearching",
        "Name": "SearchOrderConfig",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Device Installer",
        "Name": "DisableCoInstallers",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0"
      }
    ],
    "InvokeScript": [
      "
      $RazerPath = \"C:\\Windows\\Installer\\Razer\"

      if (Test-Path $RazerPath) {
        Remove-Item $RazerPath\\* -Recurse -Force
      }
      else {
        New-Item -Path $RazerPath -ItemType Directory
      }

      icacls $RazerPath /deny \"Everyone:(W)\"
      "
    ],
    "UndoScript": [
      "
      icacls \"C:\\Windows\\Installer\\Razer\" /remove:d Everyone
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
