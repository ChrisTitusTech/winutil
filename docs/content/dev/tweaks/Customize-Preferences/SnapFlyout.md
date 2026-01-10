# Snap Assist Flyout

```json
"WPFToggleSnapFlyout": {
    "Content": "Snap Assist Flyout",
    "Description": "If disabled then Snap preview is disabled when maximize button is hovered.",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a107_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "Name": "EnableSnapAssistFlyout",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      }
    ],
    "InvokeScript": [
      "
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
    "UndoScript": [
      "
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
