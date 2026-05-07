---
title: "CTT PowerShell Profile - Remove"
description: ""
---

```powershell {filename="functions/private/Invoke-WinUtilUninstallPSProfile.ps1",linenos=inline,linenostart=1}
function Invoke-WinUtilUninstallPSProfile {

    if (Test-Path ($Profile + ".bak")) {
        Move-Item -Path ($Profile + ".bak") -Destination $Profile
    } else {
        Remove-Item -Path $Profile
    }

    Write-Host "Successfully uninstalled CTT PowerShell Profile." -ForegroundColor Green
}
```
