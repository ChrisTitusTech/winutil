---
title: "Microsoft Edge - Remove"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=575}
  "WPFTweaksRemoveEdge": {
    "Content": "Microsoft Edge - Remove",
    "Description": "Unblocks Microsoft Edge uninstaller restrictions then uses that uninstaller to remove Microsoft Edge.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
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
