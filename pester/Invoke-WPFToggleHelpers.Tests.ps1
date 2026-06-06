BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\private\Invoke-WPFToggleHelpers.ps1')
    . (Join-Path $PSScriptRoot '..\functions\public\Invoke-WPFRunspace.ps1')

    $global:sync = [Hashtable]::Synchronized(@{
        ProcessRunning = $false
        ActiveToggleJobs = 0
        ToggleExecution = [Hashtable]::Synchronized(@{})
        ImportInProgress = $false
        WPFToggleTest = [PSCustomObject]@{ IsChecked = $true }
    })
}

Describe 'Test-WPFToggleActionAllowed' {
    It 'Blocks when import is in progress' {
        $result = Test-WPFToggleActionAllowed -ImportInProgress $true
        $result.Allowed | Should -Be $false
        $result.Reason | Should -Be 'ImportInProgress'
    }

    It 'Blocks when a batch process is running' {
        $global:sync.ProcessRunning = $true
        try {
            $result = Test-WPFToggleActionAllowed -ImportInProgress $false
            $result.Allowed | Should -Be $false
            $result.Reason | Should -Be 'ProcessBusy'
        } finally {
            $global:sync.ProcessRunning = $false
        }
    }

    It 'Blocks when toggle jobs are active' {
        $global:sync.ActiveToggleJobs = 1
        try {
            $result = Test-WPFToggleActionAllowed -ImportInProgress $false
            $result.Allowed | Should -Be $false
        } finally {
            $global:sync.ActiveToggleJobs = 0
        }
    }

    It 'Allows action when idle' {
        $result = Test-WPFToggleActionAllowed -ImportInProgress $false
        $result.Allowed | Should -Be $true
    }
}

Describe 'Set-WPFToggleCheckedState' {
    It 'Reverts checkbox state without leaving SuppressToggleEvents set' {
        Set-WPFToggleCheckedState -ToggleName 'WPFToggleTest' -IsChecked $false
        $global:sync.SuppressToggleEvents | Should -Be $false
        $global:sync.WPFToggleTest.IsChecked | Should -Be $false
    }
}

Describe 'Test-WPFToggleExecutionLock' {
    It 'Rejects duplicate locks for the same toggle' {
        Test-WPFToggleExecutionLock -ToggleName 'WPFToggleTest' | Should -Be $true
        Test-WPFToggleExecutionLock -ToggleName 'WPFToggleTest' | Should -Be $false
        Release-WPFToggleExecutionLock -ToggleName 'WPFToggleTest'
    }
}

Describe 'Start-WPFToggleTweakJob' {
    It 'Clears lock and decrements ActiveToggleJobs when queueing fails' {
        Mock Invoke-WPFRunspace { throw 'queue failed' }

        { Start-WPFToggleTweakJob -ToggleName 'WPFToggleTest' -Undo $false } | Should -Throw
        $global:sync.ToggleExecution.ContainsKey('WPFToggleTest') | Should -Be $false
        $global:sync.ActiveToggleJobs | Should -Be 0
    }
}