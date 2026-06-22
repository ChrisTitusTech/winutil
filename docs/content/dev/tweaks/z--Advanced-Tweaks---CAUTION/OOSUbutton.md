---
title: "O&O ShutUp10++ - Run"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFOOSU.ps1",linenos=inline,linenostart=1}
function Invoke-WPFOOSU {
    try {
        $ProgressPreference = 'SilentlyContinue'

        Invoke-WebRequest -Uri https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile "$winutildir\ooshutup10.exe"
        Start-Process -FilePath "$winutildir\ooshutup10.exe"

        $ProgressPreference = 'Continue'
    } catch {
        Write-Error "Couldn't download O&O ShutUp10. Please make sure you have an active Internet connection."
    }
}
```
