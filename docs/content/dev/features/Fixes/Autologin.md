---
title: "AutoLogon - Run"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFPanelAutologin.ps1",linenos=inline,linenostart=1}
function Invoke-WPFPanelAutologin {
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile "$winutildir\autologin.exe"
    Start-Process -FilePath "$winutildir\autologin.exe" -ArgumentList /accepteula
}
```
