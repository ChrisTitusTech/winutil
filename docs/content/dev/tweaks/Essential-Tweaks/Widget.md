---
title: "Widgets - Remove"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=61}
  "WPFTweaksWidget": {
    "Content": "Widgets - Remove",
    "Description": "Removes the annoying widgets in the bottom left of the Taskbar.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      # Sometimes if you dont stop the Widgets process the removal may fail

      Get-Process *Widget* | Stop-Process
      Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers | Remove-AppxPackage -AllUsers
      Get-AppxPackage MicrosoftWindows.Client.WebExperience -AllUsers | Remove-AppxPackage -AllUsers

      Invoke-WinUtilExplorerUpdate -action \"restart\"
      Write-Host \"Removed widgets\"
      "
    ],
```
