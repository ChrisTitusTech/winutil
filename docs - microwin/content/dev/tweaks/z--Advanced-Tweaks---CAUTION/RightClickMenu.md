# Set Classic Right-Click Menu

```json
"WPFTweaksRightClickMenu": {
    "Content": "Set Classic Right-Click Menu ",
    "Description": "Great Windows 11 tweak to bring back good context menus when right clicking things in explorer.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a030_",
    "InvokeScript": [
      "
      New-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Name \"InprocServer32\" -force -value \"\"
      Write-Host Restarting explorer.exe ...
      Stop-Process -Name \"explorer\" -Force
      "
    ],
    "UndoScript": [
      "
      Remove-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Recurse -Confirm:$false -Force
      # Restarting Explorer in the Undo Script might not be necessary, as the Registry change without restarting Explorer does work, but just to make sure.
      Write-Host Restarting explorer.exe ...
      Stop-Process -Name \"explorer\" -Force
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
