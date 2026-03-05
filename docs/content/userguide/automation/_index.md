---
title: Automation
weight: 7
---

The Automation option in Winutil allows you to run Winutil from an exported config file.

You can create your own config in the app by clicking the gear icon in the top-right corner, then choosing Export and saving the file.

You can automate Winutil launch with this command:
```powershell
& ([ScriptBlock]::Create((irm "https://christitus.com/win"))) -Config "C:\Path\To\Config.json" -Run
```
