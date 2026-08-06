#===========================================================================
# Tests - Job layer
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilErrorRecord.ps1")
    . (Join-Path $script:repoRoot "functions\private\Start-WinUtilJob.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIThread.ps1")

    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Write-WinUtilJobBanner {
        param([string]$Message, [string]$Level)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Write-WinUtilJobProgress {
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
    # Work handed to the interface thread must arrive as body text plus parameters. A
    # scriptblock marshalled from a worker runspace keeps that runspace's session state, which
    # both loses the caller's variables on an async post and costs roughly twenty times as much
    # per command - enough to turn a checkbox refresh into a visible freeze.
    It "hands work to the interface runspace instead of marshalling a scriptblock" {
        $uiThread = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIThread.ps1") -Raw
        $userInterface = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $userInterface | Should -Match ([regex]::Escape('$sync.UIDispatchDelegate = [System.Func[object, object]]'))
        $uiThread | Should -Match ([regex]::Escape('$executor = $sync.UIDispatchDelegate'))
        $uiThread | Should -Match ([regex]::Escape('Body = $ScriptBlock.ToString()'))
        $uiThread | Should -Match ([regex]::Escape('$dispatcher.Invoke($executor, @($work))'))
        $uiThread | Should -Match ([regex]::Escape('$dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, $executor, $work)'))
    }

    It "passes deferred values as parameters rather than capturing them" {
        foreach ($path in @(
            "functions\private\Write-WinUtilJobProgress.ps1",
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
        Mock Write-WinUtilJobProgress { }
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
        Should -Invoke -CommandName Write-WinUtilJobProgress -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example..." -and $Percent -eq 0
        }
    }

    It "uses the description for the initial progress text" {
        Start-WinUtilJob -Name "Example" -Description "Doing the thing" -ScriptBlock { } | Out-Null

        Should -Invoke -CommandName Write-WinUtilJobProgress -Times 1 -Exactly -ParameterFilter {
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

    It "reports completion and releases the busy state when the body succeeds" {
        Start-WinUtilJob -Name "Example" -ScriptBlock { } | Out-Null

        & $script:capturedRunspaceBody `
            -JobName "Example" `
            -JobBody '$null = $true' `
            -JobParameters @{} `
            -JobRestoresAppList $false

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Example" -and $Message -like "Example job finished in * ms."
        }
        Should -Invoke -CommandName Write-WinUtilJobProgress -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example finished" -and $Percent -eq 100 -and $State -eq "None" -and $Overlay -eq "checkmark"
        }
        $script:sync.ActiveJob | Should -BeNullOrEmpty
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
                -JobRestoresAppList $false
        } | Should -Not -Throw

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Component -eq "Example" -and $Message -like "*failed after * ms : boom"
        }
        Should -Invoke -CommandName Write-WinUtilJobProgress -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Example failed" -and $State -eq "Error" -and $Overlay -eq "warning"
        }
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "restores the app list after a failing job that disabled it" {
        Start-WinUtilJob -Name "Install" -DisableAppList -ScriptBlock { } | Out-Null
        $script:sync.ActiveJob = "Install"
        Mock Write-Host { }

        & $script:capturedRunspaceBody `
            -JobName "Install" `
            -JobBody 'throw "boom"' `
            -JobParameters @{} `
            -JobRestoresAppList $true

        $script:sync.ItemsControl.IsEnabled | Should -BeTrue
        $script:sync.ActiveJob | Should -BeNullOrEmpty
    }
}
