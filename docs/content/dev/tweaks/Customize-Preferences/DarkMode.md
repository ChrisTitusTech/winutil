---
title: "Dark Theme for Windows"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2143}
  "WPFToggleDarkMode": {
    "Content": "Dark Theme for Windows",
    "Description": "Enable/Disable Dark Mode.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        "Name": "AppsUseLightTheme",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1",
        "DefaultState": "false"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        "Name": "SystemUsesLightTheme",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1",
        "DefaultState": "false"
      }
    ],
    "InvokeScript": [
      "
      Invoke-WinUtilExplorerUpdate
      if ($sync.ThemeButton.Content -eq [char]0xF08C) {
        Invoke-WinutilThemeChange -theme \"Auto\"
      }
      "
    ],
    "UndoScript": [
      "
      Invoke-WinUtilExplorerUpdate
      if ($sync.ThemeButton.Content -eq [char]0xF08C) {
        Invoke-WinutilThemeChange -theme \"Auto\"
      }
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
