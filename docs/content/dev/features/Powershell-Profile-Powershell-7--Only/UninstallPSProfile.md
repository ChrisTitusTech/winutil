---
title: "Uninstall CTT PowerShell Profile"
description: ""
---

```powershell {filename="functions/private/Invoke-WinUtilUninstallPSProfile.ps1",linenos=inline,linenostart=1}
function Invoke-WinUtilUninstallPSProfile {
    if (Test-Path ($Profile + '.bak')) {
        Remove-Item $Profile
        Rename-Item ($Profile + '.bak') -NewName $Profile
    }
    else {
        Remove-Item $Profile
    }

    Write-Host "Successfully uninstalled CTT Powershell Profile" -ForegroundColor Green
}
```
