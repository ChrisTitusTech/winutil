#===========================================================================
# Tests - Job layer

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilErrorRecord.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")
    . (Join-Path $script:repoRoot "functions\private\Start-WinUtilJob.ps1")
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
            if ($script:dispatchCount -gt 1) {
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
