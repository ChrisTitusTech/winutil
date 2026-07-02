#===========================================================================
# Tests - Toggle status checks
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilToggleStatus.ps1")
}

Describe "Get-WinUtilToggleStatus" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                tweaks = [pscustomobject]@{
                    WPFToggleExample = [pscustomobject]@{
                        registry = @(
                            [pscustomobject]@{
                                Path = "HKCU:\Software\WinUtilToggle"
                                Name = "Enabled"
                                Value = "1"
                                OriginalValue = "0"
                                DefaultState = "true"
                            }
                        )
                    }
                    WPFToggleDisabledByDefault = [pscustomobject]@{
                        registry = @(
                            [pscustomobject]@{
                                Path = "HKCU:\Software\WinUtilToggle"
                                Name = "Enabled"
                                Value = "1"
                                OriginalValue = "0"
                                DefaultState = "false"
                            }
                        )
                    }
                }
            }
        })

        Mock Get-PSDrive { [pscustomobject]@{ Name = "HKU" } } -ParameterFilter { $Name -eq "HKU" }
        Mock New-PSDrive { }
        Mock New-Item { }
        Mock Test-Path { $false }
        Mock Get-ItemProperty { [pscustomobject]@{ Enabled = "1" } }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "does not create missing registry paths while reading toggle state" {
        Get-WinUtilToggleStatus "WPFToggleExample" | Should -BeTrue

        Should -Invoke -CommandName Test-Path -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\Software\WinUtilToggle"
        }
        Should -Invoke -CommandName New-Item -Times 0 -Exactly
        Should -Invoke -CommandName Get-ItemProperty -Times 0 -Exactly
    }

    It "uses configured false default when the registry path is missing" {
        Get-WinUtilToggleStatus "WPFToggleDisabledByDefault" | Should -BeFalse

        Should -Invoke -CommandName New-Item -Times 0 -Exactly
    }

    It "caches toggle results for repeated checks" {
        Mock Test-Path { $true } -ParameterFilter { $Path -eq "HKCU:\Software\WinUtilToggle" }
        Mock Get-ItemProperty { [pscustomobject]@{ Enabled = "1" } } -ParameterFilter {
            $Path -eq "HKCU:\Software\WinUtilToggle"
        }

        Get-WinUtilToggleStatus "WPFToggleExample" | Should -BeTrue
        Get-WinUtilToggleStatus "WPFToggleExample" | Should -BeTrue

        Should -Invoke -CommandName Test-Path -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\Software\WinUtilToggle"
        }
        Should -Invoke -CommandName Get-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\Software\WinUtilToggle"
        }
    }
}
