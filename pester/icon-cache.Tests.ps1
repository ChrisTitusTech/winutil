#===========================================================================
# Tests - App icons never reach the network from the interface thread

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    . (Join-Path $script:functionRoot "private\Start-WinUtilIconFetch.ps1")

    $script:cacheRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-icon-tests-$([guid]::NewGuid().ToString('N'))"
    $global:sync = [hashtable]::Synchronized(@{ winutildir = $script:cacheRoot })

    # Stubs so the mocks have something to replace; the real ones live in other files
    function Invoke-WPFRunspace { param($ScriptBlock, $ArgumentList, $ParameterList) }
    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
}

AfterAll {
    if ($script:cacheRoot -and (Test-Path $script:cacheRoot)) {
        Remove-Item $script:cacheRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Icon cache paths" {
    It "creates the cache directory on demand" {
        $dir = Get-WinUtilIconCacheDirectory

        Test-Path $dir | Should -BeTrue
        $dir | Should -BeLike "*icons*"
    }

    It "maps a link to a stable file name" {
        $first = Get-WinUtilIconCacheFile -Link "https://example.com/app"
        $second = Get-WinUtilIconCacheFile -Link "https://example.com/app"

        $first | Should -Be $second
    }

    It "ignores case, so one site is not fetched twice" {
        $lower = Get-WinUtilIconCacheFile -Link "https://Example.com/App"
        $upper = Get-WinUtilIconCacheFile -Link "https://example.com/app"

        $lower | Should -Be $upper
    }

    It "gives different links different files even when the unsafe characters match" {
        # sanitising rather than hashing would collapse these two onto one file
        $a = Get-WinUtilIconCacheFile -Link "https://example.com/a?x=1"
        $b = Get-WinUtilIconCacheFile -Link "https://example.com/a?x=2"

        $a | Should -Not -Be $b
    }

    It "produces a name that is valid on disk" {
        $file = Get-WinUtilIconCacheFile -Link "https://example.com/path?a=1&b=2#frag"
        $name = Split-Path $file -Leaf

        $invalid = [System.IO.Path]::GetInvalidFileNameChars()
        ($name.ToCharArray() | Where-Object { $_ -in $invalid }).Count | Should -Be 0
    }
}

Describe "Icon decoding" {
    It "returns a frozen bitmap, which is what makes it safe to build off the interface thread" {
        $png = [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
        $file = Join-Path (Get-WinUtilIconCacheDirectory) "sample.img"
        [System.IO.File]::WriteAllBytes($file, $png)

        $bitmap = Get-WinUtilFrozenIcon -Path $file

        $bitmap | Should -Not -BeNullOrEmpty
        $bitmap.IsFrozen | Should -BeTrue
    }

    It "returns nothing for a file that is not an image rather than throwing" {
        $file = Join-Path (Get-WinUtilIconCacheDirectory) "broken.img"
        Set-Content -Path $file -Value "this is not a picture"

        Get-WinUtilFrozenIcon -Path $file | Should -BeNullOrEmpty
    }

    It "returns nothing for an empty file" {
        $file = Join-Path (Get-WinUtilIconCacheDirectory) "empty.img"
        [System.IO.File]::WriteAllBytes($file, @())

        Get-WinUtilFrozenIcon -Path $file | Should -BeNullOrEmpty
    }
}

Describe "Icon fetching" {
    It "does nothing when every icon was already cached" {
        $sync.PendingIcons = [hashtable]::Synchronized(@{})
        Mock Invoke-WPFRunspace { }
        Mock Write-WinUtilLog { }

        Start-WinUtilIconFetch

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "hands the pending list to a worker and clears it" {
        $sync.PendingIcons = [hashtable]::Synchronized(@{ "WPFInstallApp" = "https://example.com" })
        Mock Invoke-WPFRunspace { }
        Mock Write-WinUtilLog { }

        Start-WinUtilIconFetch

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly
        # cleared, so a later pass does not queue the same downloads again
        $sync.PendingIcons.Count | Should -Be 0
    }

    It "passes the work as one name and value pair, not a flattened array" {
        # @(("Name", $value)) is a two element array; the worker would then be handed the first
        # two characters of the name and silently do nothing
        $sync.PendingIcons = [hashtable]::Synchronized(@{ "WPFInstallApp" = "https://example.com" })
        Mock Write-WinUtilLog { }
        $captured = $null
        Mock Invoke-WPFRunspace { $script:captured = $ParameterList }

        Start-WinUtilIconFetch

        @($script:captured).Count | Should -Be 1
        @($script:captured)[0][0] | Should -Be "IconWork"
        @($script:captured)[0][1].Count | Should -Be 1
    }
}

