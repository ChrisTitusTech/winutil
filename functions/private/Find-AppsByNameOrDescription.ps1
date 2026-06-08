function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the Apps on the Install Tab and hides all entries that do not match the string

        .DESCRIPTION
            Filters application entries by name or description using literal string matching.
            Also supports filtering by FOSS status with 'foss:true' or 'foss:false'.
            Respects collapsed category state and handles null $sync gracefully.

        .PARAMETER SearchString
            The string to be searched for. Wildcards are treated as literal characters.

        .NOTES
            - Uses module-scope $sync (no parameter needed; inherits from caller's scope)
            - Performs literal matching (no wildcard expansion)
            - Safely handles missing hashtable keys and null UI elements
            - Protected by try/catch to prevent UI thread crashes
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = ""
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
        $fossFilter = $null
        $actualSearchString = $SearchString

        if ($SearchString -match "foss:(true|false)") {
            $fossFilter = [bool]::Parse($Matches[1])
            $actualSearchString = $SearchString -replace "foss:(true|false)", ""
        } elseif ($SearchString -eq "foss") {
            $fossFilter = $true
            $actualSearchString = ""
        }

        $actualSearchString = $actualSearchString.Trim()

        # Reset the visibility if the search string is empty or the search is cleared
        if ([string]::IsNullOrWhiteSpace($actualSearchString) -and $null -eq $fossFilter) {
            $sync.ItemsControl.Items | ForEach-Object {
                $_.Visibility = [Windows.Visibility]::Visible
                if ($_.Children.Count -ge 2) {
                    $categoryLabel = $_.Children[0]
                    $wrapPanel = $_.Children[1]
                    $categoryLabel.Visibility = [Windows.Visibility]::Visible
                    if ($categoryLabel.Content -like "+*") {
                        $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                    } else {
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
        $escapedSearchString = [System.Management.Automation.WildcardPattern]::Escape($actualSearchString)

        # Perform search
        $sync.ItemsControl.Items | ForEach-Object {
            if ($_.Children.Count -ge 2) {
                $categoryLabel = $_.Children[0]
                $wrapPanel = $_.Children[1]
                $categoryHasMatch = $false

                $categoryLabel.Visibility = [Windows.Visibility]::Visible

                $wrapPanel.Children | ForEach-Object {
                    $appTag = $_.Tag
                    $appEntry = $null

                    if (-not [string]::IsNullOrWhiteSpace($appTag) -and $sync.configs.applicationsHashtable.ContainsKey($appTag)) {
                        $appEntry = $sync.configs.applicationsHashtable[$appTag]
                    }

                    if ($null -ne $appEntry) {
                        $textMatch = $true
                        if (-not [string]::IsNullOrWhiteSpace($actualSearchString)) {
                            $contentMatch = $appEntry.Content -like "*$escapedSearchString*"
                            $descriptionMatch = $appEntry.Description -like "*$escapedSearchString*"
                            $textMatch = $contentMatch -or $descriptionMatch
                        }

                        $fossMatch = $true
                        if ($null -ne $fossFilter) {
                            $fossMatch = ($appEntry.foss -eq $fossFilter)
                        }

                        if ($textMatch -and $fossMatch) {
                            $_.Visibility = [Windows.Visibility]::Visible
                            $categoryHasMatch = $true
                        } else {
                            $_.Visibility = [Windows.Visibility]::Collapsed
                        }
                    } else {
                        $_.Visibility = [Windows.Visibility]::Collapsed
                    }
                }

                if ($categoryHasMatch) {
                    $wrapPanel.Visibility = [Windows.Visibility]::Visible
                    $_.Visibility = [Windows.Visibility]::Visible
                    if ($categoryLabel.Content -like "+*") {
                        $categoryLabel.Content = $categoryLabel.Content -replace "^\+ ", "- "
                    }
                } else {
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }
    }
    catch {
        Write-Warning "Find-AppsByNameOrDescription: An error occurred during search: $_"
        return
    }
}
