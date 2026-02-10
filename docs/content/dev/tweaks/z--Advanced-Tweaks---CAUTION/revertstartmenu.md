---
title: "Revert the new start menu"
description: ""
---

```json
  "WPFTweaksRevertStartMenu": {
    "Content": "Revert the new start menu",
    "Description": "Uses vivetool to revert the the original start menu from 24h2",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a027_",
    "InvokeScript": [
      "
      # This hardcodes version v0.3.4 But updates dont get grabbed from this repo so version v0.3.4 well not change
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip
      
      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip
      
      .\ViVeTool\ViVeTool.exe /disable /id:47205210
      
      Remove-Item ViVeTool -Recurse
      "
    ],
    "UndoScript": [
      "
      # This hardcodes version v0.3.4 But updates dont get grabbed from this repo so version v0.3.4 well not change
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip
      
      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip
      
      .\ViVeTool\ViVeTool.exe /enable /id:47205210
      
      Remove-Item ViVeTool -Recurse
      "
    ],
```
