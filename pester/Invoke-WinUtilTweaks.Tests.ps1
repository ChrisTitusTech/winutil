BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilRegistryValueMatch.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Set-WinUtilRegistry.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Invoke-WinUtilTweaks.ps1')

    $global:sync = [Hashtable]::Synchronized(@{
        configs = @{
            tweaks = [PSCustomObject]@{
                WPFTweaksTest = [PSCustomObject]@{
                    registry = @(
                        [PSCustomObject]@{
                            Path = 'HKCU:\Test'
                            Name = 'TestName'
                            Value = '1'
                            OriginalValue = '0'
                            Type = 'DWord'
                        }
                    )
                }
            }
        }
    })
}

Describe 'Invoke-WinUtilTweaks' {
    It 'Skips registry writes on second apply when value already matches' {
        Mock Test-Path { $true }
        Mock New-PSDrive { }
        Mock Get-ItemProperty { [PSCustomObject]@{ TestName = 0 } }
        Mock Set-ItemProperty { }

        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksTest'
        Mock Get-ItemProperty { [PSCustomObject]@{ TestName = 1 } }
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksTest'

        Should -Invoke Set-ItemProperty -Times 1
    }
}