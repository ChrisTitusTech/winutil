BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Get-WinUtilServiceStartupType.ps1')
}

Describe 'Get-WinUtilServiceStartupType' {
    It 'Returns AutomaticDelayedStart when registry DelayedAutoStart is set' {
        $service = [PSCustomObject]@{
            Name = 'TestService'
            StartType = [System.ServiceProcess.ServiceStartMode]::Automatic
        }

        Mock Get-ItemProperty { [PSCustomObject]@{ DelayedAutoStart = 1 } }

        Get-WinUtilServiceStartupType -Service $service | Should -Be 'AutomaticDelayedStart'
    }

    It 'Returns Automatic when delayed start is not enabled' {
        $service = [PSCustomObject]@{
            Name = 'TestService'
            StartType = [System.ServiceProcess.ServiceStartMode]::Automatic
        }

        Mock Get-ItemProperty { throw 'not found' }

        Get-WinUtilServiceStartupType -Service $service | Should -Be 'Automatic'
    }
}