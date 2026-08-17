#===========================================================================
# Tests - Locales (i18n)
#===========================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilText.ps1")
    $sync = [hashtable]::Synchronized(@{})
}

Describe "i18n config" {
    It "contains zh-CN with meta and strings" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw | ConvertFrom-Json
        $i18n."zh-CN" | Should -Not -BeNullOrEmpty
        $i18n."zh-CN".meta.code | Should -Be "zh-CN"
        $i18n."zh-CN".meta.name | Should -Be "简体中文"
        $i18n."zh-CN".strings | Should -Not -BeNullOrEmpty
    }

    It "has no empty translation values" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw | ConvertFrom-Json
        foreach ($string in $i18n."zh-CN".strings.PSObject.Properties) {
            [string]$string.Value | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Get-WinUtilText" {
    It "returns the original string when no language is active" {
        $sync.TextTable = $null
        Get-WinUtilText -String "Run Tweaks" | Should -Be "Run Tweaks"
    }

    It "returns the translation when the key exists" {
        $sync.TextTable = @{ "Run Tweaks" = "运行调整" }
        Get-WinUtilText -String "Run Tweaks" | Should -Be "运行调整"
    }

    It "falls back to the original string when the key is missing" {
        $sync.TextTable = @{ "Run Tweaks" = "运行调整" }
        Get-WinUtilText -String "Something Untranslated" | Should -Be "Something Untranslated"
    }
}
