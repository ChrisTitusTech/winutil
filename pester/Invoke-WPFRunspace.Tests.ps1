BeforeAll {
    . (Join-Path $PSScriptRoot '..\functions\public\Invoke-WPFRunspace.ps1')
}

Describe 'Invoke-WPFRunspace' {
    BeforeEach {
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $global:sync = [Hashtable]::Synchronized(@{
            runspace = [runspacefactory]::CreateRunspacePool(1, 2, $initialSessionState, $Host)
            RunspaceJobs = [System.Collections.Generic.List[hashtable]]::new()
            RunspaceJobsLock = [object]::new()
        })
        $global:sync.runspace.Open()
    }

    AfterEach {
        Complete-WinUtilRunspaceJobs
        $global:sync.runspace.Close()
        $global:sync.runspace.Dispose()
    }

    It 'Returns a handle and does not dispose the shared runspace pool' {
        $handle = Invoke-WPFRunspace -ScriptBlock { 1 + 1 }
        $handle | Should -Not -BeNullOrEmpty
        $global:sync.runspace.GetType().Name | Should -Be 'RunspacePool'

        if (-not $handle.IsCompleted) {
            $handle.AsyncWaitHandle.WaitOne(5000) | Out-Null
        }
        Complete-WinUtilRunspaceJobs
        $global:sync.RunspaceJobs.Count | Should -Be 0
    }

    It 'Tracks async jobs until completion cleanup runs' {
        $handle = Invoke-WPFRunspace -ScriptBlock { Start-Sleep -Milliseconds 200; 'done' }
        $handle.IsCompleted | Should -Be $false
        $global:sync.RunspaceJobs.Count | Should -Be 1

        $handle.AsyncWaitHandle.WaitOne(5000) | Out-Null
        Complete-WinUtilRunspaceJobs
        $global:sync.RunspaceJobs.Count | Should -Be 0
    }
}