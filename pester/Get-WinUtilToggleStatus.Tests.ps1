BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilRegistryValueMatch.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Get-WinUtilToggleStatus.ps1')

    $global:sync = [Hashtable]::Synchronized(@{
        configs = @{
            tweaks = [PSCustomObject]@{
                TestToggle = [PSCustomObject]@{
                    registry = @(
                        [PSCustomObject]@{
                            Path = 'HKCU:\Test\Path'
                            Name = 'TestValue'
                            Value = '1'
                            OriginalValue = '<RemoveEntry>'
                            DefaultState = 'false'
                            Type = 'DWord'
                        }
                    )
                }
            }
        }
    })
}

Describe 'Get-WinUtilToggleStatus' {
    It 'Returns false when absent property uses RemoveEntry OriginalValue without throwing' {
        Mock Test-Path { $false }
        Mock Get-PSDrive { @{ Name = 'HKU' } }
        Mock New-PSDrive { }

        Get-WinUtilToggleStatus 'TestToggle' | Should -Be $false
    }

    It 'Returns true when registry state matches toggle Value' {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { [PSCustomObject]@{ TestValue = 1 } }
        Mock Get-PSDrive { @{ Name = 'HKU' } }
        Mock New-PSDrive { }

        Get-WinUtilToggleStatus 'TestToggle' | Should -Be $true
    }

    It 'Returns false when property is absent and effective value is null without coercing null to zero' {
        $global:sync.configs.tweaks = [PSCustomObject]@{
            TestToggleNull = [PSCustomObject]@{
                registry = @(
                    [PSCustomObject]@{
                        Path = 'HKCU:\Test\NullPath'
                        Name = 'NullValue'
                        Value = '0'
                        OriginalValue = $null
                        DefaultState = $null
                        Type = 'DWord'
                    }
                )
            }
        }

        Mock Test-Path { $false }
        Mock Get-PSDrive { @{ Name = 'HKU' } }
        Mock New-PSDrive { }

        Get-WinUtilToggleStatus 'TestToggleNull' | Should -Be $false
    }
}

Describe 'Test-WinUtilRegistryValueMatch table' -ForEach @(
    @{ Current = $null; Expected = '1'; Type = 'DWord'; Result = $false; Name = 'null current' }
    @{ Current = '<RemoveEntry>'; Expected = '1'; Type = 'DWord'; Result = $false; Name = 'remove entry current' }
    @{ Current = '0'; Expected = '<RemoveEntry>'; Type = 'DWord'; Result = $false; Name = 'remove entry expected absent' }
    @{ Current = $null; Expected = '<RemoveEntry>'; Type = 'DWord'; Result = $true; Name = 'remove entry expected null' }
    @{ Current = '1'; Expected = '1'; Type = 'DWord'; Result = $true; Name = 'dword match' }
    @{ Current = '0x10'; Expected = '16'; Type = 'DWord'; Result = $true; Name = 'hex dword match' }
    @{ Current = 'enabled'; Expected = 'enabled'; Type = 'String'; Result = $true; Name = 'string match' }
) {
    It 'Compares <Name> correctly' {
        Test-WinUtilRegistryValueMatch -CurrentValue $Current -ExpectedValue $Expected -Type $Type | Should -Be $Result
    }
}