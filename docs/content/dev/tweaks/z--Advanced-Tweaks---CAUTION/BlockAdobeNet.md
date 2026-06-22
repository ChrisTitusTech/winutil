---
title: "Adobe URL Block List - Enable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1062}
  "WPFTweaksBlockAdobeNet": {
    "Content": "Adobe URL Block List - Enable",
    "Description": "Reduces user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      $hostsUrl = Invoke-RestMethod -Uri https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/raw/refs/heads/master/hosts
      Add-Content -Path \"$Env:SystemRoot\\System32\\drivers\\etc\\hosts\" -Value $hostsUrl

      ipconfig /flushdns
      Write-Host 'Added Adobe url block list from host file'
      "
    ],
    "UndoScript": [
      "
      Set-Content \"$Env:SystemRoot\\System32\\drivers\\etc\\hosts\" (
          (Get-Content \"$Env:SystemRoot\\System32\\drivers\\etc\\hosts\") -join \"`n\" -replace '(?s)#New Ver.*', ''
      )

      ipconfig /flushdns
      Write-Host 'Removed Adobe url block list from host file'
      "
    ],
```
