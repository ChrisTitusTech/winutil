#===========================================================================
# Tests - Headless runs never need a window
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
    $script:startScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\start.ps1") -Raw

    . (Join-Path $script:functionRoot "private\Update-WinUtilSelections.ps1")

    # Stubs so the mocks below have something to replace; the real ones live in other files
    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
    function Write-WinUtilTimingSummary { param($Scope, $TotalMilliseconds) }
    function Write-WinUtilErrorRecord { param($ErrorRecord, $Component, $Context) }
    function Invoke-WPFtweaksbutton { }
    function Invoke-WPFToggleSelections { }
    function Invoke-WPFFeatureInstall { }
    function Invoke-WPFInstall { }
    function Invoke-WPFAppxRemoval { }
}

Describe "Headless entry point" {
    It "handles preset and config through one path" {
        $script:mainScript | Should -Match 'if \(\$Preset -or \$Config\) \{'
    }

    It "ends with an exit code an automated caller can read" {
        $script:mainScript | Should -Match 'exit \$headlessCode'
        $script:mainScript | Should -Match 'Write-WinUtilAutoRunSummary'
    }

    It "cleans up even when the run throws" {
        # Without a finally a failed run leaves the worker pool open and the transcript running
        $script:mainScript | Should -Match '\} finally \{[\s\S]*Close-WinUtilRunspacePool[\s\S]*Stop-Transcript'
    }

    It "names the presets that exist when given one that does not" {
        $script:mainScript | Should -Match "There is no preset called"
    }

    It "waits for the elevated run and passes its code back" {
        # Start-Process without -Wait returns immediately, so the caller would see success
        # regardless of what the run did
        $script:startScript | Should -Match '\$elevated = Start-Process[^\r\n]*-Wait -PassThru'
        $script:startScript | Should -Match 'exit \$elevated\.ExitCode'
    }
}

Describe "Headless reporting" {
    It "reports progress on the console when there is no window" {
        $progress = Get-Content -Path (Join-Path $script:functionRoot "private\Write-WinUtilJobProgress.ps1") -Raw

        $progress | Should -Match 'Write-WinUtilConsoleProgress'
        # the headless branch has to come before the dispatcher post, which would discard it
        $headlessBranch = ($progress -split 'Invoke-WPFUIThread -Async')[0]
        $headlessBranch | Should -Match 'null -eq \$sync\.Form'
    }

    It "throttles repeated progress so package downloads do not bury the log" {
        $console = Get-Content -Path (Join-Path $script:functionRoot "private\Write-WinUtilConsoleProgress.ps1") -Raw

        $console | Should -Match 'TotalMilliseconds -lt \$throttleMs'
        # redirected output has no cursor to rewrite, so it is throttled hard instead
        $console | Should -Match 'if \(\$redirected\) \{ 1000 \} else \{ 150 \}'
    }

    It "rewrites the progress line in place on a console" {
        # one line per update scrolls a screenful for a single install
        $console = Get-Content -Path (Join-Path $script:functionRoot "private\Write-WinUtilConsoleProgress.ps1") -Raw

        $console | Should -Match '\[Console\]::IsOutputRedirected'
        $console | Should -Match 'Write-Host \("`r\$line"'
        $console | Should -Match '-NoNewline'
        # and a line left open has to be closed before anything else prints
        $console | Should -Match 'function Complete-WinUtilConsoleProgress'
    }
}

