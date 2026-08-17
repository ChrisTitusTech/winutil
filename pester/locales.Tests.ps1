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
        # The two groups restore the full text (accent letter + rest). Already-covered
        # keys (Install/Tweaks/Config/Updates/Win11 Creator) are skipped like the
        # attribute scan below, otherwise this would never pass.
        [regex]::Matches($xaml, '<Underline>([^<]+)</Underline>([^<]+)</TextBlock>') | ForEach-Object {
            $text = ($_.Groups[1].Value + $_.Groups[2].Value).Trim()
            if ($text -and $covered -notcontains $text) { $missing.Add("tab:$text") }
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

        # TextBlock content: bare text nodes and Run text, split by LineBreak into
        # per-segment keys like the runtime fallback. Whitespace is collapsed the
        # way XAML parsing does (segments trimmed, runs of whitespace folded to a
        # single space). Icon-only glyphs (e.g. "&#xE721;") have no letters or
        # digits and are not translatable.
        [xml]$xamlDoc = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw -Encoding UTF8
        foreach ($tb in $xamlDoc.SelectNodes('//*[local-name()="TextBlock"]')) {
            $segments = New-Object System.Collections.Generic.List[string]
            $current = ""
            foreach ($child in $tb.ChildNodes) {
                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Text) {
                    $current += $child.InnerText
                } elseif ($child.LocalName -eq "LineBreak") {
                    if ($current.Trim()) { $segments.Add($current) }
                    $current = ""
                } elseif ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    # InnerText includes nested Run/Underline text
                    $current += $child.InnerText
                }
            }
            if ($current.Trim()) { $segments.Add($current) }
            foreach ($segment in $segments) {
                $folded = [regex]::Replace($segment.Trim(), '\s+', ' ')
                if ($folded -and $folded -match '[A-Za-z0-9]' -and $covered -notcontains $folded -and $missing -notcontains $folded) {
                    $missing.Add($folded)
                }
            }
        }

        if ($missing.Count -gt 0) {
            throw "XAML text not covered by zh-CN: $($missing -join ' | ')"
        }
    }
}

Describe "zh-CN coverage of config-driven text" {
    It "covers Content and Description of tweaks, features, appx, appnavigation" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $covered = @($i18n."zh-CN".strings.PSObject.Properties.Name)
        $missing = New-Object System.Collections.Generic.List[string]

        foreach ($name in @("tweaks", "feature", "appx", "appnavigation")) {
            $cfg = Get-Content -Path (Join-Path $script:repoRoot "config\$name.json") -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($entry in $cfg.PSObject.Properties) {
                $values = @()
                if ($entry.Value.Content) { $values += $entry.Value.Content }
                if ($entry.Value.Description) { $values += $entry.Value.Description }
                foreach ($value in $values) {
                    if ($value -is [array]) {
                        foreach ($item in $value) { if ($item -and $covered -notcontains $item) { $missing.Add("$name/$($entry.Name):$item") } }
                    } elseif ($value -and $covered -notcontains $value) {
                        $missing.Add("$name/$($entry.Name):$value")
                    }
                }
            }
        }

        if ($missing.Count -gt 0) {
            throw "Config text not covered by zh-CN: $($missing -join ' | ')"
        }
    }

    It "covers application descriptions and all categories" {
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $covered = @($i18n."zh-CN".strings.PSObject.Properties.Name)
        $missing = New-Object System.Collections.Generic.List[string]

        $apps = Get-Content -Path (Join-Path $script:repoRoot "config\applications.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($entry in $apps.PSObject.Properties) {
            if ($entry.Value.description -and $covered -notcontains $entry.Value.description) {
                $missing.Add("applications/$($entry.Name):$($entry.Value.description)")
            }
        }

        foreach ($name in @("tweaks", "feature", "applications")) {
            $cfg = Get-Content -Path (Join-Path $script:repoRoot "config\$name.json") -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($entry in $cfg.PSObject.Properties) {
                $cat = $entry.Value.category
                if ($cat -and $covered -notcontains $cat) { $missing.Add("$name/category:$cat") }
            }
        }

        if ($missing.Count -gt 0) {
            throw "Application text/categories not covered by zh-CN: $($missing -join ' | ')"
        }
    }
}
