---
title: "Remove Unwanted Pre-Installed Apps"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1676}
  "WPFTweaksDeBloat": {
    "Content": "Remove Unwanted Pre-Installed Apps",
    "Description": "This will remove a bunch of Windows pre-installed applications which most people dont want on there system.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "appx": [
      "Microsoft.WindowsFeedbackHub",
      "Microsoft.BingNews",
      "Microsoft.BingSearch",
      "Microsoft.BingWeather",
      "Clipchamp.Clipchamp",
      "Microsoft.Todos",
      "Microsoft.PowerAutomateDesktop",
      "Microsoft.MicrosoftSolitaireCollection",
      "Microsoft.WindowsSoundRecorder",
      "Microsoft.MicrosoftStickyNotes",
      "Microsoft.Windows.DevHome",
      "Microsoft.Paint",
      "Microsoft.OutlookForWindows",
      "Microsoft.WindowsAlarms",
      "Microsoft.StartExperiencesApp",
      "Microsoft.GetHelp",
      "Microsoft.ZuneMusic",
      "MicrosoftCorporationII.QuickAssist",
      "MSTeams"
    ],
    "InvokeScript": [
      "
      $TeamsPath = \"$Env:LocalAppData\\Microsoft\\Teams\\Update.exe\"

      if (Test-Path $TeamsPath) {
        Write-Host \"Uninstalling Teams\"
        Start-Process $TeamsPath -ArgumentList -uninstall -wait

        Write-Host \"Deleting Teams directory\"
        Remove-Item $TeamsPath -Recurse -Force
      }
      "
    ],
```
