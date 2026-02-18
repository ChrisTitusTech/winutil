---
title: "Remove ALL MS Store Apps - NOT RECOMMENDED"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1647}
  "WPFTweaksDeBloat": {
    "Content": "Remove ALL MS Store Apps - NOT RECOMMENDED",
    "Description": "USE WITH CAUTION!!! This will remove ALL Microsoft store apps.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "appx": [
      "Microsoft.Microsoft3DViewer",
      "Microsoft.AppConnector",
      "Microsoft.BingFinance",
      "Microsoft.BingNews",
      "Microsoft.BingSports",
      "Microsoft.BingTranslator",
      "Microsoft.BingWeather",
      "Microsoft.BingFoodAndDrink",
      "Microsoft.BingHealthAndFitness",
      "Microsoft.BingTravel",
      "Clipchamp.Clipchamp",
      "Microsoft.Todos",
      "MicrosoftCorporationII.QuickAssist",
      "Microsoft.MicrosoftStickyNotes",
      "Microsoft.GetHelp",
      "Microsoft.GetStarted",
      "Microsoft.Messaging",
      "Microsoft.MicrosoftSolitaireCollection",
      "Microsoft.NetworkSpeedTest",
      "Microsoft.News",
      "Microsoft.Office.Lens",
      "Microsoft.Office.Sway",
      "Microsoft.Office.OneNote",
      "Microsoft.OneConnect",
      "Microsoft.People",
      "Microsoft.Print3D",
      "Microsoft.SkypeApp",
      "Microsoft.Wallet",
      "Microsoft.Whiteboard",
      "Microsoft.WindowsAlarms",
      "Microsoft.WindowsCommunicationsApps",
      "Microsoft.WindowsFeedbackHub",
      "Microsoft.WindowsMaps",
      "Microsoft.WindowsSoundRecorder",
      "Microsoft.ConnectivityStore",
      "Microsoft.ScreenSketch",
      "Microsoft.MixedReality.Portal",
      "Microsoft.ZuneMusic",
      "Microsoft.ZuneVideo",
      "Microsoft.MicrosoftOfficeHub",
      "MsTeams",
      "*EclipseManager*",
      "*ActiproSoftwareLLC*",
      "*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
      "*Duolingo-LearnLanguagesforFree*",
      "*PandoraMediaInc*",
      "*CandyCrush*",
      "*BubbleWitch3Saga*",
      "*Wunderlist*",
      "*Flipboard*",
      "*Twitter*",
      "*Facebook*",
      "*Royal Revolt*",
      "*Sway*",
      "*Speed Test*",
      "*Dolby*",
      "*Viber*",
      "*ACGMediaPlayer*",
      "*Netflix*",
      "*OneCalendar*",
      "*LinkedInForWindows*",
      "*HiddenCityMysteryofShadows*",
      "*Hulu*",
      "*HiddenCity*",
      "*AdobePhotoshopExpress*",
      "*HotspotShieldFreeVPN*",
      "*Microsoft.Advertising.Xaml*"
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
