#===========================================================================
# Tests - Pausing a running job
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    . (Join-Path $script:functionRoot "private\Wait-WinUtilJobPause.ps1")

    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
    function Write-WinUtilJobProgress { param($Status, $Percent, $State, $Overlay, [switch]$Hide) }
}

Describe "Wait-WinUtilJobPause" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        Mock Write-WinUtilLog { }
    }

    It "only ever holds inside a job worker" {
        # whoever sets the pause reports it through the same progress call, so a caller that
        # held there would be waiting on itself
        $sync.JobPaused = $true
        $global:WinUtilIsJobWorker = $false

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilJobPause
        $clock.Elapsed.TotalMilliseconds | Should -BeLessThan 300
    }

    It "returns at once when nothing is paused" {
        $sync.JobPaused = $false
        $global:WinUtilIsJobWorker = $true

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilJobPause
        $clock.Elapsed.TotalMilliseconds | Should -BeLessThan 200
    }

    It "holds until the pause is lifted" {
        $sync.JobPaused = $true
        $global:WinUtilIsJobWorker = $true

        $timer = New-Object System.Timers.Timer
        $timer.Interval = 600
        $timer.AutoReset = $false
        Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action { $global:sync.JobPaused = $false } | Out-Null
        $timer.Start()

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilJobPause
        $clock.Stop()

        $clock.Elapsed.TotalMilliseconds | Should -BeGreaterThan 400
        $sync.JobPaused | Should -BeFalse

        $timer.Dispose()
        Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.Timers.Timer] } | Unregister-Event
    }

    It "stops holding when WinUtil is shutting down" {
        # a paused run must not keep the process alive after a close was asked for
        $sync.JobPaused = $true
        $sync.ShuttingDown = $true
        $global:WinUtilIsJobWorker = $true

        $clock = [Diagnostics.Stopwatch]::StartNew()
        Wait-WinUtilJobPause
        $clock.Elapsed.TotalSeconds | Should -BeLessThan 3
    }
}

Describe "Set-WinUtilJobPaused" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.WPFPauseJobButton = [pscustomobject]@{ Content = ""; ToolTip = ""; IsEnabled = $true }
        Mock Write-WinUtilLog { }
        Mock Write-WinUtilJobProgress { }
    }

    It "sets the flag and shows a resume glyph when pausing" {
        Set-WinUtilJobPaused -Paused $true

        $sync.JobPaused | Should -BeTrue
        $sync.WPFPauseJobButton.Content | Should -Be ([char]0xE768)
        $sync.WPFPauseJobButton.ToolTip | Should -Be "Resume"
    }

    It "clears the flag and shows a pause glyph when resuming" {
        Set-WinUtilJobPaused -Paused $true
        Set-WinUtilJobPaused -Paused $false

        $sync.JobPaused | Should -BeFalse
        $sync.WPFPauseJobButton.Content | Should -Be ([char]0xE769)
    }

    It "works before the button exists" {
        $sync.WPFPauseJobButton = $null

        { Set-WinUtilJobPaused -Paused $true } | Should -Not -Throw
        $sync.JobPaused | Should -BeTrue
    }
}

Describe "Stop-WinUtilJobIfRequested" {
    BeforeAll {
        . (Join-Path $script:functionRoot "private\Stop-WinUtilRunningJob.ps1")
    }

    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        Mock Write-WinUtilLog { }
    }

    It "does nothing when no stop was asked for" {
        $sync.StopRequested = $false
        $global:WinUtilIsJobWorker = $true

        { Stop-WinUtilJobIfRequested } | Should -Not -Throw
    }

    It "ends the run when a stop was asked for" {
        $sync.StopRequested = $true
        $global:WinUtilIsJobWorker = $true

        { Stop-WinUtilJobIfRequested } | Should -Throw
    }

    It "throws a cancellation, so the run is reported as stopped and not as broken" {
        $sync.StopRequested = $true
        $global:WinUtilIsJobWorker = $true

        $caught = $null
        try { Stop-WinUtilJobIfRequested } catch { $caught = $_.Exception }

        $caught | Should -BeOfType [System.OperationCanceledException]
    }

    It "never unwinds the thread that asked for the stop" {
        # the button handler goes through the same progress call
        $sync.StopRequested = $true
        $global:WinUtilIsJobWorker = $false

        { Stop-WinUtilJobIfRequested } | Should -Not -Throw
    }
}

