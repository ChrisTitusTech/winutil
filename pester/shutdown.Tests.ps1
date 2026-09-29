#===========================================================================
# Tests - Closing while something is running

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    . (Join-Path $script:functionRoot "private\Stop-WinUtilActiveWork.ps1")

    function Test-WinUtilUIAlive { $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher }

    . (Join-Path $script:functionRoot "private\Invoke-WinUtilCloseRequest.ps1")

    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
    function Step-WinUtilJob { param($Status, $Percent, $State, $Overlay, [switch]$Hide) }
    function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) }
    function Complete-WinUtilConsoleProgress { }
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

    It "treats a stopping invocation as active until it reaches a terminal state" {
        $shell = [pscustomobject]@{
            InvocationStateInfo = [pscustomobject]@{
                State = [System.Management.Automation.PSInvocationState]::Stopping
            }
        }

        Test-WinUtilShellRunning $shell | Should -BeTrue
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
        Mock Step-WinUtilJob { }
    }

    It "hands the job to the console and closes the window when asked to let it finish" {
        Mock Show-WinUtilMessage { "Yes" }
        Mock Write-Host { }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        # the window goes now; the job carries on without it
        $sync.FinishInConsole | Should -BeTrue
        $sync.ForceClose | Should -BeTrue
    }

    It "keeps the window open when the close is cancelled" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        $sync.FinishInConsole | Should -Not -BeTrue
        $sync.ForceClose | Should -Not -BeTrue
    }

    It "closes before the main thread stops the worker pool" {
        Mock Show-WinUtilMessage { "No" }
        Mock Request-WinUtilWindowClose { }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        $sync.ForceClose | Should -BeTrue
        Should -Invoke -CommandName Request-WinUtilWindowClose -Times 1 -Exactly
        (Get-Content (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilCloseRequest.ps1") -Raw) |
            Should -Not -Match 'Request-WinUtilWindowClose\s+-Before'
    }

    It "never shuts down the worker pool from the window closing handler" {
        (Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw) |
            Should -Not -Match 'Close-WinUtilRunspacePool'
    }



    It "offers all three choices" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Button -eq "YesNoCancel" -and $Message -like "*Install*" -and $Message -like "*console*"
        }
    }
}

Describe "Waiting for work that outlived the window" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    It "returns at once when nothing was left running" {
        $sync.FinishInConsole = $true
        $sync.ActiveJob = $null

        { Wait-WinUtilRemainingWork } | Should -Not -Throw
    }

    It "does not wait when the window was closed normally" {
        # a job cannot be active without FinishInConsole, but the guard must hold either way
        $sync.FinishInConsole = $false
        $sync.ActiveJob = "Install"

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilRemainingWork
        $clock.Elapsed.TotalSeconds | Should -BeLessThan 2
    }

    It "waits until the job clears the busy flag" {
        $sync.FinishInConsole = $true
        $sync.ActiveJob = "Install"

        # something else clears it, the way a worker's finally does
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 700
        $timer.AutoReset = $false
        Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action { $global:sync.ActiveJob = $null } | Out-Null
        $timer.Start()

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilRemainingWork
        $clock.Stop()

        $sync.ActiveJob | Should -BeNullOrEmpty
        $clock.Elapsed.TotalMilliseconds | Should -BeGreaterThan 500
        $timer.Dispose()
        Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.Timers.Timer] } | Unregister-Event
    }

    It "gives up rather than keeping the process alive for ever" {
        $sync.FinishInConsole = $true
        $sync.ActiveJob = "Install"

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilRemainingWork -TimeoutMinutes 0.02
        $clock.Stop()

        # it waited rather than returning at once, and gave up rather than waiting for ever
        $clock.Elapsed.TotalSeconds | Should -BeGreaterThan 0.5
        $clock.Elapsed.TotalSeconds | Should -BeLessThan 10
        $sync.ActiveJob | Should -Be "Install"
    }
}
