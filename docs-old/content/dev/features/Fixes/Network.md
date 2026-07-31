---
title: "Network - Reset"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFFixesNetwork.ps1",linenos=inline,linenostart=1}
function Invoke-WPFFixesNetwork {
    netsh winsock reset
    netsh int ip reset
    Write-Host "Network Configuration has been Reset. Please restart your computer."
}
```
