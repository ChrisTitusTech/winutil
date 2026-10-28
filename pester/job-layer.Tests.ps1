#===========================================================================
# Tests - Job layer

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilErrorRecord.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")
    . (Join-Path $script:repoRoot "functions\private\Start-WinUtilJob.ps1")
    . (Join-Path $script:repoRoot "functions\private\Start-WinUtilNextQueuedJob.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilCloseRequest.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIThread.ps1")

    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Write-WinUtilJobBanner {
        param([string]$Message, [string]$Level)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component, [switch]$Detail)
    }
    function Step-WinUtilJob {
        param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }

    function script:Get-WinUtilJobRunspaceBody {
        param([hashtable]$ParameterList)

        $named = @{}
        foreach ($parameter in $ParameterList) {
            $named[$parameter[0]] = $parameter[1]
        }
        return $named
    }
}

Describe "Interface thread dispatch" {
    # Work handed to the interface thread must arrive as body text plus parameters. A scriptblock
    # marshalled from a worker runspace keeps that runspace's session state, so every command it
    # invokes is resolved back through the originating runspace. Measured on 400 invocations:
    # 5354 ms marshalled against 3 ms rebuilt from text.

    It "passes deferred values as parameters rather than capturing them" {
        foreach ($path in @(
            "functions\private\Step-WinUtilJob.ps1",
            "functions\private\Invoke-WinUtilISO.ps1"
        )) {
            $source = Get-Content -Path (Join-Path $script:repoRoot $path) -Raw

            $source | Should -Match ([regex]::Escape('Invoke-WPFUIThread -Async -Parameters @{'))
            $source | Should -Not -Match ([regex]::Escape('GetNewClosure'))
        }
    }
}

Describe "Invoke-WPFUIThread output" {
    BeforeEach {
        $dispatcher = [pscustomobject]@{ HasShutdownStarted = $false }
        $dispatcher | Add-Member -MemberType ScriptMethod -Name CheckAccess -Value { $true }
        $script:sync = [Hashtable]::Synchronized(@{
            Form = [pscustomobject]@{ Dispatcher = $dispatcher }
        })
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    # Output from the body must not join the caller's own return value: a caller that only
    # wanted a control updated would otherwise return an array and every index read wrong.
    It "swallows the body's output by default" {
        @(Invoke-WPFUIThread -ScriptBlock { "stray" }).Count | Should -Be 0
    }

    It "returns the body's output when asked" {
        Invoke-WPFUIThread -PassThru -ScriptBlock { "wanted" } | Should -Be "wanted"
    }

    It "passes values in rather than relying on the caller's scope" {
        Invoke-WPFUIThread -PassThru -Parameters @{ Value = 7 } -ScriptBlock {
            param($Value)
            $Value * 2
        } | Should -Be 14
    }

    It "ignores a synchronous dispatch canceled by window shutdown" {
        $dispatcher = [pscustomobject]@{ HasShutdownStarted = $false }
        $dispatcher | Add-Member -MemberType ScriptMethod -Name CheckAccess -Value { $false }
        $dispatcher | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
            param($Executor, $Work)
            $null = $Executor, $Work
            $this.HasShutdownStarted = $true
            throw [System.OperationCanceledException]::new("dispatcher stopped")
        }
        $script:sync = [Hashtable]::Synchronized(@{
            Form = [pscustomobject]@{ Dispatcher = $dispatcher }
            UIDispatchDelegate = [System.Func[object, object]]{ param($Work) $Work }
        })

        { Invoke-WPFUIThread -ScriptBlock { } } | Should -Not -Throw
    }

    It "does not hide a dispatch failure while the window is still alive" {
        $dispatcher = [pscustomobject]@{ HasShutdownStarted = $false }
        $dispatcher | Add-Member -MemberType ScriptMethod -Name CheckAccess -Value { $false }
        $dispatcher | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
            throw [System.InvalidOperationException]::new("not a shutdown")
        }
        $script:sync = [Hashtable]::Synchronized(@{
            Form = [pscustomobject]@{ Dispatcher = $dispatcher }
            UIDispatchDelegate = [System.Func[object, object]]{ param($Work) $Work }
        })

        { Invoke-WPFUIThread -ScriptBlock { } } | Should -Throw "*not a shutdown*"
    }

    It "rethrows synchronous callback failures for the waiting caller to log" {
        $tokens = $null
        $errors = $null
        $uiAst = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1"),
            [ref]$tokens,
            [ref]$errors
        )
        $delegateAssignment = $uiAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq '$sync.UIDispatchDelegate'
        }, $true)
        $delegateBody = $delegateAssignment.Right.Expression.Child.ScriptBlock.GetScriptBlock()
        $delegate = [System.Func[object, object]]$delegateBody
        Mock Write-WinUtilErrorRecord { }

        { $delegate.Invoke(@{ Body = 'throw "callback failed"'; Parameters = @{}; PropagateErrors = $true }) } |
            Should -Throw "*callback failed*"
        Should -Invoke Write-WinUtilErrorRecord -Times 0 -Exactly
    }

    It "logs asynchronous callback failures without throwing on the dispatcher" {
        $tokens = $null
        $errors = $null
        $uiAst = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1"),
            [ref]$tokens,
            [ref]$errors
        )
        $delegateAssignment = $uiAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq '$sync.UIDispatchDelegate'
        }, $true)
        $delegateBody = $delegateAssignment.Right.Expression.Child.ScriptBlock.GetScriptBlock()
        $delegate = [System.Func[object, object]]$delegateBody
        Mock Write-WinUtilErrorRecord { }

        { $delegate.Invoke(@{ Body = 'throw "callback failed"'; Parameters = @{}; PropagateErrors = $false }) } |
            Should -Not -Throw
        Should -Invoke Write-WinUtilErrorRecord -Times 1 -Exactly
    }
}

