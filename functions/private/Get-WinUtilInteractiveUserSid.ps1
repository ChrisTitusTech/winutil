function Get-WinUtilInteractiveUserSid {
    <#

    .SYNOPSIS
        Returns the SID of the currently logged-in interactive (console) user.

    .DESCRIPTION
        When WinUtil is elevated with a different account than the logged-in user (over-the-shoulder UAC),
        this resolves the SID of the interactive user so HKCU tweaks can target the correct hive.
        Prefers the console user reported by Win32_ComputerSystem; falls back to the owner of explorer.exe
        only when a single interactive shell is present, to avoid guessing on multi-session hosts.
        Returns $null when no interactive user can be unambiguously determined. The result is cached only
        once a real SID is found, so a transient detection failure is retried on the next call.

    #>

    if ($script:WinUtilInteractiveUserSidResolved) {
        return $script:WinUtilInteractiveUserSid
    }

    $sid = $null

    try {
        $userName = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
        if ($userName) {
            $sid = ([System.Security.Principal.NTAccount]$userName).Translate([System.Security.Principal.SecurityIdentifier]).Value
        }
    } catch {
        $sid = $null
    }

    if (-not $sid) {
        try {
            $distinct = @(Get-WinUtilExplorerOwner | Select-Object -ExpandProperty Sid -Unique)
            if ($distinct.Count -eq 1) {
                $sid = $distinct[0]
            }
        } catch {
            $sid = $null
        }
    }

    if ($sid) {
        $script:WinUtilInteractiveUserSid = $sid
        $script:WinUtilInteractiveUserSidResolved = $true
    }
    return $sid
}
