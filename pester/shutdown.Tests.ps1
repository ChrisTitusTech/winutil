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

    It "asks a question the buttons answer in any language" {
        # Windows labels the buttons itself, so text naming them "Yes" does not match a button
        # that reads "Ja"
        $source = Get-Content -Path (Join-Path $script:functionRoot "private\Invoke-WinUtilCloseRequest.ps1") -Raw

        $source | Should -Match 'Close the window and let it finish in the console\?'
        $source | Should -Not -Match '(?m)^Yes\s+'
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
        Wait-WinUtilRemainingWork -TimeoutMinutes ([double]0.01)
        $clock.Stop()

        $clock.Elapsed.TotalSeconds | Should -BeLessThan 10
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

    It "keeps the worker pool alive when the job is to finish in the console" {
        # closing the pool there would stop the very work the user asked to let finish
        $ui = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilUserInterface.ps1") -Raw

        $ui | Should -Match 'if \(\$sync\.FinishInConsole\) \{[\s\S]{0,400}?return'
        $closeAt = $ui.IndexOf("Close-WinUtilRunspacePool")
        $guardAt = $ui.IndexOf('if ($sync.FinishInConsole)')
        $guardAt | Should -BeGreaterThan 0
        $guardAt | Should -BeLessThan $closeAt
    }

    It "waits for that work on the main thread before closing the pool" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        $waitAt = $mainScript.IndexOf("Wait-WinUtilRemainingWork")
        $closeAt = $mainScript.LastIndexOf("Close-WinUtilRunspacePool")

        $waitAt | Should -BeGreaterThan 0
        $closeAt | Should -BeGreaterThan $waitAt
    }

    It "reports progress to the console once the window has gone" {
        # the dispatcher still accepts posts after shutdown and drops them, so a closed window
        # has to count as no window or the run goes silent
        $progress = Get-Content -Path (Join-Path $script:functionRoot "private\Write-WinUtilJobProgress.ps1") -Raw

        $progress | Should -Match '\$sync\.Form\.Dispatcher\.HasShutdownStarted'
    }

    It "refuses to queue new work once shutdown has begun" {
        $runspace = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFRunspace.ps1") -Raw
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $runspace | Should -Match 'if \(\$sync\.ShuttingDown\)'
        $job | Should -Match 'if \(\$sync\.ShuttingDown -or \$sync\.FinishInConsole\)'
    }

    It "clears the busy flag last, since the main thread waits on it" {
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $job | Should -Match '\$sync\.ActiveJob = \$null\s*\}'
    }
}
