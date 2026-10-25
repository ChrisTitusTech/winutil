function Get-WinUtilAppEntryFromElement {
    <#
        .SYNOPSIS
            Finds the app entry (card) an element on the Install tab belongs to

        .PARAMETER Element
            The element an event came from, such as an icon, a name or the card itself

        .OUTPUTS
            The nearest border tagged with an app key, or nothing when the element is not in a card
    #>
    param($Element)

    while ($null -ne $Element) {
        if ($Element -is [Windows.Controls.Border] -and $Element.Tag -is [string] -and $Element.Tag.StartsWith("WPFInstall")) {
            return $Element
        }
        $Element = if ($Element -is [Windows.Media.Visual]) {
            [Windows.Media.VisualTreeHelper]::GetParent($Element)
        } else {
            [Windows.LogicalTreeHelper]::GetParent($Element)
        }
    }
}