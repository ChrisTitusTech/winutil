#===========================================================================
# Tests - Closing while something is running
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    . (Join-Path $script:functionRoot "private\Stop-WinUtilActiveWork.ps1")
    . (Join-Path $script:functionRoot "private\Invoke-WinUtilCloseRequest.ps1")

    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
    function Write-WinUtilJobProgress { param($Status, $Percent, $State, $Overlay, [switch]$Hide) }
    function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) }
}

Describe "Tracking what is running" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
    }

    It "reports nothing to stop before anything has run" {
        # @($null) is a one element array holding null, so a missing collection once read as one
        # running item and the shutdown logged work that did not exist
        Stop-WinUtilActiveWork | Should -BeTrue
    }

    It "creates the collection on first use" {
        $shell = [powershell]::Create()
        try {
            Register-WinUtilActiveShell -PowerShell $shell
            @($sync.ActiveShells).Count | Should -Be 1
        } finally {
            $shell.Dispose()
        }
    }

    It "drops instances that have finished instead of holding them for the session" {
        $first = [powershell]::Create()
        $second = [powershell]::Create()
        try {
            Register-WinUtilActiveShell -PowerShell $first
            # the first is NotStarted, so registering another should sweep it away
            Register-WinUtilActiveShell -PowerShell $second

            @($sync.ActiveShells).Count | Should -Be 1
            [object]::ReferenceEquals(@($sync.ActiveShells)[0], $second) | Should -BeTrue
        } finally {
            $first.Dispose(); $second.Dispose()
        }
    }

    It "survives an instance that was disposed underneath it" {
        $shell = [powershell]::Create()
        Register-WinUtilActiveShell -PowerShell $shell
        $shell.Dispose()

        { Stop-WinUtilActiveWork -TimeoutSeconds 1 } | Should -Not -Throw
    }

    It "stops work that is genuinely running" {
        $pool = [runspacefactory]::CreateRunspacePool(1, 2)
        $pool.Open()
        $shell = [powershell]::Create()
        $shell.RunspacePool = $pool
        $null = $shell.AddScript('Start-Sleep -Seconds 30')
        $null = $shell.BeginInvoke()

        Register-WinUtilActiveShell -PowerShell $shell
        try {
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $stopped = Stop-WinUtilActiveWork -TimeoutSeconds 10
            $clock.Stop()

            $stopped | Should -BeTrue
            $clock.Elapsed.TotalSeconds | Should -BeLessThan 10
            $shell.InvocationStateInfo.State | Should -Not -Be ([System.Management.Automation.PSInvocationState]::Running)
        } finally {
            try { $shell.Dispose() } catch { }
            $pool.Close(); $pool.Dispose()
        }
    }

    It "gives up rather than holding the window open for ever" {
        # a worker inside a command that never returns cannot be stopped, and must not stop the
        # window closing either
        $global:sync.ActiveShells = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        $stubborn = [pscustomobject]@{
            InvocationStateInfo = [pscustomobject]@{ State = [System.Management.Automation.PSInvocationState]::Running }
        }
        $stubborn | Add-Member -MemberType ScriptMethod -Name BeginStop -Value { param($a, $b) $null }
        $null = $sync.ActiveShells.Add($stubborn)

        $clock = [Diagnostics.Stopwatch]::StartNew()
        $result = Stop-WinUtilActiveWork -TimeoutSeconds 1
        $clock.Stop()

        $result | Should -BeFalse
        $clock.Elapsed.TotalSeconds | Should -BeLessThan 5
    }
}

Describe "The close question" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.ActiveJob = "Install"
        Mock Write-WinUtilLog { }
        Mock Write-WinUtilJobProgress { }
    }

    It "waits for the job when asked to let it finish" {
        Mock Show-WinUtilMessage { "Yes" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        $sync.CloseWhenIdle | Should -BeTrue
        $sync.ForceClose | Should -Not -BeTrue
    }

    It "keeps the window open when the close is cancelled" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        $sync.CloseWhenIdle | Should -Not -BeTrue
        $sync.ForceClose | Should -Not -BeTrue
    }

    It "asks a question the buttons answer in any language" {
        # Windows labels the buttons itself, so text naming them "Yes" does not match a button
        # that reads "Ja"
        $source = Get-Content -Path (Join-Path $script:functionRoot "private\Invoke-WinUtilCloseRequest.ps1") -Raw

        $source | Should -Match 'Wait for it to finish before closing'
        $source | Should -Not -Match '(?m)^Yes\s+wait'
    }

    It "offers all three choices" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Button -eq "YesNoCancel" -and $Message -like "*Install*" -and $Message -like "*Wait for it to finish*"
        }
    }
}

Describe "Completing a pending close" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        Mock Write-WinUtilLog { }
    }

    It "does nothing when no close is pending" {
        $sync.CloseWhenIdle = $false

        { Complete-WinUtilPendingClose } | Should -Not -Throw
    }

    It "does not throw when the window has already gone" {
        $sync.CloseWhenIdle = $true
        $sync.Form = $null

        { Complete-WinUtilPendingClose } | Should -Not -Throw
        # cleared, so a later job cannot try to close a window that is not there
        $sync.CloseWhenIdle | Should -BeFalse
    }
}

Describe "Shutdown wiring" {
    It "asks before closing while a job is running" {
        $ui = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilUserInterface.ps1") -Raw

        $ui | Should -Match '\$closingArgs\.Cancel = \$true'
        $ui | Should -Match 'Invoke-WinUtilCloseRequest -RunningJob \$sync\.ActiveJob'
    }

    It "stops running work before closing the pool" {
        # closing the pool first leaves a queued instance to start on a runspace that is already
        # closing, which throws on a thread pool thread and ends the process
        $close = Get-Content -Path (Join-Path $script:functionRoot "private\Close-WinUtilRunspacePool.ps1") -Raw

        $stopAt = $close.IndexOf("Stop-WinUtilActiveWork")
        $closeAt = $close.IndexOf('$sync.runspace.Close()')

        $stopAt | Should -BeGreaterThan 0
        $closeAt | Should -BeGreaterThan $stopAt
        $close | Should -Match '\$sync\.ShuttingDown = \$true'
    }

    It "refuses to queue new work once shutdown has begun" {
        $runspace = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFRunspace.ps1") -Raw
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $runspace | Should -Match 'if \(\$sync\.ShuttingDown\)'
        $job | Should -Match 'if \(\$sync\.ShuttingDown -or \$sync\.CloseWhenIdle\)'
    }

    It "closes once the awaited job finishes" {
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $job | Should -Match 'Complete-WinUtilPendingClose'
    }
}
