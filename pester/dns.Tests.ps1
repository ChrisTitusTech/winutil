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
            [switch]$ResetServerAddresses,
            $ErrorAction
        )
    }
    function netsh {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }

    function Add-DnsClientDohServerAddress {
        param($ServerAddress, $DohTemplate, $AllowFallbackToUdp, $AutoUpgrade, $ErrorAction)
    }
    function Set-DnsClientDohServerAddress {
        param($ServerAddress, $DohTemplate, $AllowFallbackToUdp, $AutoUpgrade, $ErrorAction)
    }
    function Get-DnsClientDohServerAddress {
        param($ServerAddress, $ErrorAction)
    }
    function Remove-DnsClientDohServerAddress {
        param($ServerAddress, $Confirm, $ErrorAction)
    }
    function Clear-DnsClientCache { }

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
                        DohTemplate = "https://cloudflare-dns.com/dns-query"
                    }
                    Mullvad = [pscustomobject]@{
                        Primary = "194.242.2.2"
                        Secondary = "194.242.2.3"
                        Primary6 = "2a07:e340::2"
                        Secondary6 = "2a07:e340::3"
                        DohOnly = $true
                        DohTemplate = "https://dns.mullvad.net/dns-query"
                        SecondaryDohTemplate = "https://adblock.dns.mullvad.net/dns-query"
                    }
                    MullvadNoSecondary = [pscustomobject]@{
                        Primary = "194.242.2.2"
                        Secondary = ""
                        Primary6 = "2a07:e340::2"
                        Secondary6 = ""
                        DohOnly = $true
                        DohTemplate = "https://dns.mullvad.net/dns-query"
                    }
                }
            }
        })

        Mock Get-NetAdapter {
            [pscustomobject]@{
                Name = "Ethernet"
                Status = "Up"
                ifIndex = 7
                InterfaceGuid = "{1234-5678-90AB-CDEF}"
            }
        }
        Mock Set-DnsClientServerAddress { }
        Mock netsh { }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
        Mock Write-Host { }

        Mock Get-Command { return $true } -ParameterFilter { $Name -eq "Add-DnsClientDohServerAddress" }
        Mock Add-DnsClientDohServerAddress { }
        Mock Set-DnsClientDohServerAddress { }
        Mock Get-DnsClientDohServerAddress { return $null }
        Mock Remove-DnsClientDohServerAddress { }
        Mock Test-Path { return $false }
        Mock Get-ChildItem { }
        Mock New-Item { }
        Mock New-ItemProperty { }
        Mock Remove-Item { }
        Mock Clear-DnsClientCache { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "sets IPv4 and IPv6 DNS server addresses separately and applies DoH templates" {
        $result = Set-WinUtilDNS -DNSProvider "Cloudflare"

        $result | Should -BeTrue
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
        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 4 -Exactly
        Should -Invoke -CommandName New-ItemProperty -Times 4 -ParameterFilter {
            $Name -eq "DohFlags" -and $Value -eq 1
        }
        Should -Invoke -CommandName Clear-DnsClientCache -Times 1 -Exactly
    }

    It "updates an existing DoH entry with the selected provider settings" {
        Mock Get-DnsClientDohServerAddress {
            if ($ServerAddress -eq "1.1.1.1") {
                return [pscustomobject]@{ ServerAddress = $ServerAddress }
            }
            return $null
        }

        Set-WinUtilDNS -DNSProvider "Cloudflare"

        Should -Invoke -CommandName Set-DnsClientDohServerAddress -Times 1 -Exactly -ParameterFilter {
            $ServerAddress -eq "1.1.1.1" -and
                $DohTemplate -eq "https://cloudflare-dns.com/dns-query" -and
                $AllowFallbackToUdp -eq $false -and
                $AutoUpgrade -eq $true
        }
        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 3 -Exactly
    }

    It "filters empty DNS server addresses" {
        Set-WinUtilDNS -DNSProvider "MullvadNoSecondary"

        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
            $InterfaceIndex -eq 7 -and
                $ServerAddresses.Count -eq 1 -and
                $ServerAddresses[0] -eq "194.242.2.2"
        }
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
            $InterfaceIndex -eq 7 -and
                $ServerAddresses.Count -eq 1 -and
                $ServerAddresses[0] -eq "2a07:e340::2"
        }
        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 2 -Exactly
    }

    It "applies the matching DoH template to secondary resolvers" {
        Set-WinUtilDNS -DNSProvider "Mullvad"

        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 2 -Exactly -ParameterFilter {
            $ServerAddress -in @("194.242.2.2", "2a07:e340::2") -and
                $DohTemplate -eq "https://dns.mullvad.net/dns-query"
        }
        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 2 -Exactly -ParameterFilter {
            $ServerAddress -in @("194.242.2.3", "2a07:e340::3") -and
                $DohTemplate -eq "https://adblock.dns.mullvad.net/dns-query"
        }
    }

    It "does not apply a DoH-only provider when DoH is unsupported" {
        Mock Get-Command { return $null } -ParameterFilter { $Name -eq "Add-DnsClientDohServerAddress" }

        $result = Set-WinUtilDNS -DNSProvider "Mullvad"

        $result | Should -BeFalse
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 0 -Exactly
        Should -Invoke -CommandName Add-DnsClientDohServerAddress -Times 0 -Exactly
        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "DNS provider Mullvad requires DNS over HTTPS, which is not supported on this system."
        }
    }

    It "does not change adapter DNS when DoH registration fails" {
        Mock Add-DnsClientDohServerAddress { throw "DoH registration failed" }

        $result = Set-WinUtilDNS -DNSProvider "Mullvad"

        $result | Should -BeFalse
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 0 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "DNS" -and
                $Message -like "DNS provider Mullvad was not completed: *"
        }
    }

    It "falls back to plain DNS when optional DoH registration fails" {
        Mock Add-DnsClientDohServerAddress { throw "DoH registration failed" }

        $result = Set-WinUtilDNS -DNSProvider "Cloudflare"

        $result | Should -BeTrue
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 2 -Exactly
        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "DNS over HTTPS setup for provider Cloudflare failed; continuing with plain DNS."
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and
                $Component -eq "DNS" -and
                $Message -like "DNS over HTTPS setup for provider Cloudflare failed; continuing with plain DNS: *"
        }
    }

    It "resets DNS to DHCP and removes the applied DoH configuration" {
        Mock Test-Path { return $true } -ParameterFilter { $Path -like "*DohInterfaceSettings*" }
        Mock Get-ChildItem {
            if ($Path -like "*\Doh6") {
                return @(
                    [pscustomobject]@{ PSChildName = "2606:4700:4700::1111" }
                    [pscustomobject]@{ PSChildName = "2606:4700:4700::1001" }
                )
            }

            return @(
                [pscustomobject]@{ PSChildName = "1.1.1.1" }
                [pscustomobject]@{ PSChildName = "1.0.0.1" }
            )
        }
        Mock Get-DnsClientDohServerAddress {
            [pscustomobject]@{ ServerAddress = $ServerAddress }
        }
        
        Set-WinUtilDNS -DNSProvider "DHCP"

        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
            $InterfaceIndex -eq 7 -and
                $ResetServerAddresses -eq $true
        }
        Should -Invoke -CommandName netsh -Times 1 -Exactly -ParameterFilter {
            $Arguments[0] -eq "interface" -and
                $Arguments[1] -eq "ip" -and
                $Arguments[2] -eq "set" -and
                $Arguments[3] -eq "dnsservers" -and
                $Arguments[4] -eq "name=Ethernet" -and
                $Arguments[5] -eq "source=dhcp"
        }
        Should -Invoke -CommandName netsh -Times 1 -Exactly -ParameterFilter {
            $Arguments[0] -eq "interface" -and
                $Arguments[1] -eq "ipv6" -and
                $Arguments[2] -eq "set" -and
                $Arguments[3] -eq "dnsservers" -and
                $Arguments[4] -eq "name=Ethernet" -and
                $Arguments[5] -eq "source=dhcp"
        }
        Should -Invoke -CommandName Remove-Item -Times 1 -Exactly -ParameterFilter {
            $Path -like "*DohInterfaceSettings*" -and $Recurse -eq $true -and $Force -eq $true
        }
        Should -Invoke -CommandName Remove-DnsClientDohServerAddress -Times 4 -Exactly
    }

    It "catches non-terminating DNS setter failures so the tweak runspace can continue" {
        Mock Set-DnsClientServerAddress { Write-Error "DNS failed" -ErrorAction $ErrorAction }

        $result = Set-WinUtilDNS -DNSProvider "Cloudflare"

        $result | Should -BeFalse
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "DNS" -and
                $Message -like "DNS provider Cloudflare was not completed: *"
        }
    }

    It "returns failure for an unknown DNS provider" {
        $result = Set-WinUtilDNS -DNSProvider "Unknown"

        $result | Should -BeFalse
        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 0 -Exactly
    }
}
