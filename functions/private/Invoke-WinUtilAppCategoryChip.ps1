function Invoke-WinUtilAppCategoryChip {
    <#
        .SYNOPSIS
            Handles a click on an Install tab category chip

        .DESCRIPTION
            The chip carries its category in Tag, so every chip shares this handler. Holding ctrl
            adds the category to the current selection instead of replacing it.

        .PARAMETER Chip
            The chip that was clicked
    #>
    param(
        [Parameter(Mandatory)]
        $Chip
    )

    $ctrlDown = [bool]([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Control)
    Set-WinUtilAppCategoryFilter -Category $Chip.Tag -Additive:$ctrlDown
}
