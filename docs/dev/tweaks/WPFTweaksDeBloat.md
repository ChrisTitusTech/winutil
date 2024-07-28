# Remove ALL MS Store Apps - NOT RECOMMENDED


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

USE WITH CAUTION!!!!! This will remove ALL Microsoft store apps other than the essentials to make winget work. Games installed by MS Store ARE INCLUDED!

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Remove ALL MS Store Apps - NOT RECOMMENDED",
  "Description": "USE WITH CAUTION!!!!! This will remove ALL Microsoft store apps other than the essentials to make winget work. Games installed by MS Store ARE INCLUDED!",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a028_",
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
    "Microsoft.MinecraftUWP",
    "Microsoft.GamingServices",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
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
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsPhone",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.XboxApp",
    "Microsoft.ConnectivityStore",
    "Microsoft.CommsPhone",
    "Microsoft.ScreenSketch",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.MixedReality.Portal",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
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
    "*LinkedInforWindows*",
    "*HiddenCityMysteryofShadows*",
    "*Hulu*",
    "*HiddenCity*",
    "*AdobePhotoshopExpress*",
    "*HotspotShieldFreeVPN*",
    "*Microsoft.Advertising.Xaml*"
  ],
  "InvokeScript": [
    "\r\n        $TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')\r\n        $TeamsUpdateExePath = [System.IO.Path]::Combine($TeamsPath, 'Update.exe')\r\n\r\n        Write-Host \"Stopping Teams process...\"\r\n        Stop-Process -Name \"*teams*\" -Force -ErrorAction SilentlyContinue\r\n\r\n        Write-Host \"Uninstalling Teams from AppData\\Microsoft\\Teams\"\r\n        if ([System.IO.File]::Exists($TeamsUpdateExePath)) {\r\n            # Uninstall app\r\n            $proc = Start-Process $TeamsUpdateExePath \"-uninstall -s\" -PassThru\r\n            $proc.WaitForExit()\r\n        }\r\n\r\n        Write-Host \"Removing Teams AppxPackage...\"\r\n        Get-AppxPackage \"*Teams*\" | Remove-AppxPackage -ErrorAction SilentlyContinue\r\n        Get-AppxPackage \"*Teams*\" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue\r\n\r\n        Write-Host \"Deleting Teams directory\"\r\n        if ([System.IO.Directory]::Exists($TeamsPath)) {\r\n            Remove-Item $TeamsPath -Force -Recurse -ErrorAction SilentlyContinue\r\n        }\r\n\r\n        Write-Host \"Deleting Teams uninstall registry key\"\r\n        # Uninstall from Uninstall registry key UninstallString\r\n        $us = (Get-ChildItem -Path HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall, HKLM:\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like '*Teams*'}).UninstallString\r\n        if ($us.Length -gt 0) {\r\n            $us = ($us.Replace('/I', '/uninstall ') + ' /quiet').Replace('  ', ' ')\r\n            $FilePath = ($us.Substring(0, $us.IndexOf('.exe') + 4).Trim())\r\n            $ProcessArgs = ($us.Substring($us.IndexOf('.exe') + 5).Trim().replace('  ', ' '))\r\n            $proc = Start-Process -FilePath $FilePath -Args $ProcessArgs -PassThru\r\n            $proc.WaitForExit()\r\n        }\r\n      "
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

