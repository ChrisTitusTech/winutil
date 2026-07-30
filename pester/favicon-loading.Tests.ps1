BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilFaviconUrl.ps1")
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
        $poolScript | Should -Match '\[Math\]::Max\(\$halfProcessors, 2\)'
        $poolScript | Should -Match '\[Math\]::Min\(\$maxThreads, 8\)'
        $poolScript | Should -Match 'CreateRunspacePool'
    }

    It "downloads favicon bytes without assigning a network URL to the WPF image" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $fetchScript | Should -Match 'WebRequest\]::Create'
        $fetchScript | Should -Match 'AddScript'
        $fetchScript | Should -Match 'ServicePoint\.ConnectionLimit = \$connectionLimit'
        $fetchScript | Should -Match 'FaviconRunspace\.GetMaxRunspaces\(\)'
        $fetchScript | Should -Match 'return ,\$memoryStream\.ToArray\(\)'
        $entryScript | Should -Match 'Get-WinUtilFaviconUrl -Link \$app\.link'
        $entryScript | Should -Match 'Invoke-WinUtilFaviconFetch -AppKey \$appKey'
        $entryScript | Should -Not -Match '\$logo\.Source = "https://www\.google\.com/s2/favicons'
    }

    It "keeps byte arrays returned directly from a runspace" {
        $pool = [runspacefactory]::CreateRunspacePool(1, 1)
        $pool.Open()
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $pool
        [void]$powershell.AddScript({
            $bytes = [byte[]](1, 2, 3, 4)
            return ,$bytes
        })

        try {
            $handle = $powershell.BeginInvoke()
            $results = @($powershell.EndInvoke($handle))

            $results.Count | Should -Be 1
            $results[0].GetType() | Should -Be ([byte[]])
            ([byte[]]$results[0]).Length | Should -Be 4
            [Convert]::ToBase64String([byte[]]$results[0]) | Should -Be "AQIDBA=="
        } finally {
            $powershell.Dispose()
            $pool.Close()
            $pool.Dispose()
        }
    }

    It "applies results and fallback state through the WPF dispatcher" {
        $fetchScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFaviconFetch.ps1") -Raw

        $fetchScript | Should -Match 'DispatcherTimer'
        $fetchScript | Should -Match 'Handle\.IsCompleted'
        $fetchScript | Should -Match '\$Operation\.Bytes = \[byte\[\]\]\$results\[0\]'
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
        $closeScript | Should -Match '\.Dispose\(\)'
        $closeScript | Should -Match 'FaviconRunspace\.Close\(\)'
    }
}
