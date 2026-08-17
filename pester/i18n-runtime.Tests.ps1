#===========================================================================
# Tests - i18n runtime text application
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilText.ps1")
    . (Join-Path $script:repoRoot "functions\private\Apply-WinUtilUILanguage.ps1")
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
}

Describe "Apply-WinUtilUILanguage runtime traversal" {
    It "translates tab button underline text" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Underline -ArgumentList (New-Object System.Windows.Documents.Run -ArgumentList "I")))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "nstall"))
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
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
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "- 版本：Windows 11`n- Language : your preferred language`n- Architecture : 64-bit (x64)"
    }

    It "translates Text plus Inlines content per segment" {
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="HEAD">tail<LineBreak/>more</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "混合译文`nmore"
    }

    It "flattens Run plus LineBreak plus Run with no separator as one key" {
        # Mirrors the USB warning shape: <Run/><LineBreak/>text. The whole
        # content joined without a separator matches the generated key.
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"><Run>AAA</Run><LineBreak/>BBB</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
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
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "注意：悬停查看项目说明。`n推荐选择适用于普通用户。"
        $tb.Inlines.Count | Should -Be 0
    }

    It "translates every segment that has a key" {
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">A<LineBreak/>B</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "甲`n乙"
    }

    It "traverses Border.Child" {
        $sync.Form = New-Object System.Windows.Window
        $border = New-Object System.Windows.Controls.Border
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Run Tweaks"
        $border.Child = $tb
        $sync.Form.Content = $border
        Apply-WinUtilUILanguage
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
        Apply-WinUtilUILanguage
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
        Apply-WinUtilUILanguage
        $tb1.ToolTip | Should -Be "运行调整"
        $tt.Content | Should -Be "运行调整"
    }

    It "translates string Content on ContentControl" {
        $sync.Form = New-Object System.Windows.Window
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "Run Tweaks"
        $sync.Form.Content = $btn
        Apply-WinUtilUILanguage
        $btn.Content | Should -Be "运行调整"
    }

    It "is idempotent across repeated runs" {
        $sync.Form = New-Object System.Windows.Window
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Inlines.Add((New-Object System.Windows.Documents.Underline -ArgumentList (New-Object System.Windows.Documents.Run -ArgumentList "I")))
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run -ArgumentList "nstall"))
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "安装"
        # A second pass sees no Inlines and must not touch anything.
        $tb.Inlines.Count | Should -Be 0
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
        Apply-WinUtilUILanguage
        # Text was never set and the underline structure survives for styling.
        $tb.Text | Should -Be ""
        $tb.Inlines.Count | Should -Be 2
        $tb.Inlines[0].GetType().Name | Should -Be "Underline"
    }
}
