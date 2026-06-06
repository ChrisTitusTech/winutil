BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilRegistryValueMatch.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Set-WinUtilRegistry.ps1')
}

Describe 'Set-WinUtilRegistry' {
    BeforeEach {
        Mock Test-Path { $true }
        Mock New-PSDrive { }
        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock Remove-ItemProperty { }
    }

    It 'Skips Set-ItemProperty when DWord value already matches' {
        Mock Get-ItemProperty { [PSCustomObject]@{ TestName = 1 } }

        Set-WinUtilRegistry -Name 'TestName' -Path 'HKCU:\Test' -Type 'DWord' -Value '1'

        Should -Invoke Set-ItemProperty -Times 0
    }

    It 'Writes registry when DWord value differs' {
        Mock Get-ItemProperty { [PSCustomObject]@{ TestName = 0 } }

        Set-WinUtilRegistry -Name 'TestName' -Path 'HKCU:\Test' -Type 'DWord' -Value '1'

        Should -Invoke Set-ItemProperty -Times 1
    }

    It 'Skips remove when property is already absent' {
        Mock Get-ItemProperty { $null }

        Set-WinUtilRegistry -Name 'TestName' -Path 'HKCU:\Test' -Type 'DWord' -Value '<RemoveEntry>'

        Should -Invoke Remove-ItemProperty -Times 0
    }

    It 'Writes warning when Set-ItemProperty throws' {
        Mock Get-ItemProperty { [PSCustomObject]@{ TestName = 0 } }
        Mock Set-ItemProperty { throw 'access denied' }
        Mock Write-Warning { } -ParameterFilter { $Message -like '*access denied*' }

        Set-WinUtilRegistry -Name 'TestName' -Path 'HKCU:\Test' -Type 'DWord' -Value '1'

        Should -Invoke Write-Warning -ParameterFilter { $Message -like '*access denied*' }
    }
}