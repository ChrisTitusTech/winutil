function Get-WinUtilInlineText {
    <#
    .SYNOPSIS
        Flattens an InlineCollection to plain text. Run contributes its Text;
        Span subclasses (Underline/Bold/Italic) contribute their nested Inlines
        recursively; LineBreak and anything else contribute nothing. The
        no-separator concat matches how i18n.json keys were generated for
        inline-only content (e.g. the USB warning: Run + LineBreak + Run becomes
        one key with no separator).
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Inlines
    )

    $sb = [System.Text.StringBuilder]::new()
    foreach ($inline in $Inlines) {
        if ($inline -is [System.Windows.Documents.Run]) {
            $null = $sb.Append($inline.Text)
        } elseif ($inline -is [System.Windows.Documents.Span] -and $inline.Inlines.Count -gt 0) {
            $null = $sb.Append((Get-WinUtilInlineText $inline.Inlines))
        }
    }
    return $sb.ToString()
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

        # TextBlock: direct Text, or Inlines (e.g. tab buttons "<Underline>I</Underline>nstall").
        # When Text is set it holds the text XamlReader produced — for mixed
        # content that is the leading line, which is exactly what the i18n.json
        # key contains. Inline-only content is flattened (Run text, nested Span
        # inlines, LineBreak adds no separator), translated, and replaced with
        # plain Text.
        if ($node -is [System.Windows.Controls.TextBlock]) {
            if (-not [string]::IsNullOrWhiteSpace($node.Text)) {
                $node.Text = Get-WinUtilText $node.Text
            } elseif ($node.Inlines -and $node.Inlines.Count -gt 0) {
                $fullText = Get-WinUtilInlineText $node.Inlines
                if ($fullText) {
                    $node.Text = Get-WinUtilText $fullText
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
