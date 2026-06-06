BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilIsServiceNotFoundException.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilRegistryValueMatch.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Get-WinUtilToggleStatus.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Get-WinUtilServiceStartupType.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Invoke-WinUtilCurrentSystem.ps1')

    $script:defaultTweaksConfig = [PSCustomObject]@{
        WPFToggleApplied = [PSCustomObject]@{
            Type = 'Toggle'
            registry = @(
                [PSCustomObject]@{
                    Path = 'HKCU:\Test'
                    Name = 'Value'
                    Value = '1'
                    OriginalValue = '0'
                    Type = 'DWord'
                }
            )
        }
        WPFTweaksApplied = [PSCustomObject]@{
            registry = @(
                [PSCustomObject]@{
                    Path = 'HKCU:\Test'
                    Name = 'Value'
                    Value = '1'
                    OriginalValue = '0'
                    Type = 'DWord'
                }
            )
        }
        WPFTweaksServiceApplied = [PSCustomObject]@{
            service = @(
                [PSCustomObject]@{
                    Name = 'TestService'
                    StartupType = 'Manual'
                }
            )
        }
    }

    $global:sync = [Hashtable]::Synchronized(@{
        configs = @{
            tweaks = $script:defaultTweaksConfig
        }
    })
}

Describe 'Invoke-WinUtilCurrentSystem' {
    BeforeEach {
        $global:sync.configs.tweaks = $script:defaultTweaksConfig
    }

    It 'Outputs toggle configs that are currently applied' {
        $global:sync.configs.tweaks = [PSCustomObject]@{
            WPFToggleApplied = $script:defaultTweaksConfig.WPFToggleApplied
            WPFTweaksApplied = $script:defaultTweaksConfig.WPFTweaksApplied
        }

        Mock Get-WinUtilToggleStatus { param($ToggleSwitch) $ToggleSwitch -eq 'WPFToggleApplied' }
        Mock Test-Path { $true }
        Mock Get-PSDrive { @{ Name = 'HKU' } }
        Mock New-PSDrive { }
        Mock Get-ItemProperty { [PSCustomObject]@{ Value = 1 } }

        $result = @(Invoke-WinUtilCurrentSystem -CheckBox 'tweaks')
        $result | Should -Contain 'WPFToggleApplied'
        $result | Should -Contain 'WPFTweaksApplied'
    }

    It 'Outputs service configs when startup type matches' {
        $global:sync.configs.tweaks = [PSCustomObject]@{
            WPFTweaksServiceApplied = $script:defaultTweaksConfig.WPFTweaksServiceApplied
        }

        Mock Get-Service -ParameterFilter { $Name -eq 'TestService' } {
            [PSCustomObject]@{ Name = 'TestService'; StartType = [System.ServiceProcess.ServiceStartMode]::Manual }
        }
        Mock Get-ItemProperty { throw 'not found' }

        $result = @(Invoke-WinUtilCurrentSystem -CheckBox 'tweaks')
        $result | Should -Contain 'WPFTweaksServiceApplied'
    }
}

Describe 'Invoke-WinUtilCurrentSystem registry matching' -ForEach @(
    @{ RegState = $null; DefaultState = 'false'; OriginalValue = '<RemoveEntry>'; Value = '1'; Type = 'DWord'; Matches = $false; Name = 'remove entry absent' }
    @{ RegState = 1; DefaultState = 'false'; OriginalValue = '0'; Value = '1'; Type = 'DWord'; Matches = $true; Name = 'dword applied' }
    @{ RegState = 'enabled'; DefaultState = $null; OriginalValue = 'disabled'; Value = 'enabled'; Type = 'String'; Matches = $true; Name = 'string applied' }
) {
    It 'Detects applied state for <Name>' {
        $effective = Resolve-WinUtilRegistryEffectiveValue `
            -CurrentValue $RegState `
            -DefaultState $DefaultState `
            -Value $Value `
            -OriginalValue $OriginalValue

        if ($null -eq $effective) {
            $result = $false
        } else {
            $result = Test-WinUtilRegistryValueMatch -CurrentValue $effective -ExpectedValue $Value -Type $Type
        }

        $result | Should -Be $Matches
    }
}