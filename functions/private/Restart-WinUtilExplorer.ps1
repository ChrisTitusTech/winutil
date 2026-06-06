function Restart-WinUtilExplorer {
    <#

    .SYNOPSIS
        Restarts Windows Explorer so shell changes apply without a re-login.

    .DESCRIPTION
        When WinUtil is elevated as a different account than the interactive (console) user, only that user's
        explorer.exe is stopped so Winlogon respawns the shell in their session; starting explorer from the
        elevated context would not produce a working shell. Otherwise the shell is restarted the usual way for
        the current session.

    #>

    $sid = Get-WinUtilInteractiveUserSid
    $currentSid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

    if ($sid -and $sid -ne $currentSid) {
        try {
            Get-WinUtilExplorerOwner | Where-Object { $_.Sid -eq $sid } | ForEach-Object {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
        } catch {
            taskkill.exe /F /IM "explorer.exe"
            Start-Process "explorer.exe"
        }
    } else {
        taskkill.exe /F /IM "explorer.exe"
        Start-Process "explorer.exe"
    }
}
