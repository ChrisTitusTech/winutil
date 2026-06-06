BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Test-WinUtilIsServiceNotFoundException.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Get-WinUtilServiceStartupType.ps1')
    . (Join-Path $PSScriptRoot '..\functions\private\Set-WinUtilService.ps1')
}

Describe 'Set-WinUtilService' {
    It 'Skips Set-Service when startup type already matches' {
        $service = [PSCustomObject]@{
            Name = 'TestService'
            StartType = [System.ServiceProcess.ServiceStartMode]::Manual
        }

        Mock Get-Service { $service }
        Mock Set-Service { }

        Set-WinUtilService -Name 'TestService' -StartupType 'Manual'

        Should -Invoke Set-Service -Times 0
    }

    It 'Calls Set-Service when startup type differs' {
        $service = [PSCustomObject]@{
            Name = 'TestService'
            StartType = [System.ServiceProcess.ServiceStartMode]::Automatic
        }

        Mock Get-Service { $service }
        Mock Get-ItemProperty { throw 'not found' }
        Mock Set-Service { }

        Set-WinUtilService -Name 'TestService' -StartupType 'Manual'

        Should -Invoke Set-Service -Times 1
    }

    It 'Skips delayed-auto service when registry reports delayed start' {
        $service = [PSCustomObject]@{
            Name = 'TestService'
            StartType = [System.ServiceProcess.ServiceStartMode]::Automatic
        }

        Mock Get-Service { $service }
        Mock Get-ItemProperty { [PSCustomObject]@{ DelayedAutoStart = 1 } }
        Mock Set-Service { }

        Set-WinUtilService -Name 'TestService' -StartupType 'AutomaticDelayedStart'

        Should -Invoke Set-Service -Times 0
    }

    It 'Writes warning when service is not found' {
        Mock Get-Service { throw (New-Object System.Exception 'Cannot find any service with service name MissingService.') }
        Mock Write-Warning { } -ParameterFilter { $Message -like '*was not found*' }

        Set-WinUtilService -Name 'MissingService' -StartupType 'Manual'

        Should -Invoke Write-Warning -ParameterFilter { $Message -like '*was not found*' }
    }
}