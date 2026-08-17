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

function Apply-WinUtilUILanguage {
    <#
    .SYNOPSIS
        Walks the window's visual tree and replaces static string text with the
        current language translation. Idempotent: already-translated text is not
        a dictionary key, so it is left untouched.
    #>

    $stack = [System.Collections.Generic.Stack[object]]::new()
    $stack.Push($sync.Form)

    while ($stack.Count -gt 0) {
        $node = $stack.Pop()
        if ($null -eq $node) { continue }

        # TextBlock: translate in two stages against the mixed key shapes in
        # i18n.json. Stage 1 looks up the whole content joined without a
        # separator (tab buttons "Install", USB warning). Stage 2 falls back to
        # per-LineBreak-segment lookups and rejoins with newlines, keeping
        # untranslated segments (e.g. "Note: Hover over items ..." plus a second
        # line that has no key). Untranslated text is left untouched so inline
        # styling such as the tab underline survives.
        if ($node -is [System.Windows.Controls.TextBlock] -and
            $node.Inlines -and $node.Inlines.Count -gt 0) {
            $segments = Get-WinUtilInlineSegments $node.Inlines
            $fullText = $segments -join ""

            $translatedFull = Get-WinUtilText $fullText
            if ($translatedFull -ne $fullText) {
                $node.Text = $translatedFull
                $node.Inlines.Clear()
            } else {
                $translatedSegments = @(foreach ($segment in $segments) { Get-WinUtilText $segment })
                $changed = $false
                for ($i = 0; $i -lt $segments.Count; $i++) {
                    if ($translatedSegments[$i] -ne $segments[$i]) { $changed = $true; break }
                }
                if ($changed) {
                    $node.Text = $translatedSegments -join "`n"
                    $node.Inlines.Clear()
                }
            }
        }

        # Content-typed controls with string content
        if ($node.Content -is [string] -and
            $node -is [System.Windows.Controls.ContentControl] -and
            $node -isnot [System.Windows.Controls.TextBox]) {
            $node.Content = Get-WinUtilText $node.Content
        }

        # MenuItem Header / TabItem Header
        if (($node -is [System.Windows.Controls.MenuItem] -or $node -is [System.Windows.Controls.TabItem]) -and
            $node.Header -is [string]) {
            $node.Header = Get-WinUtilText $node.Header
        }

        # ToolTip: string property, or ToolTip object with string Content
        if ($node.ToolTip -is [string]) {
            $node.ToolTip = Get-WinUtilText $node.ToolTip
        } elseif ($node.ToolTip -is [System.Windows.Controls.ToolTip] -and $node.ToolTip.Content -is [string]) {
            $node.ToolTip.Content = Get-WinUtilText $node.ToolTip.Content
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
    }
}
