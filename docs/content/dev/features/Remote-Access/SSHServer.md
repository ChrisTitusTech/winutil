---
title: "Enable OpenSSH Server"
description: ""
---

```powershell {filename="functions/public/Invoke-WPFSSHServer.ps1",linenos=inline,linenostart=1}
function Invoke-WPFSSHServer {
    <#

    .SYNOPSIS
        Invokes the OpenSSH Server install in a runspace

  #>

    Invoke-WPFRunspace -ScriptBlock {

        Invoke-WinUtilSSHServer

        Write-Host "======================================="
        Write-Host "--     OpenSSH Server installed!    ---"
        Write-Host "======================================="
    }
}
```
