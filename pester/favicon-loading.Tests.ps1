BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Add-Type -AssemblyName PresentationFramework
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilFaviconUrl.ps1")
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

    It "uses a dedicated pool capped between two and eight workers" {
        $poolScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilFaviconRunspacePool.ps1") -Raw

        $poolScript | Should -Match '\[Environment\]::ProcessorCount / 2'
        $poolScript | Should -Match '\$minimumWorkers = 2'
        $poolScript | Should -Match '\$maximumWorkers = 8'
        $poolScript | Should -Match '\[Math\]::Max\(\$halfProcessors, \$minimumWorkers\)'
        $poolScript | Should -Match '\[Math\]::Min\(\$maxThreads, \$maximumWorkers\)'
        $poolScript | Should -Match 'CreateRunspacePool'
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
        $entryScript | Should -Match 'Invoke-WinUtilFaviconFetch -AppKey \$appKey'
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
        $fetchScript | Should -Match '\$circuitBreaker\.ReportSuccess\(\)'
        $fetchScript | Should -Match '\$circuitBreaker\.ReportFailure\(\)'
        $fetchScript | Should -Match '\$failureThreshold = 8'
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

    It "closes favicon workers when the form closes" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $closeScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Close-WinUtilFaviconRunspacePool.ps1") -Raw

        $mainScript | Should -Match 'Add_Closing\(\{\s+Close-WinUtilFaviconRunspacePool'
        $closeScript | Should -Match '\.Stop\(\)'
        $closeScript | Should -Match 'FaviconCircuitBreaker\.Cancel\(\)'
        $closeScript | Should -Match '\.Dispose\(\)'
        $closeScript | Should -Match 'FaviconRunspace\.Close\(\)'
    }
}
