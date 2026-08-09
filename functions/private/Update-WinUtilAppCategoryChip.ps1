function Update-WinUtilAppCategoryChip {
    <#
        .SYNOPSIS
            Pushes the current category selection onto the Install tab filter chips

        .DESCRIPTION
            The chips are toggle buttons, so their checked state has to follow the selection
            rather than whatever the last click did to them. The All chip is checked when no
            category is selected.
    #>
    $selected = $sync.SelectedAppCategories
    if ($null -eq $selected) { return }

    foreach ($chip in $sync.AppCategoryChips) {
        $control = $sync[$chip.Name]
        if ($null -eq $control) { continue }
        $control.IsChecked = if ($chip.Category) { $selected.Contains($chip.Category) } else { $selected.Count -eq 0 }
    }
}
