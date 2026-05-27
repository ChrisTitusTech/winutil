---
title: "WinUtil Dev Command Launcher"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1833}
  "WPFToggleWinUtilDevLauncher": {
    "Content": "WinUtil Dev Command Launcher",
    "Description": "Installs a user-level 'winutil-dev' command launcher so you can run the development branch of WinUtil from any terminal.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\WinUtil",
        "Name": "DevCommandLauncher",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "false"
      }
    ],
    "InvokeScript": [
      "Invoke-WinUtilInstallDevLauncher"
    ],
    "UndoScript": [
      "Invoke-WinUtilUninstallDevLauncher"
    ],
    "link": "https://winutil.christitus.com/dev/tweaks/customize-preferences/winutildevlauncher"
  },
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
