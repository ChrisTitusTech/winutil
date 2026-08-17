#===========================================================================
# Tests - Speculative work stands aside for the user
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    . (Join-Path $script:functionRoot "private\Test-WinUtilDeferBackgroundWork.ps1")

    function Test-WinUtilUIAlive { $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher }

}

Describe "Test-WinUtilDeferBackgroundWork" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.currentTab = "Install"
        $sync.LastInputAt = [datetime]::MinValue
    }

    It "runs work when the user is idle and the tab is the one being drawn" {
        Test-WinUtilDeferBackgroundWork -RequiresTab "Install" | Should -BeFalse
    }

    It "waits while the user is interacting" {
        # background priority puts work behind input in the queue but does not make the piece
        # already running interruptible
        $sync.LastInputAt = [datetime]::Now

        Test-WinUtilDeferBackgroundWork | Should -BeTrue
    }

    It "runs again once the interaction has passed" {
        $sync.LastInputAt = [datetime]::Now.AddSeconds(-2)

        Test-WinUtilDeferBackgroundWork | Should -BeFalse
    }

    It "waits while the work is for a tab that is not on screen" {
        $sync.currentTab = "Tweaks"

        Test-WinUtilDeferBackgroundWork -RequiresTab "Install" | Should -BeTrue
    }

    It "does not care which tab is open for work that belongs to no tab" {
        $sync.currentTab = "Tweaks"

        Test-WinUtilDeferBackgroundWork | Should -BeFalse
    }

    It "copes with the timestamp never having been set" {
        $sync.Remove("LastInputAt")

        { Test-WinUtilDeferBackgroundWork } | Should -Not -Throw
        Test-WinUtilDeferBackgroundWork | Should -BeFalse
    }
}

Describe "Invoke-WinUtilWhenIdle" {
    BeforeEach {
        Add-Type -AssemblyName WindowsBase
        $global:sync = [hashtable]::Synchronized(@{})
        $global:sync.Form = [pscustomobject]@{ Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher }
    }

    It "actually runs the callback" {
        # a retry that never fires abandons whatever was deferred, and nothing reports it
        $global:ranCount = 0
        Invoke-WinUtilWhenIdle -Callback { $global:ranCount++ } -DelayMilliseconds 20

        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $guard = New-Object System.Windows.Threading.DispatcherTimer
        $guard.Interval = [timespan]::FromMilliseconds(20)
        $guard.Tag = @{ Frame = $frame; Clock = [Diagnostics.Stopwatch]::StartNew() }
        $guard.Add_Tick({
            param($eventSender)
            $t = [System.Windows.Threading.DispatcherTimer]$eventSender
            if ($global:ranCount -gt 0 -or $t.Tag.Clock.Elapsed.TotalSeconds -gt 3) {
                $t.Stop()
                $t.Tag.Frame.Continue = $false
            }
        })
        $guard.Start()
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)

        $global:ranCount | Should -Be 1
    }

    It "runs the callback exactly once, not on every tick" {
        $global:ranCount = 0
        Invoke-WinUtilWhenIdle -Callback { $global:ranCount++ } -DelayMilliseconds 20

        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $stop = New-Object System.Windows.Threading.DispatcherTimer
        $stop.Interval = [timespan]::FromMilliseconds(300)
        $stop.Tag = $frame
        $stop.Add_Tick({
            param($eventSender)
            $t = [System.Windows.Threading.DispatcherTimer]$eventSender
            $t.Stop()
            $t.Tag.Continue = $false
        })
        $stop.Start()
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)

        $global:ranCount | Should -Be 1
    }

    It "does nothing when the window has gone" {
        $global:sync.Form = $null

        { Invoke-WinUtilWhenIdle -Callback { throw "should not run" } } | Should -Not -Throw
    }
}

Describe "Deferral wiring" {
    It "checks before running another queued step" {
        # one pump for every queue, so this check cannot be forgotten by a new caller
        $queue = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilBackgroundQueue.ps1") -Raw

        $queue | Should -Match 'Test-WinUtilDeferBackgroundWork -RequiresTab \$state\.RequiresTab'
        $queue | Should -Match 'Invoke-WinUtilWhenIdle'
    }

    It "draws app entries against the tab they belong to" {
        $render = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $render | Should -Match '-RequiresTab "Install"'
    }

    It "runs queued steps at background priority, not idle priority" {
        # At idle priority warmup only ran once the app list had finished, so for the first few
        # seconds every tab but the open one was empty and cost a full build to open
        $queue = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilBackgroundQueue.ps1") -Raw

        $queue | Should -Match 'DispatcherPriority\]::Background'
        $queue | Should -Not -Match 'DispatcherPriority\]::ApplicationIdle'
    }

    It "finishes building the other tabs before finishing the visible list" {
        # the list is on screen and filling in; another tab shows nothing at all until built
        $render = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $render | Should -Match '-DeferWhile'
        $render | Should -Match '\$sync\.TabWarmupQueue -and \$sync\.TabWarmupQueue\.Count -gt 0'
    }

    It "records input before a control handles it" {
        # a click that a control spends time on must still count as input
        $watch = Get-Content -Path (Join-Path $script:functionRoot "private\Test-WinUtilDeferBackgroundWork.ps1") -Raw

        $watch | Should -Match 'Add_PreviewMouseDown'
        $watch | Should -Match 'Add_PreviewKeyDown'
    }

    It "registers the watch before the window is shown" {
        $ui = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilUserInterface.ps1") -Raw

        $registerAt = $ui.IndexOf("Register-WinUtilInputWatch")
        $showAt = $ui.IndexOf("ShowDialog")

        $registerAt | Should -BeGreaterThan 0
        $registerAt | Should -BeLessThan $showAt
    }
}
