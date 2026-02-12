---
title: "Adobe Network Block"
description: ""
---
```json {filename="config/tweaks.json",linenos=inline,linenostart=1982}
  "WPFTweaksBlockAdobeNet": {
    "Content": "Adobe Network Block",
    "Description": "Reduce user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      $hostsUrl = \"https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/raw/refs/heads/master/hosts\"
      $hosts = \"$env:SystemRoot\\System32\\drivers\\etc\\hosts\"

      Copy-Item $hosts \"$env:SystemRoot\\System32\\drivers\\etc\\hosts\\$hosts.bak\"
      Invoke-WebRequest $hostsUrl -OutFile $hosts
      ipconfig /flushdns

      Write-Host \"Added Adobe url block list from host file\"
      "
    ],
    "UndoScript": [
      "
      $hosts = \"$env:SystemRoot\\System32\\drivers\\etc\\hosts\"
      $backup = \"$env:SystemRoot\\System32\\drivers\\etc\\hosts\\$hosts.bak\"

      Remove-Item $hosts
      ipconfig /flushdns

      Write-Host \"Removed Adobe url block list from host file\"
      "
    ],
```
