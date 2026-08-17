function Invoke-WinUtilUILanguage {
    <#
    .SYNOPSIS
        Walks the window's visual tree and replaces static string text with the
        current language translation, or restores the English key when switching
        back to English. Idempotent: text that matches nothing is left untouched.

    .NOTES
        The forward pass records each translated control's original text in its
        Uid property (unused by the XAML in this project). The reverse pass
        restores from that record first, so distinct controls that share one
        translation (e.g. "Documentation" and "Document" both translate to 文档)
        come back to their own English key instead of the first key seen in the
        non-injective reverse table. Controls created after the forward pass
        fall back to the reverse table.
    #>

    $stack = [System.Collections.Generic.Stack[object]]::new()
    $stack.Push($sync.Form)

    while ($stack.Count -gt 0) {
        $node = $stack.Pop()
        if ($null -eq $node) { continue }

        try {
        # Reverse mode: English target, translated text needs restoring.
        $reverseMode = $null -eq $sync.TextTable -and $null -ne $sync.ReverseTextTable

        # TextBlock: translate in two stages against the mixed key shapes in
        # i18n.json. Stage 1 looks up the whole content joined without a
        # separator (tab buttons "Install", USB warning). Stage 2 falls back to
        # per-LineBreak-segment lookups and rejoins with newlines, keeping
        # untranslated segments in the original text. When nothing translates,
        # the text is left untouched so inline styling such as the tab
        # underline survives. In reverse mode a recorded Uid wins over the
        # reverse table so per-control English keys are restored exactly.
        if ($node -is [System.Windows.Controls.TextBlock]) {
            if ($reverseMode -and -not [string]::IsNullOrEmpty($node.Uid) -and $node.Text -ne $node.Uid) {
                $node.Inlines.Clear()
                $node.Text = $node.Uid
            } else {
                $segments = New-Object System.Collections.Generic.List[string]
                if ($node.Inlines -and $node.Inlines.Count -gt 0) {
                    # Text set by XAML or code lives in the first inline Run, so
                    # only the Inlines are collected. Literal newlines (from a
                    # previous stage-2 rejoin or code-set text) are split back into
                    # segments so each line resolves against its own key.
                    foreach ($segment in (Get-WinUtilInlineSegments $node.Inlines)) {
                        foreach ($sub in ($segment -split "`n")) { $segments.Add($sub) }
                    }
                } elseif (-not [string]::IsNullOrWhiteSpace($node.Text)) {
                    # Text-only TextBlock (Inlines cleared after a previous pass).
                    # In reverse mode the text was joined with newlines, so split
                    # it back into segments so each one resolves to its English key.
                    if ($reverseMode) {
                        foreach ($segment in ($node.Text -split "`n")) {
                            $segments.Add($segment)
                        }
                    } else {
                        $segments.Add($node.Text)
                    }
                }

                if ($segments.Count -gt 0) {
                    $fullText = $segments -join ""
                    $translatedFull = if ($fullText) { Get-WinUtilLanguageText $fullText } else { $fullText }
                    if ($translatedFull -ne $fullText) {
                        # Clear before set: with non-empty Inlines (e.g. an Underline
                        # span in the tab buttons) the Text setter takes a slow path
                        # and Text/Inlines stay desynced, so clearing afterwards
                        # leaves the getter returning empty text.
                        if (-not $reverseMode -and [string]::IsNullOrEmpty($node.Uid)) {
                            $node.Uid = $segments -join ""
                        }
                        $node.Inlines.Clear()
                        $node.Text = $translatedFull
                    } else {
                        # Empty segments stay empty — Get-WinUtilLanguageText
                        # rejects them.
                        $translatedSegments = @(foreach ($segment in $segments) {
                            if ([string]::IsNullOrEmpty($segment)) { $segment } else { Get-WinUtilLanguageText $segment }
                        })
                        $changed = $false
                        for ($i = 0; $i -lt $segments.Count; $i++) {
                            if ($translatedSegments[$i] -ne $segments[$i]) { $changed = $true; break }
                        }
                        if ($changed) {
                            if (-not $reverseMode -and [string]::IsNullOrEmpty($node.Uid)) {
                                $node.Uid = $segments -join "`n"
                            }
                            $node.Inlines.Clear()
                            $node.Text = $translatedSegments -join "`n"
                        }
                    }
                }
            }
        }

        # Content-typed controls with string content
        if ($node.Content -is [string] -and
            $node -is [System.Windows.Controls.ContentControl] -and
            $node -isnot [System.Windows.Controls.TextBox]) {
            $original = [string]$node.Content
            $translated = if ($reverseMode -and -not [string]::IsNullOrEmpty($node.Uid)) {
                [string]$node.Uid
            } else {
                Get-WinUtilLanguageText $original
            }
            if ($translated -ne $original) {
                if (-not $reverseMode -and [string]::IsNullOrEmpty($node.Uid)) {
                    $node.Uid = $original
                }
                $node.Content = $translated
            }
        }

        # MenuItem Header / TabItem Header
        if (($node -is [System.Windows.Controls.MenuItem] -or $node -is [System.Windows.Controls.TabItem]) -and
            $node.Header -is [string]) {
            $original = [string]$node.Header
            $translated = if ($reverseMode -and -not [string]::IsNullOrEmpty($node.Uid)) {
                [string]$node.Uid
            } else {
                Get-WinUtilLanguageText $original
            }
            if ($translated -ne $original) {
                if (-not $reverseMode -and [string]::IsNullOrEmpty($node.Uid)) {
                    $node.Uid = $original
                }
                $node.Header = $translated
            }
        }

        # ToolTip: string property, or ToolTip object with string Content
        if ($node.ToolTip -is [string]) {
            $node.ToolTip = Get-WinUtilLanguageText $node.ToolTip
        } elseif ($node.ToolTip -is [System.Windows.Controls.ToolTip] -and $node.ToolTip.Content -is [string]) {
            $toolTip = $node.ToolTip
            $original = [string]$toolTip.Content
            $translated = if ($reverseMode -and -not [string]::IsNullOrEmpty($toolTip.Uid)) {
                [string]$toolTip.Uid
            } else {
                Get-WinUtilLanguageText $original
            }
            if ($translated -ne $original) {
                if (-not $reverseMode -and [string]::IsNullOrEmpty($toolTip.Uid)) {
                    $toolTip.Uid = $original
                }
                $toolTip.Content = $translated
            }
        }

        # AutomationProperties.Name (accessibility name)
        $autoName = [System.Windows.Automation.AutomationProperties]::GetName($node)
        if (-not [string]::IsNullOrWhiteSpace($autoName)) {
            [System.Windows.Automation.AutomationProperties]::SetName($node, (Get-WinUtilLanguageText $autoName))
        }

        # Descend: Content element, Children, Items (TabItem lives in Items, not
        # Children), Child (Decorator like Border, and Popup).
        if ($node.Content -and $node.Content -isnot [string] -and $node.Content -is [System.Windows.DependencyObject]) {
            $stack.Push($node.Content)
        }
        if ($node.Children) {
            foreach ($child in $node.Children) { $stack.Push($child) }
        }
        if ($node.Items) {
            foreach ($item in $node.Items) { $stack.Push($item) }
        }
        if ($node.Child -and $node.Child -is [System.Windows.DependencyObject]) {
            $stack.Push($node.Child)
        }
        } catch {
            Write-WinUtilLog -Component "i18n" -Message "Traversal error at $($node.GetType().Name): $_"
        }
    }
}
