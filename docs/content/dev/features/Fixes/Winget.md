---
title: "WinGet Reinstall"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFFixesWinget.ps1",linenos=inline,linenostart=1}
function Invoke-WPFFixesWinget {

    <#

    .SYNOPSIS
        Fixes Winget by running choco install winget
    .DESCRIPTION
        BravoNorris for the fantastic idea of a button to reinstall winget
    #>
    # Install Choco if not already present
    try {
        Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
        Write-Host "==> Starting Winget Repair"
        Install-WinUtilWinget -Force
    } catch {
        Write-Error "Failed to install winget: $_"
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    } finally {
        Write-Host "==> Finished Winget Repair"
        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
    }

}
```
