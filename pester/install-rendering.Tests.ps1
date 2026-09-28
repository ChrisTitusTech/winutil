#===========================================================================
# Tests - Install tab rendering

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Describe "Install app rendering startup contract" {






    It "drains queued app batches on the WPF dispatcher without timer scope errors" {
        Add-Type -AssemblyName WindowsBase
        function global:Test-WinUtilUIAlive { $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher }
        . (Join-Path $script:repoRoot "functions\private\Start-WinUtilBackgroundQueue.ps1")
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
            $global:sync.RenderFilterPasses = [System.Collections.Generic.List[object]]::new()

            function global:Initialize-InstallAppEntry {
                param($TargetElement, $AppKey)
                $renderedApps.Add($AppKey)
                return "entry:$AppKey"
            }


            function global:Test-WinUtilDeferBackgroundWork { param($RequiresTab) $false }
            function global:Invoke-WinUtilWhenIdle { param($Callback, $DelayMilliseconds) }

            function global:Find-AppsByNameOrDescription {
                param($SearchString, $Categories)
                $global:sync.RenderFilterPasses.Add([pscustomobject]@{
                    SearchString = $SearchString
                    Categories = $Categories
                    RenderedCount = $renderedApps.Count
                })
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
            $global:sync.RenderFilterPasses.Count | Should -BeGreaterOrEqual 2
            $global:sync.RenderFilterPasses[-1].RenderedCount | Should -Be 3
            foreach ($filterPass in $global:sync.RenderFilterPasses) {
                $filterPass.SearchString | Should -BeNullOrEmpty
                $filterPass.Categories | Should -BeNullOrEmpty
            }
            $global:Error.Count | Should -Be $errorCountBefore
            (Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1") -Raw) |
                Should -Not -Match 'Measure-WinUtilStep'
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








}
