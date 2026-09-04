#===========================================================================
# Tests - Deferred favicon loading

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Add-Type -AssemblyName PresentationFramework

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilFaviconUrl.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconDownload.ps1")

    function Initialize-WinUtilRunspacePool { }
    function Invoke-WPFRunspace {
        param($ScriptBlock, $ArgumentList, $ParameterList)
        $null = $ScriptBlock, $ArgumentList, $ParameterList
    }
    function Test-WinUtilUIAlive { return $true }
}

Describe "WinUtil favicon loading" {
    BeforeEach {
        $script:previousSync = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        $global:sync = [hashtable]::Synchronized(@{})
    }

    AfterEach {
        if ($script:previousSync) {
            Set-Variable -Name sync -Value $script:previousSync.Value -Scope Global
        } else {
            Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It "builds an escaped favicon URL from an application link" {
        Get-WinUtilFaviconUrl -Link "https://example.com/path?a=1&b=2" |
            Should -Be "https://www.google.com/s2/favicons?sz=64&domain_url=https%3A%2F%2Fexample.com%2Fpath%3Fa%3D1%26b%3D2"
    }

    It "keeps remote URLs off WPF image sources during entry rendering" {
        $entrySource = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw
        $renderSource = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $entrySource | Should -Match 'Get-WinUtilFaviconUrl -Link \$app\.link'
        $entrySource | Should -Match '\$sync\.FaviconQueue\.Enqueue'
        $entrySource | Should -Not -Match '\$logo\.Source\s*=\s*"https?://'
        $renderSource | Should -Match '(?s)InstallAppEntriesRendered = \$true.*ApplicationIdle.*Start-WinUtilFaviconLoading'
    }

    It "submits plain request data through a bounded share of the shared pool" {
        $pool = [pscustomobject]@{}
        $pool | Add-Member -MemberType ScriptMethod -Name GetMaxRunspaces -Value { 8 }
        $global:sync.runspace = $pool
        $global:sync.FaviconQueue = [System.Collections.Queue]::new()
        $global:sync.FaviconTargets = [hashtable]::Synchronized(@{})
        $global:sync.FaviconInFlight = 0
        $global:sync.FaviconLoadingStopped = $false
        1..6 | ForEach-Object {
            $global:sync.FaviconQueue.Enqueue([pscustomobject]@{
                AppKey = "App$_"
                Url = "https://example.com/$_"
                TargetImage = [pscustomobject]@{ Visibility = "Collapsed"; Source = $null }
                Fallback = [pscustomobject]@{ Visibility = "Visible" }
            })
        }
        $script:submittedRequests = [System.Collections.Generic.List[object]]::new()
        Mock Initialize-WinUtilRunspacePool { return $global:sync.runspace }
        Mock Invoke-WPFRunspace {
            $script:submittedRequests.Add($ArgumentList)
            return [pscustomobject]@{ Scheduled = $true }
        }

        Request-WinUtilFaviconDownload

        $global:sync.FaviconInFlight | Should -Be 4
        $global:sync.FaviconQueue.Count | Should -Be 2
        $script:submittedRequests.Count | Should -Be 4
        @($script:submittedRequests[0].PSObject.Properties.Name) | Should -Be @("AppKey", "Url")
        Should -Invoke Invoke-WPFRunspace -Times 4 -Exactly
    }

    It "does not submit favicon work while a user job owns the pool" {
        $global:sync.ActiveJob = "Install"
        $global:sync.FaviconQueue = [System.Collections.Queue]::new()
        $global:sync.FaviconTargets = [hashtable]::Synchronized(@{})
        $global:sync.FaviconLoadingStopped = $false
        $global:sync.FaviconQueue.Enqueue([pscustomobject]@{ AppKey = "App" })
        Mock Initialize-WinUtilRunspacePool { }
        Mock Invoke-WPFRunspace { }

        Request-WinUtilFaviconDownload

        $global:sync.FaviconQueue.Count | Should -Be 1
        Should -Invoke Initialize-WinUtilRunspacePool -Times 0 -Exactly
        Should -Invoke Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "opens the circuit after eight completed failures" {
        $global:sync.FaviconQueue = [System.Collections.Queue]::new()
        $global:sync.FaviconQueue.Enqueue([pscustomobject]@{ AppKey = "Pending" })
        $global:sync.FaviconResults = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        $global:sync.FaviconTargets = [hashtable]::Synchronized(@{})
        $global:sync.FaviconInFlight = 8
        $global:sync.FaviconConsecutiveFailures = 0
        $global:sync.FaviconLoadingStopped = $false
        1..8 | ForEach-Object {
            $key = "Failed$_"
            $global:sync.FaviconTargets[$key] = [pscustomobject]@{
                TargetImage = [pscustomobject]@{ Visibility = [Windows.Visibility]::Visible }
                Fallback = [pscustomobject]@{ Visibility = [Windows.Visibility]::Collapsed }
            }
            $global:sync.FaviconResults.Enqueue([pscustomobject]@{
                AppKey = $key
                Status = "NetworkFailure"
                Bytes = $null
            })
        }
        Mock Request-WinUtilFaviconDownload { }

        Receive-WinUtilFaviconResult

        $global:sync.FaviconLoadingStopped | Should -BeTrue
        $global:sync.FaviconConsecutiveFailures | Should -Be 8
        $global:sync.FaviconQueue.Count | Should -Be 0
        $global:sync.FaviconInFlight | Should -Be 0
    }

    It "uses time-bounded worker downloads and publishes no WPF objects" {
        $fetchSource = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconDownload.ps1") -Raw
        $downloadFunction = [regex]::Match(
            $fetchSource,
            '(?s)function Invoke-WinUtilFaviconDownload \{.*?\n\}\n\nfunction Request-WinUtilFaviconDownload'
        ).Value

        $downloadFunction | Should -Match 'Timeout = \$requestTimeoutMilliseconds'
        $downloadFunction | Should -Match 'ReadWriteTimeout = \$requestTimeoutMilliseconds'
        $downloadFunction | Should -Match '\$sync\.FaviconResults\.Enqueue'
        $downloadFunction | Should -Not -Match 'Windows\.Controls|Windows\.Media'
    }
}
