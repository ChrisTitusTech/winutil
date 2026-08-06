function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the Apps on the Install Tab and hides all entries that do not match the string

        .DESCRIPTION
            Filters application entries by name or description using literal string matching.
            Respects collapsed category state and handles null $sync gracefully.

        .PARAMETER SearchString
            The string to be searched for. Wildcards are treated as literal characters.

        .PARAMETER Category
            When provided, only applications in this exact category are shown.

        .NOTES
            - Uses module-scope $sync (no parameter needed; inherits from caller's scope)
            - Performs literal matching (no wildcard expansion)
            - Safely handles missing hashtable keys and null UI elements
            - Protected by try/catch to prevent UI thread crashes
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = "",

        [Parameter(Mandatory = $false)]
        [string]$Category = ""
    )

    # Validate that $sync exists and has required structure
    if ($null -eq $sync) {
        Write-Warning "Find-AppsByNameOrDescription: Global `$sync not found. Aborting search."
        return
    }

    if ($null -eq $sync.ItemsControl) {
        Write-Warning "Find-AppsByNameOrDescription: `$sync.ItemsControl not initialized. Aborting search."
        return
    }

    if ($null -eq $sync.configs -or $null -eq $sync.configs.applicationsHashtable) {
        Write-Warning "Find-AppsByNameOrDescription: `$sync.configs.applicationsHashtable not initialized. Aborting search."
        return
    }

    try {
        # Reset the visibility if the search string is empty or the search is cleared
        if ([string]::IsNullOrWhiteSpace($SearchString) -and [string]::IsNullOrWhiteSpace($Category)) {
            $sync.ItemsControl.Items | ForEach-Object {
                # Each item is a StackPanel container
                $_.Visibility = [Windows.Visibility]::Visible

                if ($_.Children.Count -ge 2) {
                    $categoryLabel = $_.Children[0]
                    $wrapPanel = $_.Children[1]

                    # Keep category label visible
                    $categoryLabel.Visibility = [Windows.Visibility]::Visible

                    # Respect the collapsed state of categories (indicated by + prefix)
                    if ($categoryLabel.Content -like "+*") {
                        $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                    }
                    else {
                        $wrapPanel.Visibility = [Windows.Visibility]::Visible
                    }

                    # Show all apps within the category
                    $wrapPanel.Children | ForEach-Object {
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                }
            }
            return
        }

        # IndexOf with OrdinalIgnoreCase is faster than -like with wildcard escaping
        $sync.ItemsControl.Items | ForEach-Object {
            if ($_.Children.Count -ge 2) {
                $categoryLabel = $_.Children[0]
                $wrapPanel = $_.Children[1]
                $categoryHasMatch = $false
                $categoryLabel.Visibility = [Windows.Visibility]::Visible
                $isCategoryFilter = -not [string]::IsNullOrWhiteSpace($Category)

                foreach ($appControl in $wrapPanel.Children) {
                    $appTag = $appControl.Tag
                    $appEntry = $null
                    if (-not [string]::IsNullOrWhiteSpace($appTag) -and $sync.configs.applicationsHashtable.ContainsKey($appTag)) {
                        $appEntry = $sync.configs.applicationsHashtable[$appTag]
                    }

                    if ($null -ne $appEntry) {
                        $matched = $false
                        if ($isCategoryFilter) {
                            $matched = $appEntry.Category -eq $Category
                        } else {
                            $matched = ([string]$appEntry.Content).IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                                       ([string]$appEntry.Description).IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                        }

                        if ($matched) {
                            $appControl.Visibility = [Windows.Visibility]::Visible
                            $categoryHasMatch = $true
                        } else {
                            $appControl.Visibility = [Windows.Visibility]::Collapsed
                        }
                    } else {
                        $appControl.Visibility = [Windows.Visibility]::Collapsed
                    }
                }

                # If category has matches, show the WrapPanel and update the category label to expanded state
                if ($categoryHasMatch) {
                    $wrapPanel.Visibility = [Windows.Visibility]::Visible
                    $_.Visibility = [Windows.Visibility]::Visible
                    # Update category label to show expanded state (-)
                    if ($categoryLabel.Content -like "+*") {
                        $categoryLabel.Content = $categoryLabel.Content -replace "^\+ ", "- "
                    }
                }
                else {
                    # Hide the entire category container if no matches
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }
    }
    catch {
        Write-Warning "Find-AppsByNameOrDescription: An error occurred during search: $_"
        # Fail gracefully - do not crash the UI thread
        return
    }
}
