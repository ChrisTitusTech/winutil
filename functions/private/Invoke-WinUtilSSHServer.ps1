function Invoke-WinUtilSSHServer {
    <#
    .SYNOPSIS
        Enables OpenSSH server to remote into your windows device
    #>

    # Install the OpenSSH Server feature if not already installed
    if ((Get-WindowsCapability -Name OpenSSH.Server -Online).State -ne "Installed") {
        Write-Host "Enabling OpenSSH Server... This will take a long time."
        Add-WindowsCapability -Name OpenSSH.Server -Online
    }

    # An SSH logon for a member of the administrators group gets a full token
    # with no UAC prompt, so sshd reads administrator keys from a machine-wide
    # file that only Administrators and SYSTEM may write. WinUtil always runs
    # elevated, so the account being set up here is always an administrator.
    $sshProgramDataPath = Join-Path $env:ProgramData "ssh"
    $sshdConfigPath = Join-Path $sshProgramDataPath "sshd_config"
    $authorizedKeysPath = Join-Path $sshProgramDataPath "administrators_authorized_keys"
    $profileKeysPath = Join-Path $env:USERPROFILE ".ssh\authorized_keys"

    if (-not (Test-Path -Path $sshProgramDataPath)) {
        New-Item -Path $sshProgramDataPath -ItemType Directory -Force | Out-Null
    }

    # Refuse to adopt pre-existing sshd_config / administrators_authorized_keys that are not
    # owned by SYSTEM, Administrators, or the current (elevated) user: a low-privilege local
    # user could otherwise plant keys or settings that this feature later activates. This must
    # run before the service and firewall side effects below, so a planted config is never
    # consumed by a starting sshd.
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    foreach ($existingPath in @($sshdConfigPath, $authorizedKeysPath)) {
        if (-not (Test-Path -LiteralPath $existingPath)) { continue }

        $owner = (Get-Acl -LiteralPath $existingPath).Owner
        $ownerSid = $null
        try { $ownerSid = [System.Security.Principal.SecurityIdentifier]::new($owner) } catch { }
        if (-not $ownerSid) {
            try { $ownerSid = (New-Object System.Security.Principal.NTAccount($owner)).Translate([System.Security.Principal.SecurityIdentifier]) } catch { }
        }
        if (-not $ownerSid) {
            throw "Refusing to adopt pre-existing $existingPath (owner: $owner). The owner could not be resolved."
        }
        $isAdminOwner = $ownerSid.Value -in @("S-1-5-32-544", "S-1-5-18") -or $ownerSid.Value -eq $currentUserSid
        if (-not $isAdminOwner -and (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue)) {
            # A second administrator may legitimately own the file. Accept owners that are
            # members of the local Administrators group when the cmdlet is available.
            # Resolve the built-in group by SID so localized Windows installs work too.
            $adminGroupName = (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")).Translate([System.Security.Principal.NTAccount]).Value
            $adminMemberSids = @(Get-LocalGroupMember -Group $adminGroupName -ErrorAction SilentlyContinue | ForEach-Object {
                try { (New-Object System.Security.Principal.NTAccount($_.Name)).Translate([System.Security.Principal.SecurityIdentifier]).Value } catch { $_.Name }
            })
            if ($adminMemberSids -contains $ownerSid.Value) { $isAdminOwner = $true }
        }
        if (-not $ownerSid -or -not $isAdminOwner) {
            throw "Refusing to adopt pre-existing $existingPath (owner: $owner). It must be owned by Administrators or SYSTEM before WinUtil enables OpenSSH Server."
        }
    }

    Write-Host "Starting the services"

    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd

    Set-Service -Name ssh-agent -StartupType Automatic
    Start-Service -Name ssh-agent

    #Adding Firewall rule for port 22
    Write-Host "Setting up firewall rules"
    $firewallRule = Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue
    if ($null -eq $firewallRule) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "Firewall rule for OpenSSH Server created and enabled."
    } elseif ([int]$firewallRule.Enabled -eq 2) {
        Set-NetFirewallRule -Name 'sshd' -Enabled True
        Write-Host "Firewall rule for OpenSSH Server enabled."
    }

    # Earlier WinUtil versions commented out the administrators block in
    # sshd_config. Detect that state before restoring it, so administrator keys
    # already in use are carried over instead of silently stopping working.
    $configContent = if (Test-Path -Path $sshdConfigPath) { [string](Get-Content -Path $sshdConfigPath -Raw) } else { "" }
    $restoredContent = $configContent -replace '(?m)^# (Match Group administrators)$', '$1'
    $restoredContent = $restoredContent -replace '(?m)^# (\s+AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys)$', '$1'
    $configWasOverridden = $restoredContent -ne $configContent

    if (-not (Test-Path -Path $authorizedKeysPath)) {
        Write-Host "Creating administrators_authorized_keys file..."
        New-Item -Path $authorizedKeysPath -ItemType File -Force | Out-Null
        Write-Host "administrators_authorized_keys file created at $authorizedKeysPath."
    }

    if ($configWasOverridden -and (Test-Path -Path $profileKeysPath)) {
        $currentKeys = @(Get-Content -Path $authorizedKeysPath)
        $keysToMove = @(Get-Content -Path $profileKeysPath | Where-Object {
            $_.Trim() -and -not $_.TrimStart().StartsWith("#") -and $currentKeys -notcontains $_
        })

        if ($keysToMove.Count -gt 0) {
            Add-Content -Path $authorizedKeysPath -Value $keysToMove
            Write-Host "Moved $($keysToMove.Count) key(s) from $profileKeysPath to $authorizedKeysPath."
        }
    }

    # sshd ignores the file unless inheritance is off and access is limited to
    # Administrators (S-1-5-32-544) and SYSTEM (S-1-5-18). SIDs keep this
    # working on localized installs, where the group names differ.
    $acl = Get-Acl -Path $authorizedKeysPath
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) {
        [void]$acl.RemoveAccessRule($rule)
    }
    foreach ($sid in @("S-1-5-32-544", "S-1-5-18")) {
        [void]$acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new(
            [System.Security.Principal.SecurityIdentifier]::new($sid), "FullControl", "Allow"))
    }
    Set-Acl -Path $authorizedKeysPath -AclObject $acl

    if ($configWasOverridden) {
        Set-Content -Path $sshdConfigPath -Value $restoredContent -Force
        Write-Host "Restored the administrator key file setting in sshd_config."
        Restart-Service -Name sshd -Force
    }

    Write-Host "OpenSSH server was successfully enabled."
    Write-Host "The config file can be located at $sshdConfigPath"
    Write-Host "Add your public keys to this file -> $authorizedKeysPath"
}
