# Mouse Acceleration

```json
"WPFToggleMouseAcceleration": {
    "Content": "Mouse Acceleration",
    "Description": "If Enabled then Cursor movement is affected by the speed of your physical mouse movements.",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a109_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Control Panel\\Mouse",
        "Name": "MouseSpeed",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      },
      {
        "Path": "HKCU:\\Control Panel\\Mouse",
        "Name": "MouseThreshold1",
        "Value": "6",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      },
      {
        "Path": "HKCU:\\Control Panel\\Mouse",
        "Name": "MouseThreshold2",
        "Value": "10",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
