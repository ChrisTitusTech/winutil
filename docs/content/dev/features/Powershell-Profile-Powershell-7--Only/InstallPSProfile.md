---
title: "CTT PowerShell Profile - Install"
description: ""
---

```powershell {filename="functions/private/Invoke-WinUtilInstallPSProfile.ps1",linenos=inline,linenostart=1}
function Invoke-WinUtilInstallPSProfile {
    if (-not (Get-Command wt)) {
        Write-Host "Windows Terminal not found installing..."
        Install-WinUtilWinget
        winget install Microsoft.WindowsTerminal --source winget --silent
    }

    if (-not (Get-Command pwsh)) {
        Write-Host "Powershell 7 not found installing..."
        Install-WinUtilWinget
        winget install Microsoft.PowerShell --source winget --silent
    }

    wt new-tab pwsh -NoExit -Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex"
}
```
