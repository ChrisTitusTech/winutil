function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Filters the Install tab entries by search text and by category

        .DESCRIPTION
            Search text and categories are independent filters that both have to pass. An entry is
            shown when its name, description, or application preset key matches the search text, and
            when its category is in the selected set. An empty search matches everything, and an empty
            category set matches every category.

            While either filter is active the matching categories are expanded, since a collapsed
            category would otherwise hide the very results that were asked for. With no filter at
            all the collapsed state the user set is restored.

        .PARAMETER SearchString
            The string to search for. Wildcards are treated as literal characters.

        .PARAMETER Categories
            The categories to show. An empty or missing array shows all of them.

        .NOTES
            - Uses module-scope $sync (no parameter needed; inherits from caller's scope)
            - Safely handles missing hashtable keys and null UI elements
            - Protected by try/catch to prevent UI thread crashes
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = "",

        [Parameter(Mandatory = $false)]
        [string[]]$Categories = @()
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

    # Categories that filtering expanded on the user's behalf, so clearing the filter can undo it
    if ($null -eq $sync.AppCategoryAutoExpanded) {
        $sync.AppCategoryAutoExpanded = @{}
    }

    try {
        $activeCategories = @($Categories | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $hasSearch = -not [string]::IsNullOrWhiteSpace($SearchString)
        $hasCategories = $activeCategories.Count -gt 0

        # Nothing is filtered, so put every entry back and leave the collapsed categories collapsed
        if (-not $hasSearch -and -not $hasCategories) {
            $sync.ItemsControl.Items | ForEach-Object {
                $_.Visibility = [Windows.Visibility]::Visible

                if ($_.Children.Count -ge 2) {
                    $categoryLabel = $_.Children[0]
                    $wrapPanel = $_.Children[1]

                    $categoryLabel.Visibility = [Windows.Visibility]::Visible

                    # A category that filtering expanded goes back to how the user left it
                    $categoryName = $categoryLabel.Content -replace '^[+-] ', ''
                    if ($sync.AppCategoryAutoExpanded.ContainsKey($categoryName)) {
                        $categoryLabel.Content = $categoryLabel.Content -replace "^- ", "+ "
                        $sync.AppCategoryAutoExpanded.Remove($categoryName)
                    }

                    if ($categoryLabel.Content -like "+*") {
                        $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                    }
                    else {
                        $wrapPanel.Visibility = [Windows.Visibility]::Visible
                    }

                    $wrapPanel.Children | ForEach-Object {
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                }
            }
            return
        }

        # Escape wildcard characters for literal matching
        $escapedSearchString = [System.Management.Automation.WildcardPattern]::Escape($SearchString)

        $sync.ItemsControl.Items | ForEach-Object {
            # Each item is a StackPanel container with Children[0] = label, Children[1] = WrapPanel
            if ($_.Children.Count -ge 2) {
                $categoryLabel = $_.Children[0]
                $wrapPanel = $_.Children[1]
                $categoryHasMatch = $false

                $categoryLabel.Visibility = [Windows.Visibility]::Visible

                foreach ($appControl in $wrapPanel.Children) {
                    $appTag = $appControl.Tag
                    $appEntry = $null

                    if (-not [string]::IsNullOrWhiteSpace($appTag) -and $sync.configs.applicationsHashtable.ContainsKey($appTag)) {
                        $appEntry = $sync.configs.applicationsHashtable[$appTag]
                    }

                    if ($null -ne $appEntry) {
                        $categoryMatch = -not $hasCategories -or $activeCategories -contains $appEntry.Category
                        $textMatch = -not $hasSearch -or
                            $appEntry.Content -like "*$escapedSearchString*" -or
                            $appEntry.Description -like "*$escapedSearchString*" -or
                            $appTag -like "*$escapedSearchString*"

                        if ($categoryMatch -and $textMatch) {
                            $appControl.Visibility = [Windows.Visibility]::Visible
                            $categoryHasMatch = $true
                        }
                        else {
                            $appControl.Visibility = [Windows.Visibility]::Collapsed
                        }
                    }
                    else {
                        # Hide app if no entry found (data integrity issue)
                        $appControl.Visibility = [Windows.Visibility]::Collapsed
                    }
                }

                if ($categoryHasMatch) {
                    $wrapPanel.Visibility = [Windows.Visibility]::Visible
                    $_.Visibility = [Windows.Visibility]::Visible
                    # Expand it, otherwise the matches stay hidden behind a collapsed header.
                    # Remember that it was collapsed so clearing the filter can put it back.
                    if ($categoryLabel.Content -like "+*") {
                        $categoryLabel.Content = $categoryLabel.Content -replace "^\+ ", "- "
                        $sync.AppCategoryAutoExpanded[($categoryLabel.Content -replace '^- ', '')] = $true
                    }
                }
                else {
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
