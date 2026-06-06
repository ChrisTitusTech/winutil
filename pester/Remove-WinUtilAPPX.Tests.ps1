BeforeAll {
    $global:sync = [Hashtable]::Synchronized(@{})
    . (Join-Path $PSScriptRoot '..\functions\private\Remove-WinUtilAPPX.ps1')
}

Describe 'Remove-WinUtilAPPX' {
    It 'Skips removal when no packages are found' {
        Mock Get-AppxPackage { @() }
        Mock Get-AppxProvisionedPackage { @() }
        Mock Remove-AppxPackage { }
        Mock Remove-AppxProvisionedPackage { }

        Remove-WinUtilAPPX -Name 'Contoso.App'

        Should -Invoke Remove-AppxPackage -Times 0
        Should -Invoke Remove-AppxProvisionedPackage -Times 0
    }

    It 'Uses cached provisioned packages across calls' {
        Mock Get-AppxPackage { @() }
        Mock Get-AppxProvisionedPackage { [PSCustomObject]@{ DisplayName = 'Contoso.App'; PackageName = 'Contoso.App_1.0' } }
        Mock Remove-AppxProvisionedPackage { }

        Remove-WinUtilAPPX -Name 'Contoso.App'
        Remove-WinUtilAPPX -Name 'Contoso.App'

        Should -Invoke Get-AppxProvisionedPackage -Times 1
    }

    It 'Clears provisioned cache after successful removal' {
        $global:sync.AppxProvisionedCache = @([PSCustomObject]@{ DisplayName = 'Contoso.App'; PackageName = 'Contoso.App_1.0' })
        Mock Get-AppxPackage { [PSCustomObject]@{ PackageFullName = 'Contoso.App_1.0' } }
        Mock Remove-AppxPackage { }
        Mock Remove-AppxProvisionedPackage { }

        Remove-WinUtilAPPX -Name 'Contoso.App'

        $global:sync.AppxProvisionedCache | Should -BeNullOrEmpty
    }

    It 'Writes warning when package removal fails' {
        Mock Get-AppxPackage { [PSCustomObject]@{ PackageFullName = 'Contoso.App_1.0' } }
        Mock Get-AppxProvisionedPackage { @() }
        Mock Remove-AppxPackage { throw 'remove failed' }
        Mock Write-Warning { } -ParameterFilter { $Message -like '*remove failed*' }

        Remove-WinUtilAPPX -Name 'Contoso.App'

        Should -Invoke Write-Warning -ParameterFilter { $Message -like '*remove failed*' }
    }
}