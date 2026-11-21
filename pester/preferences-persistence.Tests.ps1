#===========================================================================
# Tests - Persisted preferences (theme, package manager, language)
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilPreferences.ps1")
}

Describe "Preference persistence" {
    BeforeEach {
        $script:testRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilPrefs_$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null
        $script:sync = [Hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            preferences = @{}
        })
        $global:sync = $script:sync
    }

    AfterEach {
        if (Test-Path $script:testRoot) { Remove-Item $script:testRoot -Recurse -Force }
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "uses defaults when no saved file exists" {
        Get-WinUtilPreferences -Defaults @{ theme = "Auto"; packagemanager = "Winget"; language = "en" }
        $script:sync.preferences.theme | Should -Be "Auto"
        $script:sync.preferences.packagemanager | Should -Be "Winget"
        $script:sync.preferences.language | Should -Be "en"
    }

    It "saves and reloads preferences from disk" {
        Get-WinUtilPreferences -Defaults @{ theme = "Auto"; packagemanager = "Winget"; language = "en" }
        $script:sync.preferences.language = "de"
        $script:sync.preferences.theme = "Dark"
        $script:sync.preferences.packagemanager = "Choco"
        Save-WinUtilPreferences

        $path = Join-Path $script:testRoot "preferences.json"
        Test-Path $path | Should -BeTrue

        $script:sync.preferences = @{}
        Get-WinUtilPreferences -Defaults @{ theme = "Auto"; packagemanager = "Winget"; language = "en" }
        $script:sync.preferences.language | Should -Be "de"
        $script:sync.preferences.theme | Should -Be "Dark"
        $script:sync.preferences.packagemanager | Should -Be "Choco"
    }

    It "falls back to defaults for a malformed file" {
        Set-Content -Path (Join-Path $script:testRoot "preferences.json") -Value "not json" -Encoding UTF8
        Get-WinUtilPreferences -Defaults @{ theme = "Auto"; packagemanager = "Winget"; language = "en" }
        $script:sync.preferences.language | Should -Be "en"
    }

    It "saves language on change and loads it at startup" {
        $localeScript = Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1"
        $main = Get-Content (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $main | Should -Match 'Get-WinUtilPreferences'
        $langSource = Get-Content $localeScript -Raw
        $langSource | Should -Match 'Save-WinUtilPreferences'
    }
}
