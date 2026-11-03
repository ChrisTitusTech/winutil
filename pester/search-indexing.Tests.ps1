# Execute the configured scripts through the real tweak orchestrator. All service
# operations are mocked so these tests never change the machine's indexer.
BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilTweaks.ps1')
    $script:searchTweaks = Get-Content (Join-Path $repoRoot 'config/tweaks.json') -Raw | ConvertFrom-Json
    function Write-WinUtilLog { param($Level, $Component, $Message) }
    function Set-WinUtilService { param($Name, $StartupType) }
    function Invoke-WinUtilScript { param($Name, [scriptblock]$ScriptBlock) }
}

Describe 'Windows Search indexing apply and undo' {
    BeforeEach {
        $script:sync = @{ configs = @{ tweaks = $script:searchTweaks } }
        $script:searchService = [pscustomobject]@{ StartType = 'Automatic'; Status = 'Running' }
        Mock Get-Service { $script:searchService } -ParameterFilter { $Name -eq 'WSearch' }
        Mock Set-WinUtilService { $script:searchService.StartType = $StartupType }
        Mock Invoke-WinUtilScript { & $ScriptBlock }
        Mock Stop-Service { $script:searchService.Status = 'Stopped' }
        Mock Start-Service { $script:searchService.Status = 'Running' }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
    }

    AfterEach {
        Remove-Variable sync -Scope Script -ErrorAction SilentlyContinue
    }

    It 'disables and stops an automatic indexer, then restores and starts it' {
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing'
        $script:searchService.StartType | Should -Be 'Disabled'
        $script:searchService.Status | Should -Be 'Stopped'
        Should -Invoke Stop-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'WSearch' -and $ErrorAction -eq 'Stop' }

        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing' -undo $true
        $script:searchService.StartType | Should -Be 'Automatic'
        $script:searchService.Status | Should -Be 'Running'
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'WSearch' -and $ErrorAction -eq 'Stop' }
    }

    It 'preserves a Manual service and its <Status> state on apply and undo' -TestCases @(
        @{ Status = 'Running' }, @{ Status = 'Stopped' }
    ) {
        param($Status)
        $script:searchService.StartType = 'Manual'
        $script:searchService.Status = $Status
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing'
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing' -undo $true
        $script:searchService.StartType | Should -Be 'Manual'
        $script:searchService.Status | Should -Be $Status
        Should -Invoke Set-WinUtilService -Times 0 -Exactly
        Should -Invoke Stop-Service -Times 0 -Exactly
        Should -Invoke Start-Service -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 2 -Exactly -ParameterFilter { $Message -match 'WSearch.*Manual' }
    }

    It 'does not stop the indexer when setting Disabled fails' {
        Mock Set-WinUtilService { }
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing'
        Should -Invoke Stop-Service -Times 0 -Exactly
        $script:searchService.Status | Should -Be 'Running'
    }

    It 'does not start the indexer when restoring Automatic fails' {
        $script:searchService.StartType = 'Disabled'
        $script:searchService.Status = 'Stopped'
        Mock Set-WinUtilService { }
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing' -undo $true
        Should -Invoke Start-Service -Times 0 -Exactly
    }

    It 'does not repeat stop or start operations after reaching the desired state' {
        $script:searchService.StartType = 'Disabled'
        $script:searchService.Status = 'Stopped'
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing'
        Should -Invoke Stop-Service -Times 0 -Exactly
        $script:searchService.StartType = 'Automatic'
        $script:searchService.Status = 'Running'
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableSearchIndexing' -undo $true
        Should -Invoke Start-Service -Times 0 -Exactly
    }

    It 'skips absent WSearch in both configured scripts' {
        Mock Get-Service { $null }
        & ([scriptblock]::Create($script:searchTweaks.WPFTweaksDisableSearchIndexing.InvokeScript -join "`n"))
        & ([scriptblock]::Create($script:searchTweaks.WPFTweaksDisableSearchIndexing.UndoScript -join "`n"))
        Should -Invoke Stop-Service -Times 0 -Exactly
        Should -Invoke Start-Service -Times 0 -Exactly
    }

    It 'propagates stop and start failures from the configured scripts' {
        $script:searchService.StartType = 'Disabled'
        Mock Stop-Service { throw 'Indexer stop failed' }
        { & ([scriptblock]::Create($script:searchTweaks.WPFTweaksDisableSearchIndexing.InvokeScript -join "`n")) } | Should -Throw '*Indexer stop failed*'
        $script:searchService.StartType = 'Automatic'
        $script:searchService.Status = 'Stopped'
        Mock Start-Service { throw 'Indexer start failed' }
        { & ([scriptblock]::Create($script:searchTweaks.WPFTweaksDisableSearchIndexing.UndoScript -join "`n")) } | Should -Throw '*Indexer start failed*'
    }
}
