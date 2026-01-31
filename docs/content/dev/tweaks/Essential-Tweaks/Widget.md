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
      Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers | Remove-AppxPackage -AllUsers
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Restoring widgets Microsoft Store Required\"
      start ms-windows-store://pdp/?productid=9MSSGKG348SP
      "
    ],
```
