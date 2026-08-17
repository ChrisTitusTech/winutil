#===========================================================================
# Tests - i18n runtime text application
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    # Tests build WPF controls directly; pwsh does not auto-load
    # PresentationFramework, unlike Windows PowerShell's GAC type resolution.
    Add-Type -AssemblyName PresentationFramework
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilText.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilUILanguage.ps1")
    $global:sync = [hashtable]::Synchronized(@{})
    $sync.TextTable = @{
        "Install" = "安装"
        "Run Tweaks" = "运行调整"
        "- Edition : Windows 11" = "- 版本：Windows 11"
        "AAABBB" = "拼接译文"
        "HEADtail" = "混合译文"
        "A" = "甲"
        "B" = "乙"
        "Note: Hover over items to get a better description. Please be careful as many of these tweaks will heavily modify your system." = "注意：悬停查看项目说明。"
        "Recommended selections are for normal users and if you are unsure do NOT check anything else!" = "推荐选择适用于普通用户。"
    }
    # Stash for restoring state in the reverse-restore tests below.
    $script:zhTable = $sync.TextTable
}

Describe "Invoke-WinUtilUILanguage on the real window XAML" {
    It "translates the tab buttons when loaded through XmlNodeReader (slow Text setter path)" {
        # Regression: with non-empty Inlines containing a Span (the tab
        # underline), WPF's Text setter desyncs Text from Inlines, so clearing
        # Inlines after setting Text leaves the getter returning empty. This
        # loads the full window exactly like main.ps1 does.
        [xml]$xaml = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw -Encoding UTF8
        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
        $sync.Form = $window
        # Use the real language pack so the tab keys are present.
        $i18n = Get-Content -Path (Join-Path $script:repoRoot "config\i18n.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $realTable = @{}
        $i18n."zh-CN".strings.PSObject.Properties | ForEach-Object { $realTable[$_.Name] = [string]$_.Value }
        $sync.TextTable = $realTable

        Invoke-WinUtilUILanguage

        $tabNames = @("WPFTab1BT", "WPFTab2BT", "WPFTab3BT", "WPFTab4BT", "WPFTab5BT")
        $expected = @("安装", "调整", "配置", "更新", "Win11 制作")
        for ($i = 0; $i -lt $tabNames.Count; $i++) {
            $textBlock = $window.FindName($tabNames[$i]).Content
            $textBlock.Text | Should -Be $expected[$i]
        }

        # Restore the small fixture table so later tests are not polluted.
        $sync.TextTable = $script:zhTable
    }
}

Describe "Invoke-WinUtilUILanguage runtime traversal" {
    It "translates tab button underline text" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Underline -ArgumentList (New-Object System.Windows.Documents.Run -ArgumentList "I")))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "nstall"))
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "安装"
    }

    It "translates the leading line of mixed content text and keeps the rest" {
        # XamlReader collapses the XML whitespace: "Edition  :" becomes
        # "Edition :" in the first segment. Whole-content lookup misses, so the
        # per-segment stage translates the leading line and rejoins with
        # newlines, keeping the untranslated lines.
        $xaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TextWrapping="Wrap">
                                            - Edition  : Windows 11
                                            <LineBreak/>- Language : your preferred language
                                            <LineBreak/>- Architecture : 64-bit (x64)
                                        </TextBlock>
"@
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "- 版本：Windows 11`n- Language : your preferred language`n- Architecture : 64-bit (x64)"
    }

    It "translates Text plus Inlines content per segment" {
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="HEAD">tail<LineBreak/>more</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "混合译文`nmore"
    }

    It "flattens Run plus LineBreak plus Run with no separator as one key" {
        # Mirrors the USB warning shape: <Run/><LineBreak/>text. The whole
        # content joined without a separator matches the generated key.
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"><Run>AAA</Run><LineBreak/>BBB</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "拼接译文"
    }

    It "translates every LineBreak segment of a mixed-content note" {
        # The Tweaks note shape: each segment has its own key, so stage 2 must
        # translate all of them and rejoin with newlines.
        $xaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Padding="10">
    Note: Hover over items to get a better description. Please be careful as many of these tweaks will heavily modify your system.
    <LineBreak/>Recommended selections are for normal users and if you are unsure do NOT check anything else!
</TextBlock>
"@
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "注意：悬停查看项目说明。`n推荐选择适用于普通用户。"
        # The Text setter rebuilds a single Run holding the text.
        $tb.Inlines.Count | Should -Be 1
    }

    It "translates every segment that has a key" {
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">A<LineBreak/>B</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "甲`n乙"
    }

    It "traverses Border.Child" {
        $sync.Form = New-Object System.Windows.Window
        $border = New-Object System.Windows.Controls.Border
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Run Tweaks"
        $border.Child = $tb
        $sync.Form.Content = $border
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "运行调整"
    }

    It "traverses Popup.Child and translates MenuItem headers" {
        $sync.Form = New-Object System.Windows.Window
        $popup = New-Object System.Windows.Controls.Primitives.Popup
        $border = New-Object System.Windows.Controls.Border
        $stack = New-Object System.Windows.Controls.StackPanel
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Header = "Run Tweaks"
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Run Tweaks"
        $stack.Children.Add($mi) | Out-Null
        $stack.Children.Add($tb) | Out-Null
        $border.Child = $stack
        $popup.Child = $border
        $sync.Form.Content = $popup
        Invoke-WinUtilUILanguage
        $mi.Header | Should -Be "运行调整"
        $tb.Text | Should -Be "运行调整"
    }

    It "translates string ToolTips and ToolTip object content" {
        $sync.Form = New-Object System.Windows.Window
        $tb1 = New-Object System.Windows.Controls.TextBlock
        $tb1.Text = "Run Tweaks"
        $tb1.ToolTip = "Run Tweaks"
        $tb2 = New-Object System.Windows.Controls.TextBlock
        $tb2.Text = "Run Tweaks"
        $tt = New-Object System.Windows.Controls.ToolTip
        $tt.Content = "Run Tweaks"
        $tb2.ToolTip = $tt
        $stack = New-Object System.Windows.Controls.StackPanel
        $stack.Children.Add($tb1) | Out-Null
        $stack.Children.Add($tb2) | Out-Null
        $sync.Form.Content = $stack
        Invoke-WinUtilUILanguage
        $tb1.ToolTip | Should -Be "运行调整"
        $tt.Content | Should -Be "运行调整"
    }

    It "translates string Content on ContentControl" {
        $sync.Form = New-Object System.Windows.Window
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "Run Tweaks"
        $sync.Form.Content = $btn
        Invoke-WinUtilUILanguage
        $btn.Content | Should -Be "运行调整"
    }

    It "is idempotent across repeated runs" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Underline -ArgumentList (New-Object System.Windows.Documents.Run -ArgumentList "I")))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "nstall"))
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "安装"
        # A second pass sees the single Run created by the Text setter and
        # resolves it back to the same translation (idempotent).
        $tb.Inlines.Count | Should -Be 1
    }

    It "leaves inline styling intact when nothing translates" {
        # English mode: empty table, every lookup falls back. The tab underline
        # structure must survive untouched.
        $sync.TextTable = @{}
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Underline -ArgumentList (New-Object System.Windows.Documents.Run -ArgumentList "I")))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "nstall"))
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        # Text was never set and the underline structure survives for styling.
        $tb.Text | Should -Be ""
        $tb.Inlines.Count | Should -Be 2
        $tb.Inlines[0].GetType().Name | Should -Be "Underline"
    }
}

Describe "Invoke-WinUtilUILanguage reverse restore" {
    BeforeEach {
        # The previous describe leaves an empty table; start each scenario from
        # the full Chinese table with no reverse table.
        $sync.TextTable = $script:zhTable
        $sync.ReverseTextTable = $null
    }

    It "restores a whole-text key back to English" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "AAA"))
        $tb.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "BBB"))
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "拼接译文"

        $sync.TextTable = $null
        $sync.ReverseTextTable = @{
            "拼接译文" = "AAABBB"
            "甲" = "A"
            "乙" = "B"
            "运行调整" = "Run Tweaks"
        }
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "AAABBB"
    }

    It "restores every LineBreak segment back to English" {
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">A<LineBreak/>B</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "甲`n乙"

        $sync.TextTable = $null
        $sync.ReverseTextTable = @{
            "拼接译文" = "AAABBB"
            "甲" = "A"
            "乙" = "B"
            "运行调整" = "Run Tweaks"
        }
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "A`nB"
    }

    It "is idempotent across repeated reverse runs" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "AAA"))
        $tb.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "BBB"))
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "拼接译文"

        $sync.TextTable = $null
        $sync.ReverseTextTable = @{
            "拼接译文" = "AAABBB"
            "甲" = "A"
            "乙" = "B"
            "运行调整" = "Run Tweaks"
        }
        Invoke-WinUtilUILanguage
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "AAABBB"
    }

    It "restores string Content and ToolTip in reverse mode" {
        $sync.Form = New-Object System.Windows.Window
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "Run Tweaks"
        $btn.ToolTip = "Run Tweaks"
        $sync.Form.Content = $btn
        Invoke-WinUtilUILanguage
        $btn.Content | Should -Be "运行调整"
        $btn.ToolTip | Should -Be "运行调整"

        $sync.TextTable = $null
        $sync.ReverseTextTable = @{
            "拼接译文" = "AAABBB"
            "甲" = "A"
            "乙" = "B"
            "运行调整" = "Run Tweaks"
        }
        Invoke-WinUtilUILanguage
        $btn.Content | Should -Be "Run Tweaks"
        $btn.ToolTip | Should -Be "Run Tweaks"
    }

    It "leaves English text untouched when the reverse table has no entry" {
        $sync.TextTable = $null
        $sync.ReverseTextTable = @{
            "运行调整" = "Run Tweaks"
        }
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Untranslated English Text"
        $sync.Form.Content = $tb
        Invoke-WinUtilUILanguage
        $tb.Text | Should -Be "Untranslated English Text"
    }
}
