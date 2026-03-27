function Invoke-WinUtilSSHServer {
    <#
    .SYNOPSIS
        Enables OpenSSH server to remote into your windows device
    #>

    # Install the OpenSSH Server feature if not already installed
    if ((Get-WindowsCapability -Name OpenSSH.Server -Online).State -ne "Installed") {
        Write-Host "Enabling OpenSSH Server... This will take a long time"
        Add-WindowsCapability -Name OpenSSH.Server -Online
    }

    Write-Host "Starting the services"

    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd

    Set-Service -Name ssh-agent -StartupType Automatic
    Start-Service -Name ssh-agent

    #Adding Firewall rule for port 22
    Write-Host "Setting up firewall rules"
    if (-not ((Get-NetFirewallRule -Name 'sshd').Enabled)) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "Firewall rule for OpenSSH Server created and enabled."
    }

    # Check for the authorized_keys file
    $sshFolderPath = "$Home\.ssh"
    $authorizedKeysPath = "$sshFolderPath\authorized_keys"

    if (-not (Test-Path -Path $sshFolderPath)) {
        Write-Host "Creating ssh directory..."
        New-Item -Path $sshFolderPath -ItemType Directory -Force
    }

    if (-not (Test-Path -Path $authorizedKeysPath)) {
        Write-Host "Creating authorized_keys file..."
        New-Item -Path $authorizedKeysPath -ItemType File -Force
        Write-Host "authorized_keys file created at $authorizedKeysPath."
    }

    Write-Host "Configuring sshd_config for standard authorized_keys behavior..."
    $sshdConfigPath = "C:\ProgramData\ssh\sshd_config"

    $configContent = Get-Content -Path $sshdConfigPath -Raw

    $updatedContent = $configContent -replace '(?m)^(Match Group administrators)$', '# $1'
    $updatedContent = $updatedContent -replace '(?m)^(\s+AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys)$', '# $1'

    if ($updatedContent -ne $configContent) {
        Set-Content -Path $sshdConfigPath -Value $updatedContent -Force
        Write-Host "Commented out administrator-specific SSH key configuration in sshd_config"
        Restart-Service -Name sshd -Force
    }

    Write-Host "OpenSSH server was successfully enabled."
    Write-Host "The config file can be located at C:\ProgramData\ssh\sshd_config"
    Write-Host "Add your public keys to this file -> $authorizedKeysPath"
}
