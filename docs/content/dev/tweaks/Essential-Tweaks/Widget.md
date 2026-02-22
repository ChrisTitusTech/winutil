---
title: "Remove Widgets"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=61}
  "WPFTweaksWidget": {
    "Content": "Remove Widgets",
    "Description": "Removes the annoying widgets in the bottom left of the taskbar",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      # Sometimes if you dont stop the Widgets process the removal may fail

      Stop-Process -Name Widgets
      Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers | Remove-AppxPackage -AllUsers
      Get-AppxPackage MicrosoftWindows.Client.WebExperience -AllUsers | Remove-AppxPackage -AllUsers

      Invoke-WinUtilExplorerUpdate -action \"restart\"
      Write-Host \"Removed widgets\"
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Restoring widgets AppxPackages\"

      Add-AppxPackage -Register \"C:\\Program Files\\WindowsApps\\Microsoft.WidgetsPlatformRuntime*\\AppxManifest.xml\" -DisableDevelopmentMode
      Add-AppxPackage -Register \"C:\\Program Files\\WindowsApps\\MicrosoftWindows.Client.WebExperience*\\AppxManifest.xml\" -DisableDevelopmentMode

      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
```
