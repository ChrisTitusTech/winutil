function Invoke-WinUtilSSHServer {
    <#
    .SYNOPSIS
        Enables OpenSSH server to remote into your windows device
    #>

    # Get the latest version of OpenSSH Server
    $FeatureName = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" }

    # Install the OpenSSH Server feature if not already installed
    if ($FeatureName.State -ne "Installed") {
        Write-Host "Enabling OpenSSH Server"
        Add-WindowsCapability -Online -Name $FeatureName.Name
    }

    # Sets up the OpenSSH Server service
    Write-Host "Starting the services"
    Start-Service -Name sshd
    Set-Service -Name sshd -StartupType Automatic

    # Sets up the ssh-agent service
    Start-Service 'ssh-agent'
    Set-Service -Name 'ssh-agent' -StartupType 'Automatic'

    # Confirm the required services are running
    $SSHDaemonService = Get-Service -Name sshd
    $SSHAgentService = Get-Service -Name 'ssh-agent'

    if ($SSHDaemonService.Status -eq 'Running') {
        Write-Host "OpenSSH Server is running."
    } else {
        try {
            Write-Host "OpenSSH Server is not running. Attempting to restart..."
            Restart-Service -Name sshd -Force
            Write-Host "OpenSSH Server has been restarted successfully."
        } catch {
            Write-Host "Failed to restart OpenSSH Server: $_"
        }
    }
    if ($SSHAgentService.Status -eq 'Running') {
        Write-Host "ssh-agent is running."
    } else {
        try {
            Write-Host "ssh-agent is not running. Attempting to restart..."
            Restart-Service -Name sshd -Force
            Write-Host "ssh-agent has been restarted successfully."
        } catch {
            Write-Host "Failed to restart ssh-agent : $_"
        }
    }

    #Adding Firewall rule for port 22
    Write-Host "Setting up firewall rules"
    $firewallRule = (Get-NetFirewallRule -Name 'sshd').Enabled
    if ($firewallRule) {
        Write-Host "Firewall rule for OpenSSH Server (sshd) already exists."
    } else {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "Firewall rule for OpenSSH Server created and enabled."
    }

    # Check for the authorized_keys file
    $sshFolderPath = "$env:HOMEDRIVE\$env:HOMEPATH\.ssh"
    $authorizedKeysPath = "$sshFolderPath\authorized_keys"

    if (-not (Test-Path -Path $sshFolderPath)) {
        Write-Host "Creating ssh directory..."
        New-Item -Path $sshFolderPath -ItemType Directory -Force
    }

    if (-not (Test-Path -Path $authorizedKeysPath)) {
        Write-Host "Creating authorized_keys file..."
        New-Item -Path $authorizedKeysPath -ItemType File -Force
        Write-Host "authorized_keys file created at $authorizedKeysPath."
    } else {
        Write-Host "authorized_keys file already exists at $authorizedKeysPath."
    }
    Write-Host "OpenSSH server was successfully enabled."
    Write-Host "The config file can be located at C:\ProgramData\ssh\sshd_config "
    Write-Host "Add your public keys to this file -> $authorizedKeysPath"
}
