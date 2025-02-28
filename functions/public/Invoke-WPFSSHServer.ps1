function Invoke-WPFSSHServer {
    <#

    .SYNOPSIS
        Invokes the OpenSSH Server install in a runspace

  #>

    Invoke-WPFRunspace -DebugPreference $DebugPreference -ScriptBlock {

        Invoke-WinUtilSSHServer

        Write-Host "======================================="
        Write-Host "--     OpenSSH Server installed!    ---"
        Write-Host "======================================="
    }
}
