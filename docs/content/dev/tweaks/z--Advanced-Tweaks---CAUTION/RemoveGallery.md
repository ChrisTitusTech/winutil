# Remove Gallery from explorer

```json
"WPFTweaksRemoveGallery": {
    "Content": "Remove Gallery from explorer",
    "Description": "Removes the Gallery from Explorer and sets This PC as default",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a029_",
    "InvokeScript": [
      "
      Remove-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\"
      "
    ],
    "UndoScript": [
      "
      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\"
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
