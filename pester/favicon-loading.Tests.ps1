BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Add-Type -AssemblyName PresentationFramework
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilFaviconUrl.ps1")
    . (Join-Path $script:repoRoot "functions\private\Close-WinUtilFaviconRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilFaviconRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1")
}

Describe "WinUtil favicon loading" {
    It "builds a favicon URL from an application link" {
        Get-WinUtilFaviconUrl -Link "https://example.com/path?a=1&b=2" |
            Should -Be "https://www.google.com/s2/favicons?sz=64&domain_url=https%3A%2F%2Fexample.com%2Fpath%3Fa%3D1%26b%3D2"
    }

    It "returns no URL for a blank application link" {
        Get-WinUtilFaviconUrl -Link " " | Should -BeNullOrEmpty
    }

    It "uses a dedicated pool sized to the available logical processors" {
        $poolScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilFaviconRunspacePool.ps1") -Raw

        $poolScript | Should -Match '\$maxThreads = \[Environment\]::ProcessorCount'
        $poolScript | Should -Match 'CreateRunspacePool'
    }

    It "replaces a stale pool without clearing shared favicon state" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        $stalePool = [runspacefactory]::CreateRunspacePool(1, 1)
        $stalePool.Open()
        $stalePool.Close()
        $circuitBreaker = [pscustomobject]@{ Name = "Test breaker" }
        $operations = [hashtable]::Synchronized(@{})

        try {
            $global:sync = [hashtable]::Synchronized(@{
                FaviconCircuitBreaker = $circuitBreaker
                FaviconOperations     = $operations
                FaviconRunspace       = $stalePool
            })

            $replacementPool = Initialize-WinUtilFaviconRunspacePool

            $replacementPool.RunspacePoolStateInfo.State | Should -Be ([System.Management.Automation.Runspaces.RunspacePoolState]::Opened)
            [object]::ReferenceEquals($global:sync.FaviconCircuitBreaker, $circuitBreaker) | Should -BeTrue
            [object]::ReferenceEquals($global:sync.FaviconOperations, $operations) | Should -BeTrue
        } finally {
            if ($global:sync.FaviconRunspace) {
                $global:sync.FaviconRunspace.Close()
                $global:sync.FaviconRunspace.Dispose()
            }
            if ($previousSync) {
                $global:sync = $previousSync.Value
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "downloads favicon bytes without assigning a network URL to the WPF image" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $fetchScript | Should -Match 'WebRequest\]::Create'
        $fetchScript | Should -Match 'AddScript'
        $fetchScript | Should -Match 'ServicePoint\.ConnectionLimit = \$connectionLimit'
        $fetchScript | Should -Match 'FaviconRunspace\.GetMaxRunspaces\(\)'
        $fetchScript | Should -Match 'Status = "Success"'
        $fetchScript | Should -Match 'Status = "NetworkFailure"'
        $fetchScript | Should -Match 'Status = "Cancelled"'
        $entryScript | Should -Match 'Get-WinUtilFaviconUrl -Link \$app\.link'
        $entryScript | Should -Match '\$sync\.FaviconQueue\.Enqueue'
        $entryScript | Should -Not -Match 'Invoke-WinUtilFaviconFetch'
        $entryScript | Should -Not -Match '\$logo\.Source = "https://www\.google\.com/s2/favicons'
    }

    It "keeps byte arrays inside structured runspace results" {
        $pool = [runspacefactory]::CreateRunspacePool(1, 1)
        $pool.Open()
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $pool
        [void]$powershell.AddScript({
            $bytes = [byte[]](1, 2, 3, 4)
            return [pscustomobject]@{
                Status = "Success"
                Bytes  = $bytes
            }
        })

        try {
            $handle = $powershell.BeginInvoke()
            $results = @($powershell.EndInvoke($handle))

            $results.Count | Should -Be 1
            $results[0].Status | Should -Be "Success"
            ([byte[]]$results[0].Bytes).Length | Should -Be 4
            [Convert]::ToBase64String([byte[]]$results[0].Bytes) | Should -Be "AQIDBA=="
        } finally {
            $powershell.Dispose()
            $pool.Close()
            $pool.Dispose()
        }
    }

    It "opens the circuit after eight consecutive network failures" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $global:sync = [hashtable]::Synchronized(@{})
            Initialize-WinUtilFaviconCircuitBreaker

            1..7 | ForEach-Object { $global:sync.FaviconCircuitBreaker.ReportFailure() }
            $global:sync.FaviconCircuitBreaker.IsCancellationRequested | Should -BeFalse

            $global:sync.FaviconCircuitBreaker.ReportFailure()
            $global:sync.FaviconCircuitBreaker.IsCancellationRequested | Should -BeTrue
        } finally {
            if ($global:sync.FaviconCircuitBreaker) {
                $global:sync.FaviconCircuitBreaker.Dispose()
            }
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "rejects a circuit threshold that is not greater than zero" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $global:sync = [hashtable]::Synchronized(@{})
            Initialize-WinUtilFaviconCircuitBreaker
            $global:sync.FaviconCircuitBreaker.Dispose()

            { [WinUtilFaviconCircuitBreaker]::new(0) } | Should -Throw "*Threshold must be greater than zero*"
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "resets consecutive failures on success and ignores cancellations" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $global:sync = [hashtable]::Synchronized(@{})
            Initialize-WinUtilFaviconCircuitBreaker

            1..7 | ForEach-Object { $global:sync.FaviconCircuitBreaker.ReportFailure() }
            $global:sync.FaviconCircuitBreaker.ReportSuccess()
            1..7 | ForEach-Object { $global:sync.FaviconCircuitBreaker.ReportFailure() }

            $global:sync.FaviconCircuitBreaker.ConsecutiveFailures | Should -Be 7
            $global:sync.FaviconCircuitBreaker.IsCancellationRequested | Should -BeFalse
        } finally {
            if ($global:sync.FaviconCircuitBreaker) {
                $global:sync.FaviconCircuitBreaker.Dispose()
            }
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "checks the shared breaker before scheduling and again inside each worker" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw
        $scheduleCheck = $fetchScript.IndexOf('if ($sync.FaviconCircuitBreaker.IsCancellationRequested)')
        $beginInvoke = $fetchScript.IndexOf('$powershell.BeginInvoke()')

        $scheduleCheck | Should -BeGreaterOrEqual 0
        $scheduleCheck | Should -BeLessThan $beginInvoke
        $fetchScript | Should -Match 'if \(\$circuitBreaker\.IsCancellationRequested\)'
        $fetchScript | Should -Not -Match '\$circuitBreaker\.ReportSuccess\(\)'
        $fetchScript | Should -Match '\$Operation\.Sync\.FaviconCircuitBreaker\.ReportSuccess\(\)'
        $fetchScript | Should -Match '\$Operation\.Sync\.FaviconCircuitBreaker\.ReportFailure\(\)'
        $fetchScript | Should -Match '\$circuitBreaker\.ReportFailure\(\)'
        $fetchScript | Should -Match '\$failureThreshold = 8'
    }

    It "submits only enough requests to fill the dedicated pool" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $breaker = [pscustomobject]@{ IsCancellationRequested = $false }
            $breaker | Add-Member -MemberType ScriptMethod -Name Cancel -Value { $this.IsCancellationRequested = $true }
            $pool = [pscustomobject]@{}
            $pool | Add-Member -MemberType ScriptMethod -Name GetMaxRunspaces -Value { 2 }
            $global:sync = [hashtable]::Synchronized(@{
                FaviconCircuitBreaker = $breaker
                FaviconRunspace       = $pool
                FaviconOperations     = [hashtable]::Synchronized(@{})
                FaviconQueue          = [System.Collections.Queue]::new()
            })

            1..5 | ForEach-Object {
                $global:sync.FaviconQueue.Enqueue([pscustomobject]@{
                    AppKey      = "App$_"
                    Url         = "https://example.com/$_"
                    TargetImage = [Windows.Controls.Image]::new()
                    Fallback    = [Windows.Controls.TextBlock]::new()
                })
            }

            Mock Invoke-WinUtilFaviconFetch {
                $global:sync.FaviconOperations[$AppKey] = [pscustomobject]@{ AppKey = $AppKey }
            }

            Invoke-WinUtilFaviconQueuePump

            $global:sync.FaviconOperations.Count | Should -Be 2
            $global:sync.FaviconQueue.Count | Should -Be 3
            Should -Invoke -CommandName Invoke-WinUtilFaviconFetch -Times 2 -Exactly
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "refills available capacity after a favicon operation completes" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $breaker = [pscustomobject]@{ IsCancellationRequested = $false }
            $breaker | Add-Member -MemberType ScriptMethod -Name ReportFailure -Value { }
            $breaker | Add-Member -MemberType ScriptMethod -Name ReportSuccess -Value { }
            $pool = [pscustomobject]@{}
            $pool | Add-Member -MemberType ScriptMethod -Name GetMaxRunspaces -Value { 1 }
            $worker = [pscustomobject]@{ Disposed = $false }
            $worker | Add-Member -MemberType ScriptMethod -Name EndInvoke -Value {
                param($handle)
                return [pscustomobject]@{ Status = "Cancelled"; Bytes = $null }
            }
            $worker | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $this.Disposed = $true }
            $global:sync = [hashtable]::Synchronized(@{
                FaviconCircuitBreaker = $breaker
                FaviconRunspace       = $pool
                FaviconOperations     = [hashtable]::Synchronized(@{})
                FaviconQueue          = [System.Collections.Queue]::new()
            })
            $global:sync.FaviconQueue.Enqueue([pscustomobject]@{
                AppKey      = "NextApp"
                Url         = "https://example.com/next"
                TargetImage = [Windows.Controls.Image]::new()
                Fallback    = [Windows.Controls.TextBlock]::new()
            })
            $operation = [pscustomobject]@{
                AppKey      = "CurrentApp"
                PowerShell  = $worker
                Handle      = $null
                Sync        = $global:sync
                TargetImage = [Windows.Controls.Image]::new()
                Fallback    = [Windows.Controls.TextBlock]::new()
                Bytes       = $null
            }
            $global:sync.FaviconOperations[$operation.AppKey] = $operation

            Mock Invoke-WinUtilFaviconFetch {
                $global:sync.FaviconOperations[$AppKey] = [pscustomobject]@{ AppKey = $AppKey }
            }

            Complete-WinUtilFaviconFetch -Operation $operation

            $worker.Disposed | Should -BeTrue
            $global:sync.FaviconQueue.Count | Should -Be 0
            $global:sync.FaviconOperations.ContainsKey("NextApp") | Should -BeTrue
            Should -Invoke -CommandName Invoke-WinUtilFaviconFetch -Times 1 -Exactly
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "drops pending requests when the circuit breaker is open" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $pool = [pscustomobject]@{}
            $pool | Add-Member -MemberType ScriptMethod -Name GetMaxRunspaces -Value { 2 }
            $global:sync = [hashtable]::Synchronized(@{
                FaviconCircuitBreaker = [pscustomobject]@{ IsCancellationRequested = $true }
                FaviconRunspace       = $pool
                FaviconOperations     = [hashtable]::Synchronized(@{})
                FaviconQueue          = [System.Collections.Queue]::new()
            })
            $global:sync.FaviconQueue.Enqueue([pscustomobject]@{ AppKey = "PendingApp" })
            Mock Invoke-WinUtilFaviconFetch { }

            Invoke-WinUtilFaviconQueuePump

            $global:sync.FaviconQueue.Count | Should -Be 0
            Should -Invoke -CommandName Invoke-WinUtilFaviconFetch -Times 0 -Exactly
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "stops pending work when request submission fails" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $breaker = [pscustomobject]@{ IsCancellationRequested = $false }
            $breaker | Add-Member -MemberType ScriptMethod -Name Cancel -Value { $this.IsCancellationRequested = $true }
            $pool = [pscustomobject]@{}
            $pool | Add-Member -MemberType ScriptMethod -Name GetMaxRunspaces -Value { 2 }
            $global:sync = [hashtable]::Synchronized(@{
                FaviconCircuitBreaker = $breaker
                FaviconRunspace       = $pool
                FaviconOperations     = [hashtable]::Synchronized(@{})
                FaviconQueue          = [System.Collections.Queue]::new()
            })
            1..2 | ForEach-Object {
                $global:sync.FaviconQueue.Enqueue([pscustomobject]@{
                    AppKey      = "App$_"
                    Url         = "https://example.com/$_"
                    TargetImage = [Windows.Controls.Image]::new()
                    Fallback    = [Windows.Controls.TextBlock]::new()
                })
            }
            Mock Invoke-WinUtilFaviconFetch { throw "submission failed" }

            { Invoke-WinUtilFaviconQueuePump } | Should -Not -Throw

            $breaker.IsCancellationRequested | Should -BeTrue
            $global:sync.FaviconQueue.Count | Should -Be 0
            Should -Invoke -CommandName Invoke-WinUtilFaviconFetch -Times 1 -Exactly
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "clears pending requests when favicon setup fails" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $global:sync = [hashtable]::Synchronized(@{ FaviconQueue = [System.Collections.Queue]::new() })
            $global:sync.FaviconQueue.Enqueue([pscustomobject]@{ AppKey = "PendingApp" })
            Mock Initialize-WinUtilFaviconCircuitBreaker { throw "setup failed" }
            Mock Close-WinUtilFaviconRunspacePool { }

            { Start-WinUtilFaviconLoading } | Should -Not -Throw

            $global:sync.FaviconQueue.Count | Should -Be 0
            Should -Invoke -CommandName Close-WinUtilFaviconRunspacePool -Times 1 -Exactly
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    It "applies results and fallback state through the WPF dispatcher" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw

        $fetchScript | Should -Match 'DispatcherTimer'
        $fetchScript | Should -Match 'Handle\.IsCompleted'
        $fetchScript | Should -Match '\$Operation\.Bytes = \[byte\[\]\]\$result\.Bytes'
        $fetchScript | Should -Not -Match '\$results\[0\]\.BaseObject'
        $fetchScript | Should -Match 'BitmapImage\]::new\(\)'
        $fetchScript | Should -Match 'BitmapCacheOption\]::OnLoad'
        $fetchScript | Should -Match 'TargetImage\.Visibility = \[Windows\.Visibility\]::Collapsed'
        $fetchScript | Should -Match 'Fallback\.Visibility = \[Windows\.Visibility\]::Visible'
    }

    It "counts unexpected completion failures without double-counting worker outcomes" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw

        $fetchScript | Should -Match '\$result\.Status -notin @\("NetworkFailure", "Cancelled"\)'
        $fetchScript | Should -Match 'if \(-not \$Operation\.Sync\.FaviconCircuitBreaker\.IsCancellationRequested\)'
    }

    It "cleans up failed favicon submissions" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw

        $fetchScript | Should -Match '\[object\]::ReferenceEquals\(\$sync\.FaviconOperations\[\$AppKey\], \$operation\)'
        $fetchScript | Should -Match '\$sync\.FaviconOperations\.Remove\(\$AppKey\)'
        $fetchScript | Should -Match '\$powershell\.Dispose\(\)\s+throw'
    }

    It "closes favicon workers when the form closes" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $closeScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Close-WinUtilFaviconRunspacePool.ps1") -Raw

        $mainScript | Should -Match 'Add_Closing\(\{\s+Close-WinUtilFaviconRunspacePool'
        $closeScript | Should -Match '\.Stop\(\)'
        $closeScript | Should -Match 'FaviconCircuitBreaker\.Cancel\(\)'
        $closeScript | Should -Match '\.Dispose\(\)'
        $closeScript | Should -Match 'FaviconRunspace\.Close\(\)'
    }

    It "removes pending favicon requests during shutdown" {
        $previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        try {
            $global:sync = [hashtable]::Synchronized(@{ FaviconQueue = [System.Collections.Queue]::new() })
            $global:sync.FaviconQueue.Enqueue([pscustomobject]@{ AppKey = "PendingApp" })

            Close-WinUtilFaviconRunspacePool

            $global:sync.ContainsKey("FaviconQueue") | Should -BeFalse
        } finally {
            if ($previousSync) {
                Set-Variable -Name sync -Value $previousSync.Value -Scope Global
            } else {
                Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
}
