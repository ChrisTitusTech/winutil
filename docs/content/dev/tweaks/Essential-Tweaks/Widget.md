# Remove Widgets

```json
  "WPFTweaksWidget": {
    "Content": "Remove Widgets",
    "Description": "Removes the annoying widgets in the bottom left of the taskbar",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a005_",
    "InvokeScript": [
      "
      # Sometimes if you dont stop Widgets Process for removal to work
      Stop-Procces -Name Widgets
      Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers | Remove-AppxPackage -AllUsers
      
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      Write-Host \"Removed widgets\"
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Restoring widgets AppxPackages\"
      Add-AppxPackage -DisableDevelopmentMode -Register \"C:\\Program Files\\WindowsApps\\Microsoft.WidgetsPlatformRuntime*\\AppxManifest.xml\"
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
```
