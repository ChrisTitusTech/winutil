function Get-WinUtilHKCURedirectPath {
    <#

    .SYNOPSIS
        Redirects a HKCU registry path to the interactive user's hive when WinUtil is elevated as a different account.

    .DESCRIPTION
        Returns the path unchanged unless all of the following hold: the path targets HKCU, the interactive user's
        SID is known and differs from the elevated process user, and that user's hive is loaded under HKEY_USERS.
        In that case the path is rewritten to the interactive user's hive so the tweak is applied to the logged-in user.
        Paths under Software\Classes are mapped to the user's separate classes hive (HKEY_USERS\<SID>_Classes).

    .PARAMETER Path
        The registry path to evaluate.

    #>

    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($Path -notmatch '^(HKCU:|HKEY_CURRENT_USER)\\') {
        return $Path
    }

    $sid = Get-WinUtilInteractiveUserSid
    if (-not $sid) {
        return $Path
    }

    if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value -eq $sid) {
        return $Path
    }

    $subPath = $Path -replace '^(HKCU:|HKEY_CURRENT_USER)\\', ''

    if ($subPath -match '^Software\\Classes\\(.*)$') {
        $classesHive = "Registry::HKEY_USERS\${sid}_Classes"
        if (Test-Path $classesHive) {
            return "$classesHive\$($matches[1])"
        }
        return $Path
    }

    $userHive = "Registry::HKEY_USERS\$sid"
    if (-not (Test-Path $userHive)) {
        return $Path
    }

    return "$userHive\$subPath"
}