Describe "Start-WinUtilJob" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = $null
            Form = [pscustomobject]@{ Dispatcher = [pscustomobject]@{} }
            ItemsControl = [pscustomobject]@{ IsEnabled = $true }
        })
        $script:capturedRunspaceBody = $null
        $script:capturedRunspaceArgs = $null
        $script:activeJobAtQueueTime = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
        Mock Invoke-WPFUIThread { & $ScriptBlock }
        Mock Invoke-WPFRunspace {
            $script:activeJobAtQueueTime = $script:sync.ActiveJob
            $script:capturedRunspaceBody = $ScriptBlock
            $script:capturedRunspaceArgs = @{}
            foreach ($parameter in $ParameterList) {
                $script:capturedRunspaceArgs[$parameter[0]] = $parameter[1]
            }
            [pscustomobject]@{ MockHandle = $true }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedRunspaceBody -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedRunspaceArgs -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name activeJobAtQueueTime -Scope Script -ErrorAction SilentlyContinue
    }

    It "claims the busy state before the work is queued" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        $script:activeJobAtQueueTime | Should -Be "Example"
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Example" -and $Message -eq "Example job started."
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example..." -and $Percent -eq 0
        }
    }

    It "uses the description for the initial progress text" {
        Start-WinUtilJob -Name "Example" -Description "Doing the thing" -ScriptBlock { } | Out-Null

        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Doing the thing..." -and $Percent -eq 0 -and $State -eq "Normal" -and $Overlay -eq "logo"
        }
    }

    It "refuses a second job while one is running" {
        $script:sync.ActiveJob = "Install"

        $result = Start-WinUtilJob -Name "Tweaks" -ScriptBlock { }

        $result | Should -BeNullOrEmpty
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -like "Install is still running*"
        }
        $script:sync.ActiveJob | Should -Be "Install"
    }

    It "claims the slot with a token that identifies the run, not just its name" {
        Start-WinUtilJob -Name "Install" -ScriptBlock { } | Out-Null
        $first = $script:sync.ActiveJobToken

        $first | Should -Not -BeNullOrEmpty
        $script:capturedRunspaceArgs["JobToken"] | Should -Be $first

        # a second run of the same name gets its own token, so a late worker cannot release it
        $script:sync.ActiveJob = $null
        $script:sync.ActiveJobToken = $null
        Start-WinUtilJob -Name "Install" -ScriptBlock { } | Out-Null

        $script:sync.ActiveJobToken | Should -Not -Be $first
    }

    It "passes the body text and its parameters to the worker" {
        Start-WinUtilJob -Name "Example" -Parameters @{ Value = 42 } -ScriptBlock { param($Value) $Value } | Out-Null

        $script:capturedRunspaceArgs["JobName"] | Should -Be "Example"
        $script:capturedRunspaceArgs["JobBody"] | Should -BeOfType [string]
        $script:capturedRunspaceArgs["JobBody"] | Should -Match 'param\(\$Value\)'
        $script:capturedRunspaceArgs["JobParameters"].Value | Should -Be 42
        $script:capturedRunspaceArgs["JobRestoresAppList"] | Should -BeFalse
    }

    It "greys out the app list only when asked to" {
        Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } | Out-Null

        $script:sync.ItemsControl.IsEnabled | Should -BeFalse
        $script:capturedRunspaceArgs["JobRestoresAppList"] | Should -BeTrue
    }

    It "releases the job and restores the app list when scheduling fails" {
        Mock Invoke-WPFRunspace { throw "pool failed" }
        Mock Write-Host { }

        { Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } } | Should -Not -Throw

        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:sync.ItemsControl.IsEnabled | Should -BeTrue
    }

    It "releases the job when progress setup and failure reporting both throw" {
        Mock Step-WinUtilJob { throw "progress unavailable" }
        Mock Write-Host { }

        { Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } } | Should -Not -Throw

        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:sync.ActiveJobToken | Should -BeNullOrEmpty
        $script:sync.ItemsControl.IsEnabled | Should -BeTrue
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "reports completion and releases the busy state when the body succeeds" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobBody '$null = $true' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Example" -and $Message -like "Example job finished in * ms."
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example finished" -and $Percent -eq 100 -and $State -eq "None" -and $Overlay -eq "checkmark"
        }
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "does not let a stale worker replace the current job result" {
        Start-WinUtilJob -Name "Old" -ScriptBlock { } | Out-Null
        $oldToken = $script:capturedRunspaceArgs["JobToken"]
        $script:sync.ActiveJob = "Current"
        $script:sync.ActiveJobToken = "current-token"
        $script:sync.LastJobResult = [pscustomobject]@{ Token = "current-token"; Errors = 0; Warnings = 0 }

        & $script:capturedRunspaceBody `
            -JobName "Old" `
            -JobLabel "Old" `
            -JobBody '$global:WinUtilJobErrorCount = 1' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $oldToken

        $script:sync.LastJobResult.Token | Should -Be "current-token"
        $script:sync.ActiveJob | Should -Be "Current"
        $script:sync.ActiveJobToken | Should -Be "current-token"
    }

    It "logs the failure and releases the busy state when the body throws" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null
        $script:sync.ActiveJob = "Example"
        Mock Write-Host { }

        {
            & $script:capturedRunspaceBody `
                -JobName "Example" `
                -JobBody 'throw "boom"' `
                -JobParameters @{} `
                -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]
        } | Should -Not -Throw

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Component -eq "Example" -and $Message -like "*failed after * ms : boom"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example failed" -and $State -eq "Error" -and $Overlay -eq "warning"
        }
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "does not count an error again when the body logs it before throwing" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobLabel "Example" `
            -JobBody 'Write-WinUtilLog -Level "ERROR" -Component "Example" -Message "operation failed"; $exception = [System.InvalidOperationException]::new("operation failed"); $exception.Data["WinUtilErrorReported"] = $true; throw $exception' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and -not $Detail
        }
    }

    It "counts a distinct terminating error after an earlier reported error" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobLabel "Example" `
            -JobBody 'Write-WinUtilLog -Level "ERROR" -Component "Example" -Message "first failure"; throw "second failure"' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke Write-WinUtilLog -Times 2 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and -not $Detail
        }
    }

    It "reports a job that logged errors without throwing" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobLabel "Example" `
            -JobBody '$global:WinUtilJobErrorCount = 1' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example finished with 1 error(s)" -and $State -eq "Paused" -and $Overlay -eq "warning"
        }
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "ignores errors logged outside the active job worker" {
        $script:sync.LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        $null = $script:sync.LoggedErrors.Add("[UI] unrelated rendering failure")
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobLabel "Example" `
            -JobBody '$null = $sync.LoggedErrors.Add("[UI] another unrelated failure")' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example finished" -and $State -eq "None" -and $Overlay -eq "checkmark"
        }
    }

    It "surfaces warnings and non-terminating errors raised by the body" {
        $script:sync.LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobLabel "Example" `
            -JobBody 'Write-Warning "a warning"' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and $Message -eq "a warning"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example finished with 1 warning(s)" -and $State -eq "Paused" -and $Overlay -eq "warning"
        }
        $script:sync.LastJobResult.Warnings | Should -Be 1
        $script:sync.LastJobResult.Errors | Should -Be 0
    }

    It "finishes with a warning when elevated install skips a user-scoped package" {
        Start-WinUtilJob -Name "Install" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Install" `
            -JobLabel "Installing apps" `
            -JobBody 'Complete-WinUtilPackageRun -Action "Install" -Results @([pscustomobject]@{ Package = "Microsoft.Sysinternals.ProcessExplorer"; Action = "Install"; ExitCode = -1978335107; Outcome = "Skipped"; Detail = "already installed for the current user; elevated WinUtil cannot update it" })' `
            -JobParameters @{} `
            -JobRestoresAppList $false `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Install finished with 1 warning(s)" -and $State -eq "Paused" -and $Overlay -eq "warning"
        }
    }

    It "restores the app list after a failing job that disabled it" {
        Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } | Out-Null
        $script:sync.ActiveJob = "Install"
        Mock Write-Host { }

        & $script:capturedRunspaceBody `
            -JobName "Install" `
            -JobBody 'throw "boom"' `
            -JobParameters @{} `
            -JobRestoresAppList $true `
            -JobToken $script:capturedRunspaceArgs["JobToken"]

        $script:sync.ItemsControl.IsEnabled | Should -BeTrue
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "releases the job when dispatcher shutdown aborts the app-list restore" {
        $script:dispatchCount = 0
        Mock Invoke-WPFUIThread {
            $script:dispatchCount++
            # The first two posts are the queue button refresh and the app list being greyed out
            if ($script:dispatchCount -gt 2) {
                throw [System.Threading.Tasks.TaskCanceledException]::new("dispatcher stopped")
            }
            & $ScriptBlock
        }

        Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } | Out-Null

        {
            & $script:capturedRunspaceBody `
                -JobName "Install" `
                -JobBody '$null = $true' `
                -JobParameters @{} `
                -JobRestoresAppList $true `
                -JobToken $script:capturedRunspaceArgs["JobToken"]
        } | Should -Not -Throw

        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:sync.ActiveJobToken | Should -BeNullOrEmpty
        Should -Invoke Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and $Message -like "Could not restore the app list*"
        }
    }
}

