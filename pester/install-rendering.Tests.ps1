#===========================================================================
# Tests - Install tab rendering
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Describe "Install app rendering startup contract" {
    It "queues app entries after creating category containers" {
        $categoryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallCategoryAppList.ps1") -Raw

        $categoryScript | Should -Match '\$sync\.InstallAppRenderQueue = \[System\.Collections\.Queue\]::new\(\)'
        $categoryScript | Should -Match 'Start-WinUtilInstallAppRendering'
        $categoryScript | Should -Match 'Pre-group apps by category before creating WPF controls'
    }

    It "renders queued apps through dispatcher callbacks when a form dispatcher exists" {
        $renderScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $renderScript | Should -Match 'Dispatcher\.BeginInvoke'
        $renderScript | Should -Match 'Invoke-WinUtilInstallAppRenderNextBatch'
        $renderScript | Should -Match 'Initialize-InstallAppEntry'
        $renderScript | Should -Match '\$sync\.InstallAppEntriesRendered = \$true'
    }

    It "does not use dispatcher timers for deferred install rendering" {
        $renderScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $renderScript | Should -Not -Match 'DispatcherTimer'
        $renderScript | Should -Not -Match '\$timer'
        $renderScript | Should -Not -Match '\$dispatcherTimer'
        $renderScript | Should -Not -Match '\$timer\.Stop\(\)'
        $renderScript | Should -Not -Match '& \$renderCategory'
    }

    It "drains queued app batches on the WPF dispatcher without timer scope errors" {
        Add-Type -AssemblyName WindowsBase
        . (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1")

        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        $previousInitializeAppEntry = Get-Item -Path Function:\Initialize-InstallAppEntry -ErrorAction SilentlyContinue
        $previousSearch = Get-Item -Path Function:\Find-AppsByNameOrDescription -ErrorAction SilentlyContinue
        $errorCountBefore = $global:Error.Count

        try {
            $global:sync = [Hashtable]::Synchronized(@{})
            $global:sync.currentTab = "Install"
            $global:sync.SearchBar = [pscustomobject]@{ Text = "" }
            $global:sync.Form = [pscustomobject]@{ Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher }
            $global:sync.InstallAppRenderQueue = [System.Collections.Queue]::new()

            $renderedApps = [System.Collections.Generic.List[string]]::new()

            function global:Initialize-InstallAppEntry {
                param($TargetElement, $AppKey)
                $renderedApps.Add($AppKey)
                return "entry:$AppKey"
            }

            function global:Find-AppsByNameOrDescription {
                param($SearchString)
                throw "Search should not run for an empty search box in this test."
            }

            $global:sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{ TargetElement = [pscustomobject]@{}; AppKeys = @("AppA", "AppB") })
            $global:sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{ TargetElement = [pscustomobject]@{}; AppKeys = @("AppC") })

            $frame = New-Object System.Windows.Threading.DispatcherFrame
            $timeout = [System.Diagnostics.Stopwatch]::StartNew()
            Start-WinUtilInstallAppRendering

            $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
            $closeTimer.Interval = [TimeSpan]::FromMilliseconds(25)
            $closeTimer.Add_Tick({
                param($eventSender)
                $timer = [System.Windows.Threading.DispatcherTimer]$eventSender

                if ($global:sync.InstallAppEntriesRendered -or $timeout.Elapsed.TotalSeconds -gt 5) {
                    $timer.Stop()
                    $frame.Continue = $false
                }
            })
            $closeTimer.Start()

            [System.Windows.Threading.Dispatcher]::PushFrame($frame)

            $global:sync.InstallAppEntriesRendered | Should -BeTrue
            $global:sync.InstallAppRenderQueue.Count | Should -Be 0
            @($renderedApps) | Should -Be @("AppA", "AppB", "AppC")
            $global:Error.Count | Should -Be $errorCountBefore
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }

            foreach ($functionBackup in @(
                    @{ Name = "Initialize-InstallAppEntry"; Backup = $previousInitializeAppEntry },
                    @{ Name = "Find-AppsByNameOrDescription"; Backup = $previousSearch }
                )) {
                if ($functionBackup.Backup) {
                    Set-Item -Path "Function:\$($functionBackup.Name)" -Value $functionBackup.Backup.ScriptBlock
                } else {
                    Remove-Item -Path "Function:\$($functionBackup.Name)" -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It "keeps app-entry metadata lookup independent from the old caller scope" {
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $entryScript | Should -Match '\$app = \$sync\.configs\.applicationsHashtable\.\$appKey'
        $entryScript | Should -Not -Match '\$Apps\.\$appKey'
    }

    It "restores delayed app checkbox state from selected apps" {
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $entryScript | Should -Match '\$sync\.selectedApps -contains \$appKey'
        $entryScript | Should -Match '\$checkBox\.IsChecked = \$true'
    }
}
