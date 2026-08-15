function Set-WinUtilAppCategoryFilter {
    <#
        .SYNOPSIS
            Applies the Install tab category filter and syncs the chip states to it

        .DESCRIPTION
            The selection lives in $sync.SelectedAppCategories. An empty selection means every
            category is shown, which is what the All chip represents. The category filter and the
            search box are independent: this only touches categories, and the current search text
            is reapplied on top.

        .PARAMETER Category
            The category to act on. An empty value clears the filter back to All.

        .PARAMETER Additive
            Toggles this category in or out of the current selection instead of replacing it.
            Bound to ctrl click.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Category = "",

        [Parameter(Mandatory = $false)]
        [switch]$Additive
    )

    if ($null -eq $sync.SelectedAppCategories) {
        $sync.SelectedAppCategories = [System.Collections.Generic.List[string]]::new()
    }
    $selected = $sync.SelectedAppCategories

    if ([string]::IsNullOrWhiteSpace($Category)) {
        $selected.Clear()
    } elseif ($Additive) {
        if ($selected.Contains($Category)) {
            [void]$selected.Remove($Category)
        } else {
            $selected.Add($Category)
        }
    } elseif ($selected.Count -eq 1 -and $selected.Contains($Category)) {
        # Clicking the only active category again clears the filter
        $selected.Clear()
    } else {
        $selected.Clear()
        $selected.Add($Category)
    }

    Update-WinUtilAppCategoryChip
    Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Categories $selected.ToArray()
}
