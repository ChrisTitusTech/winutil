BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilRemoteUrlAllowed.ps1')
}

Describe 'Test-WinUtilIpAddressBlocked' -ForEach @(
    @{ Address = '::1'; Blocked = $true; Name = 'IPv6 loopback' }
    @{ Address = '127.0.0.1'; Blocked = $true; Name = 'IPv4 loopback' }
    @{ Address = '::ffff:127.0.0.1'; Blocked = $true; Name = 'IPv4-mapped loopback' }
    @{ Address = 'fc00::1'; Blocked = $true; Name = 'ULA' }
    @{ Address = '8.8.8.8'; Blocked = $false; Name = 'public DNS' }
) {
    It 'Evaluates <Name>' {
        $ip = [System.Net.IPAddress]::Parse($Address)
        Test-WinUtilIpAddressBlocked -Address $ip | Should -Be $Blocked
    }
}

Describe 'Test-WinUtilRemoteUrlAllowed' {
    It 'Blocks literal IPv6 loopback hostnames' {
        Test-WinUtilRemoteUrlAllowed -Url 'http://[::1]/config.json' | Should -Be $false
    }
}