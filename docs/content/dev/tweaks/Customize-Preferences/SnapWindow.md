# Snap Window

```json
"WPFToggleSnapWindow": {
    "Content": "Snap Window",
    "Description": "If enabled you can align windows by dragging them. | Relogin Required",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a106_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Control Panel\\Desktop",
        "Name": "WindowArrangementActive",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "String"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
