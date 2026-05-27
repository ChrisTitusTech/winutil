---
title: "WinUtil Command Launcher"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1809}
  "WPFToggleWinUtilLauncher": {
    "Content": "WinUtil Command Launcher",
    "Description": "Installs a user-level 'winutil' command launcher so you can run WinUtil from any terminal with standard parameters forwarded.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\WinUtil",
        "Name": "CommandLauncher",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "false"
      }
    ],
    "InvokeScript": [
      "Invoke-WinUtilInstallLauncher"
    ],
    "UndoScript": [
      "Invoke-WinUtilUninstallLauncher"
    ],
    "link": "https://winutil.christitus.com/dev/tweaks/customize-preferences/winutillauncher"
  },
```


## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