Describe "Invoke-WinUtilAutoRun" {
    BeforeAll {
        . (Join-Path $script:functionRoot "public\Invoke-WinUtilAutoRun.ps1")
    }

    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
        $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
        $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
        $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
        $sync.selectedAppx = [System.Collections.Generic.List[string]]::new()
        $sync.LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        $sync.ActiveJob = $null

        Mock Write-WinUtilLog { }
        Mock Write-WinUtilTimingSummary { }
        Mock Write-WinUtilErrorRecord { }
    }

    It "does nothing and says so when nothing is selected" {
        $summary = Invoke-WinUtilAutoRun

        @($summary.Steps).Count | Should -Be 0
        Should -Invoke -CommandName Write-WinUtilLog -ParameterFilter { $Level -eq "WARN" -and $Message -like "*nothing to do*" }
    }

    It "applies toggles, which nothing outside the window ever did" {
        $sync.selectedToggles.Add("WPFToggleDarkMode")
        Mock Invoke-WPFToggleSelections { }

        $summary = Invoke-WinUtilAutoRun

        Should -Invoke -CommandName Invoke-WPFToggleSelections -Times 1 -Exactly
        @($summary.Steps | Where-Object { $_.Name -eq "Toggles" }).Count | Should -Be 1
    }

    It "runs only the steps that have something selected" {
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFInstall { }
        Mock Invoke-WPFtweaksbutton { }

        $summary = Invoke-WinUtilAutoRun

        @($summary.Steps).Count | Should -Be 1
        $summary.Steps[0].Name | Should -Be "Applications"
        Should -Invoke -CommandName Invoke-WPFtweaksbutton -Times 0 -Exactly
    }

    It "gives up on a step that never finishes instead of hanging for good" {
        $sync.selectedApps.Add("WPFInstall7zip")
        # a job that sets the flag and never clears it
        Mock Invoke-WPFInstall { $sync.ActiveJob = "Install" }

        $summary = Invoke-WinUtilAutoRun -StepTimeoutSeconds 1

        $summary.TimedOut | Should -Be 1
        # and the flag must be released, or every later step would be refused
        $sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "counts a step's errors against the run" {
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFInstall { $null = $sync.LoggedErrors.Add("boom") }

        $summary = Invoke-WinUtilAutoRun

        $summary.Failed | Should -Be 1
        $summary.Errors | Should -Be 1
    }

    It "keeps going after a step throws rather than abandoning the run" {
        $sync.selectedTweaks.Add("WPFTweaksDiskCleanup")
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFtweaksbutton { throw "tweaks blew up" }
        Mock Invoke-WPFInstall { }

        $summary = Invoke-WinUtilAutoRun

        Should -Invoke -CommandName Invoke-WPFInstall -Times 1 -Exactly
        @($summary.Steps).Count | Should -Be 2
    }
}

Describe "Write-WinUtilAutoRunSummary" {
    BeforeAll {
        . (Join-Path $script:functionRoot "public\Invoke-WinUtilAutoRun.ps1")
    }

    BeforeEach {
        $global:sync = @{ logPath = "C:\temp\winutil.log" }
        Mock Write-Host { }
    }

    It "returns 0 when every step was clean" {
        $summary = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Tweaks"; Items = 1; Seconds = 1; Errors = 0; TimedOut = $false })
            Failed = 0; TimedOut = 0; Errors = 0
        }

        Write-WinUtilAutoRunSummary -Summary $summary | Should -Be 0
    }

    It "returns 1 when a step failed or timed out" {
        $failed = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Tweaks"; Items = 1; Seconds = 1; Errors = 2; TimedOut = $false })
            Failed = 1; TimedOut = 0; Errors = 2
        }
        Write-WinUtilAutoRunSummary -Summary $failed | Should -Be 1

        $timedOut = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Apps"; Items = 1; Seconds = 60; Errors = 0; TimedOut = $true })
            Failed = 0; TimedOut = 1; Errors = 0
        }
        Write-WinUtilAutoRunSummary -Summary $timedOut | Should -Be 1
    }

    It "returns 2 when nothing was selected, which is not the same as success" {
        $summary = [pscustomobject]@{ Steps = @(); Failed = 0; TimedOut = 0; Errors = 0 }

        Write-WinUtilAutoRunSummary -Summary $summary | Should -Be 2
    }
}

Describe "Update-WinUtilSelections" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        foreach ($list in @("selectedApps","selectedTweaks","selectedToggles","selectedFeatures","selectedAppx")) {
            $sync.$list = [System.Collections.Generic.List[string]]::new()
        }
        Mock Write-WinUtilLog { }
    }

    It "sorts each prefix into its own list" {
        Update-WinUtilSelections -flatJson @("WPFInstall7zip","WPFTweaksDiskCleanup","WPFToggleDarkMode","WPFFeaturesdotnet","WPFAppxBing")

        $sync.selectedApps | Should -Contain "WPFInstall7zip"
        $sync.selectedTweaks | Should -Contain "WPFTweaksDiskCleanup"
        $sync.selectedToggles | Should -Contain "WPFToggleDarkMode"
        $sync.selectedFeatures | Should -Contain "WPFFeaturesdotnet"
        $sync.selectedAppx | Should -Contain "WPFAppxBing"
    }

    It "names an unrecognised entry instead of failing on a null list" {
        # $sync.$null.Add() throws "you cannot call a method on a null-valued expression",
        # which never says which entry was at fault
        { Update-WinUtilSelections -flatJson @("NotAWinUtilEntry") } | Should -Not -Throw

        Should -Invoke -CommandName Write-WinUtilLog -ParameterFilter {
            $Level -eq "WARN" -and $Message -like "*NotAWinUtilEntry*"
        }
    }

    It "does not select the same entry twice when a preset and a config both list it" {
        Update-WinUtilSelections -flatJson @("WPFInstall7zip")
        Update-WinUtilSelections -flatJson @("WPFInstall7zip")

        @($sync.selectedApps).Count | Should -Be 1
    }
}