Describe "Job timing summaries" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            StepTimings = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        })
        $null = $sync.StepTimings.Add([pscustomobject]@{ Scope = "Install"; Step = "old"; Milliseconds = 100 })
        $null = $sync.StepTimings.Add([pscustomobject]@{ Scope = "Install"; Step = "current"; Milliseconds = 25 })
        Mock Write-WinUtilLog { }
    }

    It "excludes entries recorded before the current run" {
        Write-WinUtilTimingSummary -Scope "Install" -TotalMilliseconds 30 -StartIndex 1

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "timing summary: 1 step(s), 25 ms measured of 30 ms total"
        }
    }
}

Describe "Job queue" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = $null
            JobQueue = [System.Collections.Generic.List[object]]::new()
            Form = [pscustomobject]@{ Dispatcher = [pscustomobject]@{} }
        })
        $script:started = [System.Collections.Generic.List[object]]::new()

        Mock Show-WinUtilMessage { "OK" }
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
        Mock Update-WinUtilJobQueueUI { }
        Mock Invoke-WPFUIThread { & $ScriptBlock }
        Mock Invoke-WPFRunspace {
            $runArgs = @{}
            foreach ($parameter in $ParameterList) { $runArgs[$parameter[0]] = $parameter[1] }
            $script:started.Add([pscustomobject]@{ Body = $ScriptBlock; Args = $runArgs })
        }
    }

    AfterEach {
        Remove-Variable -Name sync, started -Scope Script -ErrorAction SilentlyContinue
    }

    # Runs the worker body the way the pool would, which releases the slot and posts the next job
    function script:Complete-TestJob {
        param($Run, [string]$Body = '$null = $true')

        & $Run.Body -JobName $Run.Args["JobName"] -JobLabel $Run.Args["JobLabel"] -JobBody $Body `
            -JobParameters @{} -JobRestoresAppList $false -JobToken $Run.Args["JobToken"]
    }

    It "queues instead of refusing when asked to and the slot is taken" {
        $script:sync.ActiveJob = "Install"

        $result = Start-WinUtilJob -Name "Tweaks" -Description "Applying tweaks" -DisableAppList -QueueIfBusy -Parameters @{ Tweaks = @("A", "B") } -ScriptBlock { param($Tweaks) $Tweaks }

        $result | Should -BeNullOrEmpty
        $script:sync.JobQueue.Count | Should -Be 1
        $item = $script:sync.JobQueue[0]
        $item.Name | Should -Be "Tweaks"
        $item.Description | Should -Be "Applying tweaks"
        $item.DisableAppList | Should -BeTrue
        $item.Parameters.Tweaks | Should -Be @("A", "B")
        $item.ScriptBlock | Should -Match 'param\(\$Tweaks\)'
        [guid]::Parse($item.Id) | Should -Not -BeNullOrEmpty
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
        $script:started.Count | Should -Be 0
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Tweaks" -and $Message -like "*queued behind Install*position 1*"
        }
    }

    It "starts at once with the switch when the slot is free" {
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 0
        $script:sync.ActiveJob | Should -Be "Tweaks"
        $script:started.Count | Should -Be 1
    }

    It "still refuses with a message and leaves the queue alone without the switch" {
        $script:sync.ActiveJob = "Install"

        Start-WinUtilJob -Name "ISO mount" -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 0
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -like "Install is still running*"
        }
    }

    It "does not queue a nested job, which runs inline" {
        $script:sync.ActiveJob = "Install"
        $global:WinUtilIsJobWorker = $true
        try {
            Start-WinUtilJob -Name "Inner" -QueueIfBusy -Parameters @{ Value = 7 } -ScriptBlock { param($Value) $script:innerRan = $Value } | Out-Null
        } finally {
            $global:WinUtilIsJobWorker = $false
        }

        $script:innerRan | Should -Be 7
        $script:sync.JobQueue.Count | Should -Be 0
    }

    It "does not queue while WinUtil is closing" {
        $script:sync.ActiveJob = "Install"
        $script:sync.ShuttingDown = $true

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 0
    }

    It "runs queued jobs first in, first out, and carries on after one fails" {
        Start-WinUtilJob -Name "First" -QueueIfBusy -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Second" -QueueIfBusy -Parameters @{ Value = 2 } -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Third" -QueueIfBusy -DisableAppList -ScriptBlock { } | Out-Null
        $script:sync.JobQueue.Count | Should -Be 2

        Complete-TestJob -Run $script:started[0] -Body 'throw "boom"'

        $script:started.Count | Should -Be 2
        $script:started[1].Args["JobName"] | Should -Be "Second"
        $script:started[1].Args["JobParameters"].Value | Should -Be 2
        $script:sync.ActiveJob | Should -Be "Second"
        $script:sync.JobQueue.Count | Should -Be 1

        Complete-TestJob -Run $script:started[1]

        $script:started.Count | Should -Be 3
        $script:started[2].Args["JobName"] | Should -Be "Third"
        $script:started[2].Args["JobRestoresAppList"] | Should -BeTrue
        $script:sync.JobQueue.Count | Should -Be 0

        Complete-TestJob -Run $script:started[2]

        $script:started.Count | Should -Be 3
        $script:sync.ActiveJob | Should -BeNullOrEmpty
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Second" -and $Message -eq "Starting queued Second job."
        }
    }

    It "starts the next job when scheduling the current one fails" {
        $script:sync.ActiveJob = "Install"
        Start-WinUtilJob -Name "Queued" -QueueIfBusy -ScriptBlock { } | Out-Null
        $script:sync.ActiveJob = $null
        Mock Invoke-WPFRunspace {
            $script:started.Add($null)
            if ($script:started.Count -eq 1) { throw "pool is gone" }
        }

        Start-WinUtilJob -Name "Broken" -QueueIfBusy -ScriptBlock { } | Out-Null

        # Broken failed to schedule, released the slot, and the queued job took it
        $script:started.Count | Should -Be 2
        $script:sync.JobQueue.Count | Should -Be 0
    }

    It "does not start anything while the slot is held" {
        $script:sync.ActiveJob = "Install"
        Start-WinUtilJob -Name "Queued" -QueueIfBusy -ScriptBlock { } | Out-Null

        Start-WinUtilNextQueuedJob

        $script:sync.JobQueue.Count | Should -Be 1
        $script:started.Count | Should -Be 0
    }

    It "does not start the queue when WinUtil is closing" {
        foreach ($flag in @("ShuttingDown", "FinishInConsole")) {
            $script:sync.Remove("ShuttingDown")
            $script:sync.Remove("FinishInConsole")
            $script:sync.JobQueue.Clear()
            $script:sync.ActiveJob = "Install"
            Start-WinUtilJob -Name "Queued" -QueueIfBusy -ScriptBlock { } | Out-Null
            $script:sync.ActiveJobToken = "t"
            $script:sync[$flag] = $true

            $null = Clear-WinUtilActiveJob -Token "t"

            $script:sync.ActiveJob | Should -BeNullOrEmpty
            $script:sync.JobQueue.Count | Should -Be 1
            $script:started.Count | Should -Be 0
        }
    }

    It "does not start the queue when the slot is reset without a token" {
        $script:sync.ActiveJob = "Install"
        Start-WinUtilJob -Name "Queued" -QueueIfBusy -ScriptBlock { } | Out-Null

        $null = Clear-WinUtilActiveJob

        $script:sync.JobQueue.Count | Should -Be 1
        $script:started.Count | Should -Be 0
    }

    It "moves a job up and down and leaves the ends alone" {
        $script:sync.ActiveJob = "Install"
        foreach ($name in "A", "B", "C") {
            Start-WinUtilJob -Name $name -QueueIfBusy -ScriptBlock { } | Out-Null
        }
        $ids = @($script:sync.JobQueue | ForEach-Object Id)
        $order = { (@($script:sync.JobQueue | ForEach-Object Name)) -join "" }

        Move-WinUtilQueuedJob -Id $ids[0] -Direction Up
        & $order | Should -Be "ABC"
        Move-WinUtilQueuedJob -Id $ids[2] -Direction Down
        & $order | Should -Be "ABC"
        Move-WinUtilQueuedJob -Id $ids[1] -Direction Up
        & $order | Should -Be "BAC"
        Move-WinUtilQueuedJob -Id $ids[1] -Direction Down
        & $order | Should -Be "ABC"
        Move-WinUtilQueuedJob -Id $ids[0] -Direction Down
        & $order | Should -Be "BAC"
        Move-WinUtilQueuedJob -Id "not-an-id" -Direction Up
        & $order | Should -Be "BAC"

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "B" -and $Message -eq "Moved queued B job up."
        }
    }

    It "cancels a queued job and ignores one that already started" {
        $script:sync.ActiveJob = "Install"
        foreach ($name in "A", "B") {
            Start-WinUtilJob -Name $name -QueueIfBusy -ScriptBlock { } | Out-Null
        }
        $ids = @($script:sync.JobQueue | ForEach-Object Id)

        Remove-WinUtilQueuedJob -Id $ids[0]
        Remove-WinUtilQueuedJob -Id $ids[0]

        @($script:sync.JobQueue | ForEach-Object Name) | Should -Be @("B")
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "A" -and $Message -eq "Cancelled queued A job."
        }

        # B starts, so cancelling it now finds nothing in the queue and leaves the running job be
        $script:sync.ActiveJob = $null
        Start-WinUtilNextQueuedJob
        Remove-WinUtilQueuedJob -Id $ids[1]
        $script:sync.ActiveJob | Should -Be "B"
        $script:started.Count | Should -Be 1
    }

    It "keeps a queued job's parameters as they were when the user clicked" {
        $script:sync.ActiveJob = "Install"
        $selection = [System.Collections.Generic.List[string]]::new()
        $selection.Add("WPFTweaksOne")

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @($selection) } -ScriptBlock { } | Out-Null
        $selection.Add("WPFTweaksTwo")

        $script:sync.JobQueue[0].Parameters.Tweaks | Should -Be @("WPFTweaksOne")
    }

    It "snapshots the selection in each caller that queues" {
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFtweaksbutton.ps1")
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFFeatureInstall.ps1")
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxInstall.ps1")
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxRemoval.ps1")
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFundoall.ps1")
        $script:captured = @{}
        Mock Start-WinUtilJob { $script:captured[$Name] = @{ Queue = [bool]$QueueIfBusy; Parameters = $Parameters } }

        $newSelection = { $l = [System.Collections.Generic.List[string]]::new(); $l.Add("One"); , $l }
        $script:sync["WPFchangedns"] = [pscustomobject]@{ text = "Default" }
        $script:sync.configs = @{ appxHashtable = @{} }
        $script:sync.selectedTweaks = & $newSelection
        $script:sync.selectedFeatures = & $newSelection
        $script:sync.selectedAppx = & $newSelection

        Invoke-WPFtweaksbutton
        Invoke-WPFundoall
        Invoke-WPFFeatureInstall
        Invoke-WPFAppxInstall
        Invoke-WPFAppxRemoval
        $script:sync.selectedTweaks.Add("Two")
        $script:sync.selectedFeatures.Add("Two")
        $script:sync.selectedAppx.Add("Two")

        foreach ($name in "Tweaks", "Undo tweaks", "Features", "AppX install", "AppX") {
            $script:captured[$name].Queue | Should -BeTrue -Because $name
        }
        $script:captured["Tweaks"].Parameters.Tweaks | Should -Be @("One")
        $script:captured["Undo tweaks"].Parameters.Tweaks | Should -Be @("One")
        $script:captured["Features"].Parameters.Features | Should -Be @("One")
        $script:captured["AppX install"].Parameters.Selected | Should -Be @("One")
        $script:captured["AppX"].Parameters.Selected | Should -Be @("One")
    }

    It "queues a new action behind the head while the slot is held for the queue" {
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head"; Description = ""; ScriptBlock = ""; Parameters = @{}; DisableAppList = $false })
        $script:sync.JobHandoff = $true

        Start-WinUtilJob -Name "New" -QueueIfBusy -ScriptBlock { } | Out-Null

        @($script:sync.JobQueue | ForEach-Object Name) | Should -Be @("Head", "New")
        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:started.Count | Should -Be 0
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -like "*queued behind Queued operations, position 2*"
        }
    }

    It "refuses an action without the switch while the slot is held for the queue" {
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head" })
        $script:sync.JobHandoff = $true

        Start-WinUtilJob -Name "ISO mount" -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 1
        $script:started.Count | Should -Be 0
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -like "Queued operations is still running*"
        }
    }

    It "holds the slot for the queue after a job ends and hands it to the head" {
        Mock Invoke-WPFUIThread { }
        Start-WinUtilJob -Name "First" -QueueIfBusy -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Head" -QueueIfBusy -Parameters @{ Value = 1 } -ScriptBlock { } | Out-Null

        Complete-TestJob -Run $script:started[0]

        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:sync.JobHandoff | Should -BeTrue
        Start-WinUtilJob -Name "Late" -QueueIfBusy -ScriptBlock { } | Out-Null
        @($script:sync.JobQueue | ForEach-Object Name) | Should -Be @("Head", "Late")
        $script:started.Count | Should -Be 1

        Start-WinUtilNextQueuedJob

        $script:started.Count | Should -Be 2
        $script:started[1].Args["JobName"] | Should -Be "Head"
        $script:started[1].Args["JobParameters"].Value | Should -Be 1
        $script:sync.ActiveJob | Should -Be "Head"
        $script:sync.JobHandoff | Should -BeFalse
        @($script:sync.JobQueue | ForEach-Object Name) | Should -Be @("Late")
    }

    It "does not hold the slot when nothing is queued or WinUtil is closing" {
        $script:sync.ActiveJob = "A"
        $script:sync.ActiveJobToken = "t"
        $null = Clear-WinUtilActiveJob -Token "t"
        $script:sync.JobHandoff | Should -BeFalse

        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head" })
        $script:sync.ShuttingDown = $true
        $script:sync.ActiveJob = "A"
        $script:sync.ActiveJobToken = "t"
        $null = Clear-WinUtilActiveJob -Token "t"
        $script:sync.JobHandoff | Should -BeFalse
    }

    It "clears the handoff on every way out of the dispatch" {
        $queued = [pscustomobject]@{ Id = "1"; Name = "Head"; Description = ""; ScriptBlock = ""; Parameters = @{}; DisableAppList = $false }

        # closing
        $script:sync.JobHandoff = $true
        $script:sync.ShuttingDown = $true
        Start-WinUtilNextQueuedJob
        $script:sync.JobHandoff | Should -BeFalse
        $script:sync.Remove("ShuttingDown")

        # empty queue
        $script:sync.JobHandoff = $true
        Start-WinUtilNextQueuedJob
        $script:sync.JobHandoff | Should -BeFalse

        # slot taken, the queue is kept
        $script:sync.JobQueue.Add($queued)
        $script:sync.ActiveJob = "Other"
        $script:sync.JobHandoff = $true
        Start-WinUtilNextQueuedJob
        $script:sync.JobHandoff | Should -BeFalse
        $script:sync.JobQueue.Count | Should -Be 1

        # the job refuses to start because WinUtil began closing after the dequeue
        $script:sync.ActiveJob = $null
        $script:sync.JobHandoff = $true
        $script:sync.ShuttingDown = $true
        Start-WinUtilJob -Name "Head" -FromQueue -ScriptBlock { } | Out-Null
        $script:sync.JobHandoff | Should -BeFalse
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "clears the handoff when the dispatch cannot be posted" {
        Mock Invoke-WPFUIThread { throw "dispatcher is gone" }
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head" })
        $script:sync.ActiveJob = "A"
        $script:sync.ActiveJobToken = "t"

        $null = Clear-WinUtilActiveJob -Token "t"

        $script:sync.JobHandoff | Should -BeFalse
    }

    It "queues identical work once and ignores repeated clicks" {
        $script:sync.ActiveJob = "Install"

        foreach ($click in 1..4) {
            Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A", "B"); DnsProvider = "Default" } -ScriptBlock { } | Out-Null
        }

        $script:sync.JobQueue.Count | Should -Be 1
        Should -Invoke -CommandName Write-WinUtilLog -Times 3 -Exactly -ParameterFilter {
            $Component -eq "Tweaks" -and $Message -eq "Tweaks is already queued, ignored."
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
    }

    It "treats the same parameters given in a different key order as identical" {
        $script:sync.ActiveJob = "Install"

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters ([ordered]@{ A = 1; B = 2 }) -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters ([ordered]@{ B = 2; A = 1 }) -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 1
    }

    It "queues the same name again when the selection differs" {
        $script:sync.ActiveJob = "Install"

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A", "B") } -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Undo tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 3
    }

    It "does not compare against the running job" {
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null
        $script:sync.ActiveJob | Should -Be "Tweaks"

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 1
    }

    It "queues without the duplicate check when the parameters cannot be serialised" {
        Mock ConvertTo-Json { throw "cannot serialise" }
        $script:sync.ActiveJob = "Install"

        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null
        Start-WinUtilJob -Name "Tweaks" -QueueIfBusy -Parameters @{ Tweaks = @("A") } -ScriptBlock { } | Out-Null

        $script:sync.JobQueue.Count | Should -Be 2
        Should -Invoke -CommandName Write-WinUtilLog -Times 2 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and $Message -like "Could not compare Tweaks*"
        }
    }

    It "opts the user actions in and keeps the ISO and USB jobs refusing" {
        foreach ($path in @(
            "functions\public\Invoke-WPFInstall.ps1", "functions\public\Invoke-WPFUnInstall.ps1",
            "functions\public\Invoke-WPFAppxInstall.ps1", "functions\public\Invoke-WPFAppxRemoval.ps1",
            "functions\public\Invoke-WPFtweaksbutton.ps1", "functions\public\Invoke-WPFundoall.ps1",
            "functions\public\Invoke-WPFFeatureInstall.ps1", "functions\public\Invoke-WPFButton.ps1"
        )) {
            (Get-Content -Path (Join-Path $script:repoRoot $path) -Raw) | Should -Match 'Start-WinUtilJob [^\r\n]*-QueueIfBusy' -Because $path
        }
        foreach ($path in @("functions\private\Invoke-WinUtilISO.ps1", "functions\private\Invoke-WinUtilISOUSB.ps1")) {
            (Get-Content -Path (Join-Path $script:repoRoot $path) -Raw) | Should -Not -Match 'QueueIfBusy' -Because $path
        }
    }
}

Describe "Closing with queued jobs" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = "Install"
            JobQueue = [System.Collections.Generic.List[object]]::new()
        })
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "tells the user how many queued operations will be discarded" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install" -QueuedCount 2

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -like "*2 queued operation(s) will be discarded*"
        }
    }

    It "says nothing about the queue when it is empty" {
        Mock Show-WinUtilMessage { "Cancel" }

        Invoke-WinUtilCloseRequest -RunningJob "Install"

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -notlike "*queued*"
        }
    }

    It "empties the queue and reports how many it dropped" {
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "A" })
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "2"; Name = "B" })

        Clear-WinUtilJobQueue | Should -Be 2

        $script:sync.JobQueue.Count | Should -Be 0
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -like "Discarded 2 queued job(s)*"
        }
    }

    It "has the window's closing handler pass the count and clear the queue after the prompt" {
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $source | Should -Match 'Invoke-WinUtilCloseRequest -RunningJob \$runningJob -QueuedCount \$sync\.JobQueue\.Count'
        $source.IndexOf('Clear-WinUtilJobQueue') | Should -BeGreaterThan $source.IndexOf('Invoke-WinUtilCloseRequest -RunningJob')
    }

    It "asks only whether to discard when nothing is running, and closes on yes" {
        $script:sync.ActiveJob = $null
        Mock Show-WinUtilMessage { "Yes" }
        Mock Request-WinUtilWindowClose { }

        Invoke-WinUtilCloseRequest -RunningJob "Queued operations" -QueuedCount 2

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Button -eq "YesNo" -and $Message -like "Nothing is running. 2 queued operation(s) will be discarded*"
        }
        $script:sync.ForceClose | Should -BeTrue
        $script:sync.FinishInConsole | Should -Not -BeTrue
        Should -Invoke -CommandName Request-WinUtilWindowClose -Times 1 -Exactly
    }

    It "shuts the queue before the accepted queued-only close is posted" {
        $script:sync.ActiveJob = $null
        $script:sync.JobHandoff = $true
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head" })
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "2"; Name = "Next" })
        Mock Show-WinUtilMessage { "Yes" }
        $script:atClose = $null
        Mock Request-WinUtilWindowClose {
            $script:atClose = @{ Shutting = $script:sync.ShuttingDown; Queued = $script:sync.JobQueue.Count; Handoff = $script:sync.JobHandoff }
        }

        Invoke-WinUtilCloseRequest -RunningJob "Queued operations" -QueuedCount 2

        $script:atClose.Shutting | Should -BeTrue
        $script:atClose.Queued | Should -Be 0
        $script:atClose.Handoff | Should -BeFalse
    }

    It "refuses a job that tries to start once the queued-only close is accepted" {
        Mock Show-WinUtilMessage { "Yes" }
        Mock Request-WinUtilWindowClose { }
        $script:sync.ActiveJob = $null
        Invoke-WinUtilCloseRequest -RunningJob "Queued operations" -QueuedCount 1
        Mock Invoke-WPFRunspace { }
        Mock Step-WinUtilJob { }
        Mock Invoke-WPFUIThread { }

        Start-WinUtilJob -Name "Late" -QueueIfBusy -ScriptBlock { } | Out-Null

        $script:sync.ActiveJob | Should -BeNullOrEmpty
        $script:sync.JobQueue.Count | Should -Be 0
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "keeps the window open and the queue when the queued-only close is declined" {
        $script:sync.ActiveJob = $null
        Mock Show-WinUtilMessage { "No" }
        Mock Request-WinUtilWindowClose { }

        Invoke-WinUtilCloseRequest -RunningJob "Queued operations" -QueuedCount 2

        $script:sync.ForceClose | Should -Not -BeTrue
        Should -Invoke -CommandName Request-WinUtilWindowClose -Times 0 -Exactly
    }

    It "asks again about the running job when a queued job started during the prompt" {
        $script:sync.ActiveJob = $null
        $script:sync.JobQueue.Add([pscustomobject]@{ Id = "1"; Name = "Head" })
        $script:asked = 0
        Mock Show-WinUtilMessage {
            $script:asked++
            if ($script:asked -eq 1) { $script:sync.ActiveJob = "Head"; return "Yes" }
            return "Cancel"
        }
        Mock Request-WinUtilWindowClose { }

        Invoke-WinUtilCloseRequest -RunningJob "Queued operations" -QueuedCount 2

        Should -Invoke -CommandName Show-WinUtilMessage -Times 2 -Exactly
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter { $Title -eq "Head is still running" }
        $script:sync.ForceClose | Should -Not -BeTrue
        $script:sync.ShuttingDown | Should -Not -BeTrue
        $script:sync.JobQueue.Count | Should -Be 1
        Should -Invoke -CommandName Request-WinUtilWindowClose -Times 0 -Exactly
    }

    It "has the closing handler prompt for queued work even with nothing running" {
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $source | Should -Match '\(\$sync\.ActiveJob -or \$sync\.JobQueue\.Count -gt 0\) -and -not \$sync\.ForceClose'
    }
}
