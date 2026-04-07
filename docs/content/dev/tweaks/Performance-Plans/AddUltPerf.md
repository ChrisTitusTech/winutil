---
title: "Add and Activate Ultimate Performance Profile"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFUltimatePerformance.ps1",linenos=inline,linenostart=1}
function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Do
    )

    if ($Do) {
        if (-not (powercfg /list | Select-String "ChrisTitus - Ultimate Power Plan")) {
            if (-not (powercfg /list | Select-String "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")) {
                powercfg /restoredefaultschemes
                if (-not (powercfg /list | Select-String "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")) {
                    Write-Host "Failed to restore High Performance plan. Default plans do not include high performance. If you are on a laptop, do NOT use High Performance or Ultimate Performance plans." -ForegroundColor Red
                    return
                }
            }
            $guid = ((powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c) -split '\s+')[3]
            powercfg /changename $guid "ChrisTitus - Ultimate Power Plan"
            powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1
            powercfg /setacvalueindex $guid 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 1
            powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100
            powercfg /setactive $guid
            Write-Host "ChrisTitus - Ultimate Power Plan plan installed and activated." -ForegroundColor Green
        } else {
            Write-Host "ChrisTitus - Ultimate Power Plan plan is already installed." -ForegroundColor Red
            return
        }
    } else {
        if (powercfg /list | Select-String "ChrisTitus - Ultimate Power Plan") {
            powercfg /setactive SCHEME_BALANCED
            powercfg /delete ((powercfg /list | Select-String "ChrisTitus - Ultimate Power Plan").ToString().Split()[3])
            Write-Host "ChrisTitus - Ultimate Power Plan plan was removed." -ForegroundColor Red
        } else {
            Write-Host "ChrisTitus - Ultimate Power Plan plan is not installed." -ForegroundColor Yellow
        }
    }
}
```
