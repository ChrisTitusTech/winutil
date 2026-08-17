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
