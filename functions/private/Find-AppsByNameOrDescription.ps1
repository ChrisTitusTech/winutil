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
        $sync.ItemsControl.Items | ForEach-Object {
            $_.Visibility = [Windows.Visibility]::Visible
            $_.Children | ForEach-Object {
                if ($null -ne $_) {
                    # Respect the collapsed state of categories (indicated by + prefix)
                    if ($_.Tag -like "CategoryToggleButton" -and $_.Content -like "+*") {
                        # Keep category label visible but don't expand the WrapPanel
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                    elseif ($_.Tag -like "CategoryWrapPanel_*") {
                        # Check if parent category is collapsed (has + prefix)
                        $categoryLabel = $_.Parent.Children[0]
                        if ($categoryLabel.Content -like "+*") {
                            # Keep collapsed
                            $_.Visibility = [Windows.Visibility]::Collapsed
                        } else {
                            # Expand
                            $_.Visibility = [Windows.Visibility]::Visible
                        }
                    }
                    else {
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                }

            }
        }
        return
    }
    $sync.ItemsControl.Items | ForEach-Object {
        # Ensure ToggleButtons remain visible
        if ($_.Tag -like "CategoryToggleButton") {
            $_.Visibility = [Windows.Visibility]::Visible
            return
        }
        # Hide all CategoryWrapPanel and ToggleButton
        $_.Visibility = [Windows.Visibility]::Collapsed
        if ($_.Tag -like "CategoryWrapPanel_*") {
            $categoryHasMatch = $false
            # Search for Apps that match the search string
            $_.Children | Foreach-Object {
                $appEntry = $sync.configs.applicationsHashtable.$($_.Tag)
                if ($appEntry.Content -like "*$SearchString*" -or $appEntry.Description -like "*$SearchString*") {
                    # Show the App and mark that this category has a match
                    $_.Visibility = [Windows.Visibility]::Visible
                    $categoryHasMatch = $true
                }
                else {
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
            }

            # If category has matches, show the WrapPanel and update the category label to expanded state
            if ($categoryHasMatch) {
                $_.Visibility = [Windows.Visibility]::Visible
                # Update category label to show expanded state (-)
                $categoryLabel = $_.Parent.Children[0]
                if ($categoryLabel.Content -like "+*") {
                    $categoryLabel.Content = $categoryLabel.Content -replace "^\+ ", "- "
                }
            }
        }
    }
}