Describe "Stop-WinUtilRunningJob" {
    BeforeAll {
        . (Join-Path $script:functionRoot "private\Stop-WinUtilRunningJob.ps1")
        function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) }
        function Stop-WinUtilActiveWork { param($TimeoutSeconds) $true }
        function Start-WinUtilJobStopWatchdog { param($Job, $GraceSeconds) }
    }

    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.ActiveJob = "Install"
        Mock Write-WinUtilLog { }
        Mock Write-WinUtilJobProgress { }
        Mock Start-WinUtilJobStopWatchdog { }
    }

    It "does nothing when nothing is running" {
        $sync.ActiveJob = $null
        Mock Show-WinUtilMessage { "Yes" }

        Stop-WinUtilRunningJob

        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
    }

    It "asks before stopping" {
        Mock Show-WinUtilMessage { "No" }

        Stop-WinUtilRunningJob

        $sync.StopRequested | Should -Not -BeTrue
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Button -eq "YesNo" -and $Message -like "*Install*"
        }
    }

    It "asks the run to stop when confirmed" {
        Mock Show-WinUtilMessage { "Yes" }

        Stop-WinUtilRunningJob

        $sync.StopRequested | Should -BeTrue
    }

    It "releases a pause, or the run would never notice the stop" {
        Mock Show-WinUtilMessage { "Yes" }
        $sync.JobPaused = $true

        Stop-WinUtilRunningJob

        $sync.JobPaused | Should -BeFalse
    }

    It "arms a watchdog, because a long single step reaches no safe point" {
        Mock Show-WinUtilMessage { "Yes" }

        Stop-WinUtilRunningJob

        Should -Invoke -CommandName Start-WinUtilJobStopWatchdog -Times 1 -Exactly
    }
}

Describe "Pause wiring" {
    It "holds at the point every loop reports progress" {
        # a command already running cannot be suspended; the gap between steps can
        $progress = Get-Content -Path (Join-Path $script:functionRoot "private\Write-WinUtilJobProgress.ps1") -Raw

        $progress | Should -Match 'Wait-WinUtilJobPause'
        $waitAt = $progress.IndexOf("Wait-WinUtilJobPause")
        $postAt = $progress.IndexOf("Invoke-WPFUIThread -Async")
        $waitAt | Should -BeLessThan $postAt
    }

    It "never blocks the thread that owns the window" {
        # blocking there would freeze the button that resumes it
        $wait = Get-Content -Path (Join-Path $script:functionRoot "private\Wait-WinUtilJobPause.ps1") -Raw

        $wait | Should -Match '\$global:WinUtilIsJobWorker'
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw
        $job | Should -Match '\$global:WinUtilIsJobWorker = \$true'
    }

    It "is reachable from the button" {
        $button = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFButton.ps1") -Raw

        $button | Should -Match '"WPFPauseJobButton" \{Set-WinUtilJobPaused -Paused \(-not \$sync\.JobPaused\)\}'
    }

    It "clears a leftover pause when the next job starts" {
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $job | Should -Match '\$sync\.JobPaused = \$false'
    }

    It "does not hold the job's own completion reporting" {
        # the finish is reported through the same progress call, so a pause left set there would
        # block the teardown and leave the job marked as running for ever
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $bodyEnd = $job.IndexOf('$jobClock.Stop()')
        $firstFinishReport = $job.IndexOf('Write-WinUtilJobProgress -Status "$JobName finished')
        $clearAt = $job.IndexOf('$sync.JobPaused = $false', $bodyEnd)

        $clearAt | Should -BeGreaterThan $bodyEnd
        $clearAt | Should -BeLessThan $firstFinishReport
    }

    It "releases a pause when the window is closed over the job" {
        # no window means no button to resume with
        $close = Get-Content -Path (Join-Path $script:functionRoot "private\Invoke-WinUtilCloseRequest.ps1") -Raw

        $close | Should -Match '\$sync\.JobPaused = \$false'
    }

    It "sits beside the progress bar" {
        $xaml = [xml](Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw)

        foreach ($name in @("WPFPauseJobButton", "WPFStopJobButton")) {
            $button = $xaml.SelectSingleNode("//*[local-name()='Button'][@Name='$name']")
            $button | Should -Not -BeNullOrEmpty -Because "$name should exist"
            # inside the progress bar's own border, so it appears and hides with it
            $button.ParentNode.ParentNode.GetAttribute("Name") | Should -Be "WPFTweaksProgressBar"
        }
    }

    It "reports a stopped run as stopped rather than failed" {
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $job | Should -Match 'catch \[System\.OperationCanceledException\]'
        $job | Should -Match 'Write-WinUtilJobBanner -Message "\$JobLabel stopped"'
    }

    It "clears the stop before reporting it, or the report throws it again" {
        $job = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilJob.ps1") -Raw

        $cancelAt = $job.IndexOf('catch [System.OperationCanceledException]')
        $clearAt = $job.IndexOf('$sync.StopRequested = $false', $cancelAt)
        $reportAt = $job.IndexOf('Write-WinUtilJobProgress -Status "$JobName stopped"', $cancelAt)

        $clearAt | Should -BeGreaterThan $cancelAt
        $clearAt | Should -BeLessThan $reportAt
    }

    It "is reachable from the stop button" {
        $button = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFButton.ps1") -Raw

        $button | Should -Match '"WPFStopJobButton" \{Stop-WinUtilRunningJob\}'
    }
}
