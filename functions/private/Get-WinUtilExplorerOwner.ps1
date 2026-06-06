function Get-WinUtilExplorerOwner {
    <#

    .SYNOPSIS
        Lists each running explorer.exe process paired with the SID of its owning user.

    .DESCRIPTION
        Enumerates explorer.exe via CIM and resolves each process owner to a SID, emitting one
        object ({ ProcessId, Sid }) per process whose owner resolves. Used to identify the interactive
        user's shell (Get-WinUtilInteractiveUserSid) and to restart only that user's Explorer
        (Restart-WinUtilExplorer). A CIM enumeration failure is allowed to propagate so callers can
        fall back; processes whose owner cannot be resolved are skipped.

    #>

    $explorers = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" -ErrorAction Stop
    foreach ($proc in $explorers) {
        $owner = Invoke-CimMethod -InputObject $proc -MethodName GetOwner -ErrorAction SilentlyContinue
        if ($owner -and $owner.ReturnValue -eq 0 -and $owner.User) {
            $account = if ($owner.Domain) { "$($owner.Domain)\$($owner.User)" } else { $owner.User }
            try {
                $sid = ([System.Security.Principal.NTAccount]$account).Translate([System.Security.Principal.SecurityIdentifier]).Value
            } catch {
                continue
            }
            [PSCustomObject]@{
                ProcessId = $proc.ProcessId
                Sid       = $sid
            }
        }
    }
}
