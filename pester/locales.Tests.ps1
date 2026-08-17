#===========================================================================
# Tests - Locales (i18n)
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilText.ps1")
    $sync = [hashtable]::Synchronized(@{})
}

Describe "i18n config" {
    It "contains zh-CN with meta and strings" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $i18n."zh-CN" | Should -Not -BeNullOrEmpty
        $i18n."zh-CN".meta.code | Should -Be "zh-CN"
        $i18n."zh-CN".meta.name | Should -Be "简体中文"
        $i18n."zh-CN".strings | Should -Not -BeNullOrEmpty
    }

    It "has no empty translation values" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
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

Describe "zh-CN coverage of static XAML text" {
    It "covers every visible XAML string" {
        $xaml = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw -Encoding UTF8
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $strings = $i18n."zh-CN".strings
        $covered = @($strings.PSObject.Properties.Name)
        $missing = New-Object System.Collections.Generic.List[string]

        # Tab button inline text, e.g. "<Underline>I</Underline>nstall" -> "Install".
        # The full match contains the underline and TextBlock tags; strip them so
        # the accent letter and the rest combine back into the visible text.
        # Already-covered keys (Install/Tweaks/Config/Updates/Win11 Creator) are
        # skipped like the attribute scan below, otherwise this would never pass.
        [regex]::Matches($xaml, '<Underline>[^<]+</Underline>([^<]+)</TextBlock>') | ForEach-Object {
            $text = ($_.Groups[0].Value -replace '<Underline>|</Underline>|</TextBlock>', '').Trim()
            if ($text -and $covered -notcontains $text -and $missing -notcontains $text) { $missing.Add("tab:$text") }
        }

        # String-valued attributes: Text, Content, ToolTip, Header, Title
        foreach ($pattern in @('Text="([^"]+)"', 'Content="([^"]+)"', 'ToolTip="([^"]+)"', 'Header="([^"]+)"', 'Title="([^"]+)"')) {
            [regex]::Matches($xaml, $pattern) | ForEach-Object {
                $value = $_.Groups[1].Value
                # "100%" is the font-scaling slider's live percentage display, updated by code, not a translatable label
                if ($value -eq "" -or $value -like "&#x*" -or $value -like "{*" -or $value -eq "X" -or $value -eq "N/A" -or $value -eq "WinUtil" -or $value -eq "100%") { return }
                $value = $value.Replace("&amp;", "&").Replace("&lt;", "<").Replace("&gt;", ">")
                if ($covered -notcontains $value -and $missing -notcontains $value) {
                    $missing.Add($value)
                }
            }
        }

        if ($missing.Count -gt 0) {
            throw "XAML text not covered by zh-CN: $($missing -join ' | ')"
        }
    }
}
