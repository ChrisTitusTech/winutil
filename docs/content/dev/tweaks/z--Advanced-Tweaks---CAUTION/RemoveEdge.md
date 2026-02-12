---
title: "Remove Microsoft Edge"
description: ""
---
```json {filename="config/tweaks.json",linenos=inline,linenostart=1446}
  "WPFTweaksRemoveEdge": {
    "Content": "Remove Microsoft Edge",
    "Description": "Unblocks Microsoft Edge uninstaller restrictions than uses that uninstaller to remove Microsoft Edge",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a028_",
    "InvokeScript": [
      "Invoke-WinUtilRemoveEdge"
    ],
    "UndoScript": [
      "
      Write-Host 'Installing Microsoft Edge...'
      winget install Microsoft.Edge --source winget
      "
    ],
```
