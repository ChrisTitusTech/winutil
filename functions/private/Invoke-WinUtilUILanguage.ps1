function Get-WinUtilInlineSegments {
    <#
    .SYNOPSIS
        Splits an InlineCollection's text into segments at LineBreak boundaries.
        Run contributes its Text; Span subclasses (Underline/Bold/Italic)
        contribute their nested Inlines recursively. LineBreak ends a segment and
        contributes no text itself, so joining the segments back together has no
        separator — matching the generated i18n.json keys (e.g. the USB warning
        key "!! All data ... !!Select a removable ...").
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Inlines
    )

    $segments = New-Object System.Collections.Generic.List[string]
    $current = [System.Text.StringBuilder]::new()
    foreach ($inline in $Inlines) {
        if ($inline -is [System.Windows.Documents.LineBreak]) {
            $segments.Add($current.ToString())
            $current = [System.Text.StringBuilder]::new()
        } elseif ($inline -is [System.Windows.Documents.Run]) {
            $null = $current.Append($inline.Text)
        } elseif ($inline -is [System.Windows.Documents.Span] -and $inline.Inlines.Count -gt 0) {
            $subSegments = Get-WinUtilInlineSegments $inline.Inlines
            $null = $current.Append($subSegments[0])
            for ($i = 1; $i -lt $subSegments.Count; $i++) {
                $segments.Add($current.ToString())
                $current = [System.Text.StringBuilder]::new()
                $null = $current.Append($subSegments[$i])
            }
        }
    }
    $segments.Add($current.ToString())
    # Unary comma keeps the collection intact through the pipeline: a bare
    # return would enumerate a single-segment list down to a plain string and
    # break index semantics in the caller.
    return ,$segments
}

function Get-WinUtilLanguageText {
    <#
    .SYNOPSIS
        Resolves a string against the current language state. With an active
        TextTable it translates forward (English key -> translated text). With
        no TextTable but a ReverseTextTable (switching back to English) it
        translates backward (translated text -> English key). Falls back to the
        original string when nothing matches.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ($null -ne $sync.TextTable -and $sync.TextTable.Count -gt 0) {
        if ($sync.TextTable.ContainsKey($Text)) {
            return $sync.TextTable[$Text]
        }
        return $Text
    }

    if ($null -ne $sync.ReverseTextTable -and $sync.ReverseTextTable.ContainsKey($Text)) {
        return $sync.ReverseTextTable[$Text]
    }

    return $Text
}

function Invoke-WinUtilUILanguage {
    <#
    .SYNOPSIS
        Walks the window's visual tree and replaces static string text with the
        current language translation, or restores the English key when switching
        back to English. Idempotent: text that matches nothing is left untouched.
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
        # underline survives.
        if ($node -is [System.Windows.Controls.TextBlock]) {
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
                        $node.Inlines.Clear()
                        $node.Text = $translatedSegments -join "`n"
                    }
                }
            }
        }

        # Content-typed controls with string content
        if ($node.Content -is [string] -and
            $node -is [System.Windows.Controls.ContentControl] -and
            $node -isnot [System.Windows.Controls.TextBox]) {
            $node.Content = Get-WinUtilLanguageText $node.Content
        }

        # MenuItem Header / TabItem Header
        if (($node -is [System.Windows.Controls.MenuItem] -or $node -is [System.Windows.Controls.TabItem]) -and
            $node.Header -is [string]) {
            $node.Header = Get-WinUtilLanguageText $node.Header
        }

        # ToolTip: string property, or ToolTip object with string Content
        if ($node.ToolTip -is [string]) {
            $node.ToolTip = Get-WinUtilLanguageText $node.ToolTip
        } elseif ($node.ToolTip -is [System.Windows.Controls.ToolTip] -and $node.ToolTip.Content -is [string]) {
            $node.ToolTip.Content = Get-WinUtilLanguageText $node.ToolTip.Content
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
