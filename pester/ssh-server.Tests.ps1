#===========================================================================
# Tests - OpenSSH Server Setup
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    function Get-WindowsCapability {
        param($Name, [switch]$Online)
        [pscustomobject]@{ State = "Installed" }
    }
    function Add-WindowsCapability {
        param($Name, [switch]$Online)
    }
    function Get-NetFirewallRule {
        param($Name)
        [pscustomobject]@{ Enabled = $true }
    }
    function New-NetFirewallRule {
        param($Name, $DisplayName, $Enabled, $Direction, $Protocol, $Action, $LocalPort)
    }
    function Set-Service {
        param($Name, $StartupType)
    }
    function Start-Service {
        param($Name)
    }
    function Restart-Service {
        param($Name, [switch]$Force)
    }

    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilSSHServer.ps1")

    $script:defaultAdministratorsBlock = "Match Group administrators`n       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`n"
    $script:overriddenAdministratorsBlock = "# Match Group administrators`n#        AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`n"

    function script:New-SshdConfig {
        param([string]$AdministratorsBlock)

        $content = "# Default sshd_config`nPort 22`n`n$AdministratorsBlock"
        Set-Content -Path $script:sshdConfigPath -Value $content -NoNewline
        return $content
    }

    function script:Set-ProfileKeyFile {
        param([string[]]$Keys)

        New-Item -Path (Split-Path $script:profileKeysPath) -ItemType Directory -Force | Out-Null
        Set-Content -Path $script:profileKeysPath -Value $Keys
    }

    function script:Get-ExplicitKeyFileAccess {
        $acl = Get-Acl -Path $script:authorizedKeysPath
        @($acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])) |
            ForEach-Object { $_.IdentityReference.Value }
    }

    function script:Get-AuthorizedKeyFileContent {
        # The key file ends up readable only by Administrators and SYSTEM, so an
        # unelevated run has to grant itself read access back through its
        # ownership of the file before it can check the contents.
        $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        icacls $script:authorizedKeysPath /grant "*${currentUserSid}:(R)" | Out-Null

        @(Get-Content -Path $script:authorizedKeysPath)
    }
}

Describe "Invoke-WinUtilSSHServer" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-ssh-$([guid]::NewGuid())"
        $script:programData = Join-Path $script:testRoot "ProgramData"
        $script:userProfile = Join-Path $script:testRoot "Users\tester"
        New-Item -Path (Join-Path $script:programData "ssh") -ItemType Directory -Force | Out-Null
        New-Item -Path $script:userProfile -ItemType Directory -Force | Out-Null

        $script:sshdConfigPath = Join-Path $script:programData "ssh\sshd_config"
        $script:authorizedKeysPath = Join-Path $script:programData "ssh\administrators_authorized_keys"
        $script:profileKeysPath = Join-Path $script:userProfile ".ssh\authorized_keys"

        $script:savedProgramData = $env:ProgramData
        $script:savedUserProfile = $env:USERPROFILE
        $env:ProgramData = $script:programData
        $env:USERPROFILE = $script:userProfile

        Mock Write-Host { }
        Mock Restart-Service { }
    }

    AfterEach {
        $env:ProgramData = $script:savedProgramData
        $env:USERPROFILE = $script:savedUserProfile
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "leaves the administrators block in a default sshd_config alone" {
        $original = New-SshdConfig -AdministratorsBlock $script:defaultAdministratorsBlock

        Invoke-WinUtilSSHServer

        Get-Content -Path $script:sshdConfigPath -Raw | Should -BeExactly $original
        Should -Invoke -CommandName Restart-Service -Times 0 -Exactly
    }

    It "leaves an sshd_config without an administrators block alone" {
        $original = New-SshdConfig -AdministratorsBlock ""
        Set-ProfileKeyFile -Keys @("ssh-ed25519 AAAAnotanadminkey laptop")

        Invoke-WinUtilSSHServer

        Get-Content -Path $script:sshdConfigPath -Raw | Should -BeExactly $original
        Get-AuthorizedKeyFileContent | Should -Not -Contain "ssh-ed25519 AAAAnotanadminkey laptop"
        Should -Invoke -CommandName Restart-Service -Times 0 -Exactly
    }

    It "creates administrators_authorized_keys limited to Administrators and SYSTEM" {
        New-SshdConfig -AdministratorsBlock $script:defaultAdministratorsBlock | Out-Null

        Invoke-WinUtilSSHServer

        Test-Path -Path $script:authorizedKeysPath | Should -BeTrue
        (Get-Acl -Path $script:authorizedKeysPath).AreAccessRulesProtected | Should -BeTrue

        $sids = Get-ExplicitKeyFileAccess
        $sids | Should -HaveCount 2
        $sids | Should -Contain "S-1-5-32-544"
        $sids | Should -Contain "S-1-5-18"
    }

    It "restores the administrators block when an earlier run commented it out" {
        New-SshdConfig -AdministratorsBlock $script:overriddenAdministratorsBlock | Out-Null

        Invoke-WinUtilSSHServer

        $config = Get-Content -Path $script:sshdConfigPath -Raw
        $config | Should -Match '(?m)^Match Group administrators$'
        $config | Should -Match '(?m)^\s+AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys$'
        Should -Invoke -CommandName Restart-Service -Times 1 -Exactly
    }

    It "moves profile keys into administrators_authorized_keys while restoring the block" {
        New-SshdConfig -AdministratorsBlock $script:overriddenAdministratorsBlock | Out-Null
        Set-ProfileKeyFile -Keys @("# my laptop", "", "ssh-ed25519 AAAAkeyone laptop", "ssh-ed25519 AAAAkeytwo desktop")

        Invoke-WinUtilSSHServer

        $keys = Get-AuthorizedKeyFileContent
        $keys | Should -Contain "ssh-ed25519 AAAAkeyone laptop"
        $keys | Should -Contain "ssh-ed25519 AAAAkeytwo desktop"
        $keys | Should -Not -Contain "# my laptop"
    }

    It "does not copy profile keys when sshd_config is already at its default" {
        New-SshdConfig -AdministratorsBlock $script:defaultAdministratorsBlock | Out-Null
        Set-ProfileKeyFile -Keys @("ssh-ed25519 AAAAnotanadminkey laptop")

        Invoke-WinUtilSSHServer

        Get-AuthorizedKeyFileContent | Should -Not -Contain "ssh-ed25519 AAAAnotanadminkey laptop"
    }

    It "keeps keys that are already in administrators_authorized_keys" {
        New-SshdConfig -AdministratorsBlock $script:overriddenAdministratorsBlock | Out-Null
        Set-Content -Path $script:authorizedKeysPath -Value "ssh-ed25519 AAAAexisting server"
        Set-ProfileKeyFile -Keys @("ssh-ed25519 AAAAexisting server", "ssh-ed25519 AAAAnew laptop")

        Invoke-WinUtilSSHServer

        $keys = @(Get-AuthorizedKeyFileContent | Where-Object { $_.Trim() })
        $keys | Should -HaveCount 2
        $keys | Should -Contain "ssh-ed25519 AAAAexisting server"
        $keys | Should -Contain "ssh-ed25519 AAAAnew laptop"
    }
}
