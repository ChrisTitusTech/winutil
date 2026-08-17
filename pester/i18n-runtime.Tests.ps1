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

    It "translates the leading line of mixed content text" {
        # XamlReader collapses the XML whitespace: "Edition  :" becomes
        # "Edition :", and the Text property carries only the leading line,
        # which is exactly the i18n.json key.
        $xaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TextWrapping="Wrap">
                                            - Edition  : Windows 11
                                            <LineBreak/>- Language : your preferred language
                                        </TextBlock>
"@
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "- 版本：Windows 11"
    }

    It "translates Text plus Inlines content as one key" {
        # A TextBlock with both a Text attribute and inline content reports the
        # merged text in .Text; the translation replaces it wholesale.
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="HEAD">tail<LineBreak/>more</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "混合译文"
    }

    It "flattens Run plus LineBreak plus Run with no separator" {
        # Mirrors the USB warning shape: <Run/><LineBreak/>text. LineBreak
        # contributes no separator, matching the generated i18n.json key.
        $xaml = '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"><Run>AAA</Run><LineBreak/>BBB</TextBlock>'
        $tb = [System.Windows.Markup.XamlReader]::Parse($xaml)
        $sync.Form = New-Object System.Windows.Window
        $sync.Form.Content = $tb
        Apply-WinUtilUILanguage
        $tb.Text | Should -Be "拼接译文"
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
        # Setting Text rebuilds the Inlines as a single Run; a second pass must
        # not re-clear or re-translate it.
        $tb.Inlines.Count | Should -Be 1
        $tb.Inlines[0].Text | Should -Be "安装"
    }
}
