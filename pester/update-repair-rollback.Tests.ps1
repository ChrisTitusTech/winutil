BeforeAll {
    . (Join-Path $PSScriptRoot '../functions/public/Invoke-WPFFixesUpdate.ps1')
    . (Join-Path $PSScriptRoot '../functions/private/Step-WinUtilJob.ps1')
}

Describe 'Windows Update service-stop rollback' {
    It 'restarts only services this run stopped before a later failure' {
        Mock Step-WinUtilJob {}
        Mock Start-Sleep {}
        Mock Write-Progress {}
        Mock Get-Service {
            param($Name)
            [pscustomobject]@{ Status = if ($Name -eq 'wuauserv') { 'Stopped' } else { 'Running' } }
        }
        Mock Stop-Service {
            param($Name)
            if ($Name -eq 'appidsvc') { throw 'stop denied' }
        }
        Mock Start-Service {}

        { Invoke-WPFFixesUpdate } | Should -Throw '*appidsvc*stop denied*'
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'BITS' }
        Should -Invoke Start-Service -Times 1 -Exactly
        Should -Invoke Stop-Service -Times 0 -ParameterFilter { $Name -eq 'cryptsvc' }
    }
}
