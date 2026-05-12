---
title: "Adobe URL Block List - Enable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1071}
  "WPFTweaksBlockAdobeNet": {
    "Content": "Adobe URL Block List - Enable",
    "Description": "Reduces user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      $hostsUrl = \"https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/raw/refs/heads/master/hosts\"
      $hosts = \"$Env:SystemRoot\\System32\\drivers\\etc\\hosts\"

      Move-Item $hosts \"$hosts.bak\"
      Invoke-WebRequest $hostsUrl -OutFile $hosts
      ipconfig /flushdns

      Write-Host \"Added Adobe url block list from host file\"
      "
    ],
    "UndoScript": [
      "
      $hosts = \"$Env:SystemRoot\\System32\\drivers\\etc\\hosts\"

      Remove-Item $hosts
      Move-Item \"$hosts.bak\" $hosts
      ipconfig /flushdns

      Write-Host \"Removed Adobe url block list from host file\"
      "
    ],
```
