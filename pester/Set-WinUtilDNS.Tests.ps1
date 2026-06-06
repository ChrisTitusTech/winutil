BeforeAll {
    $global:sync = [Hashtable]::Synchronized(@{ configs = @{ dns = @{ Google = @{ Primary = '8.8.8.8'; Secondary = '8.8.4.4'; Primary6 = '2001:4860:4860::8888'; Secondary6 = '2001:4860:4860::8844' } } } })
    . (Join-Path $PSScriptRoot '..\functions\private\Set-WinUtilDNS.ps1')
}

Describe 'Test-WinUtilDnsAddressSetMatch' {
    It 'Treats address order as irrelevant' {
        Test-WinUtilDnsAddressSetMatch -Current @('8.8.4.4', '8.8.8.8') -Target @('8.8.8.8', '8.8.4.4') | Should -Be $true
    }

    It 'Detects different address sets' {
        Test-WinUtilDnsAddressSetMatch -Current @('1.1.1.1') -Target @('8.8.8.8') | Should -Be $false
    }
}

Describe 'Set-WinUtilDNS' {
    BeforeEach {
        Mock Get-NetAdapter {
            [PSCustomObject]@{
                Name = 'Ethernet'
                ifIndex = 1
                InterfaceGuid = '11111111-1111-1111-1111-111111111111'
                Status = 'Up'
            }
        }
        Mock Set-WinUtilDnsClientServerAddress { }
    }

    It 'Skips DHCP reset when adapter already uses DHCP DNS' {
        Mock Test-WinUtilAdapterDnsIsDhcp { $true }

        Set-WinUtilDNS -DNSProvider 'DHCP'

        Should -Invoke Set-WinUtilDnsClientServerAddress -Times 0
    }

    It 'Resets DNS when adapter has static servers configured' {
        Mock Test-WinUtilAdapterDnsIsDhcp { $false }

        Set-WinUtilDNS -DNSProvider 'DHCP'

        Should -Invoke Set-WinUtilDnsClientServerAddress -Times 2
    }

    It 'Skips static DNS writes when addresses already match' {
        Mock Get-DnsClientServerAddress {
            param($AddressFamily)
            if ($AddressFamily -eq 'IPv4') {
                return [PSCustomObject]@{ ServerAddresses = @('8.8.8.8', '8.8.4.4') }
            }
            return [PSCustomObject]@{ ServerAddresses = @('2001:4860:4860::8888', '2001:4860:4860::8844') }
        }

        Set-WinUtilDNS -DNSProvider 'Google'

        Should -Invoke Set-WinUtilDnsClientServerAddress -Times 0
    }

    It 'Writes warning message on unhandled exceptions' {
        Mock Get-NetAdapter { throw 'adapter failure' }
        Mock Write-Warning { } -ParameterFilter { $Message -like '*adapter failure*' }

        Set-WinUtilDNS -DNSProvider 'Google'

        Should -Invoke Write-Warning -ParameterFilter { $Message -like '*adapter failure*' }
    }
}