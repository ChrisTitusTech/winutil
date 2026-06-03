---
title: "AutoLogon - Run"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFPanelAutologin.ps1",linenos=inline,linenostart=1}
function Invoke-WPFPanelAutologin {
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile "$Env:Temp\autologin.exe"
    Start-Process -FilePath "$Env:Temp\autologin.exe" -ArgumentList /accepteula
}
```
