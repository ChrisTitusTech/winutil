#===========================================================================
# Tests - DNS
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    function Get-NetAdapter { }
    function Set-DnsClientServerAddress {
        param(
            $InterfaceIndex,
            $ServerAddresses,
            [switch]$ResetServerAddresses
        )
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }

    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilDNS.ps1")
}

Describe "Set-WinUtilDNS" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                dns = @{
                    Cloudflare = [pscustomobject]@{
                        Primary = "1.1.1.1"
                        Secondary = "1.0.0.1"
                        Primary6 = "2606:4700:4700::1111"
                        Secondary6 = "2606:4700:4700::1001"
                    }
                }
            }
        })

        Mock Get-NetAdapter {
            [pscustomobject]@{
                Name = "Ethernet"
                Status = "Up"
                ifIndex = 7
            }
        }
        Mock Set-DnsClientServerAddress { }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "sets IPv4 and IPv6 DNS server addresses separately" {
        Set-WinUtilDNS -DNSProvider "Cloudflare"

        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
            $InterfaceIndex -eq 7 -and
                $ServerAddresses.Count -eq 2 -and
                $ServerAddresses[0] -eq "1.1.1.1" -and
                $ServerAddresses[1] -eq "1.0.0.1"
        }
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
            $InterfaceIndex -eq 7 -and
                $ServerAddresses.Count -eq 2 -and
                $ServerAddresses[0] -eq "2606:4700:4700::1111" -and
                $ServerAddresses[1] -eq "2606:4700:4700::1001"
        }
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 0 -Exactly -ParameterFilter {
            $ServerAddresses.Count -eq 4
        }
    }

    It "catches DNS setter failures so the tweak runspace can continue" {
        Mock Set-DnsClientServerAddress { throw "DNS failed" }

        { Set-WinUtilDNS -DNSProvider "Cloudflare" } | Should -Not -Throw

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "DNS" -and
                $Message -like "Unable to set DNS provider Cloudflare*"
        }
    }
}
