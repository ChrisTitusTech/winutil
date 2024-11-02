function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the Apps on the Install Tab and hides all entries that do not match the string

        .PARAMETER SearchString
            The string to be searched for
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$SearchString = ""
    )
    # Reset the visibility if the search string is empty or the search is cleared
    if ([string]::IsNullOrWhiteSpace($SearchString)) {
            Set-CategoryVisibility -Category "*"
            return
    }
    $sync.ItemsControl.Items | ForEach-Object {
        # Hide all CategoryWrapPanel and ToggleButton
        $_.Visibility = [Windows.Visibility]::Collapsed
        if ($_.Tag -like "CategoryWrapPanel_*") {
            # Search for Apps that match the search string
            $_.Children | Foreach-Object {
                if ($sync.configs.applicationsHashtable.$($_.Tag).Content -like "*$SearchString*") {
                    # Show the App and the parent CategoryWrapPanel if the string is found
                    $_.Visibility = [Windows.Visibility]::Visible
                    $_.parent.Visibility = [Windows.Visibility]::Visible
                }
                else {
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }
    }
}
