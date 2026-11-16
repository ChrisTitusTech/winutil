function Get-WinUtilAccountAuthorizationGroupSid {
    param([string]$UserSid)

    $context = $null
    $user = $null
    $groups = $null
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain)
        $user = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($context, [System.DirectoryServices.AccountManagement.IdentityType]::Sid, $UserSid)
        if ($null -eq $user) { return }
        # Authorization groups include transitive security-group memberships, unlike local-group enumeration.
        $groups = $user.GetAuthorizationGroups()
        foreach ($group in $groups) {
            try { $group.Sid.Value } finally { $group.Dispose() }
        }
    } catch {
        # Offline domain lookup or an unknown owner must fail closed in the SSH preflight.
        Write-Verbose "Could not resolve authorization groups for '$UserSid': $($_.Exception.Message)"
    } finally {
        if ($null -ne $groups) { $groups.Dispose() }
        if ($null -ne $user) { $user.Dispose() }
        if ($null -ne $context) { $context.Dispose() }
    }
}
