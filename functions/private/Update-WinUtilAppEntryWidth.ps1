function Update-WinUtilAppEntryWidth {
    <#
        .SYNOPSIS
            Stretches the app cards so every row on the Install tab fills the available width

        .DESCRIPTION
            AppEntryWidth is the narrowest a card may be. The number of columns that fit at that
            width is worked out for the width the list actually has, and the cards share the row
            equally. Every card reads one dynamic resource, so a resize is a single assignment.
    #>

    # The items control sits directly in the list's scroll viewer
    $viewer = if ($sync.ItemsControl) { $sync.ItemsControl.Parent }
    if (-not $viewer -or $viewer.ViewportWidth -le 0) {
        return
    }

    $minimum = [double]$sync.Form.Resources["AppEntryWidth"]
    $spacing = ([Windows.Thickness]$sync.Form.Resources["AppEntryMargin"]).Left * 2
    $columns = [Math]::Max(1, [Math]::Floor($viewer.ViewportWidth / ($minimum + $spacing)))
    $width = [double]([Math]::Floor($viewer.ViewportWidth / $columns) - $spacing)

    if ($sync.Form.Resources["AppEntryCardWidth"] -ne $width) {
        $sync.Form.Resources["AppEntryCardWidth"] = $width
    }
}