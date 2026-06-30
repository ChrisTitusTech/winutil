function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the Apps on the Install Tab and hides all entries that do not match the string

        .DESCRIPTION
            Filters application entries by name or description using literal string matching.
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
        # Reset the visibility if the search string is empty or the search is cleared
        if ([string]::IsNullOrWhiteSpace($SearchString)) {
            if ($null -ne $sync.SearchResultsWrapPanel) {
                $sync.SearchResultsWrapPanel.Children.Clear(); $Apps = $sync.configs.applicationsHashtable
                $customApps = $sync.selectedApps | Where-Object { $_ -like "WPFInstallCustom_*" }
                $customApps | ForEach-Object { $sync.$_ = Initialize-InstallAppEntry -TargetElement $sync.SearchResultsWrapPanel -appKey $_; $sync.$_.IsChecked = $true }
            }
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
            if ($null -ne $sync.SearchResultsWrapPanel) { $sync.SearchResultsWrapPanel.Parent.Visibility = if ($customApps) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed } }
            return
        }

        # Escape wildcard characters for literal matching
        $escapedSearchString = [System.Management.Automation.WildcardPattern]::Escape($SearchString)
        if ($null -ne $sync.SearchResultsWrapPanel) {
            $sync.SearchResultsWrapPanel.Children.Clear()
            $sync.SearchResultsWrapPanel.Parent.Visibility = [Windows.Visibility]::Collapsed
        }

        # Perform search
        $anyMatch = $false
        $sync.ItemsControl.Items | ForEach-Object {
            # Each item is a StackPanel container with Children[0] = label, Children[1] = WrapPanel
            if ($_.Children.Count -ge 2) {
                $categoryLabel = $_.Children[0]
                $wrapPanel = $_.Children[1]
                $categoryHasMatch = $false

                # Keep category label visible
                $categoryLabel.Visibility = [Windows.Visibility]::Visible

                # Search through apps in this category
                $wrapPanel.Children | ForEach-Object {
                    # Safely retrieve app entry from hashtable
                    $appTag = $_.Tag
                    $appEntry = $null

                    if (-not [string]::IsNullOrWhiteSpace($appTag) -and $sync.configs.applicationsHashtable.ContainsKey($appTag)) {
                        $appEntry = $sync.configs.applicationsHashtable[$appTag]
                    }

                    # Check if app matches search criteria
                    if ($null -ne $appEntry) {
                        $contentMatch = $appEntry.Content -like "*$escapedSearchString*"
                        $descriptionMatch = $appEntry.Description -like "*$escapedSearchString*"

                        if ($contentMatch -or $descriptionMatch) {
                            # Show the App and mark that this category has a match
                            $_.Visibility = [Windows.Visibility]::Visible
                            $categoryHasMatch = $true
                        }
                        else {
                            $_.Visibility = [Windows.Visibility]::Collapsed
                        }
                    }
                    else {
                        # Hide app if no entry found (data integrity issue)
                        $_.Visibility = [Windows.Visibility]::Collapsed
                    }
                }

                # If category has matches, show the WrapPanel and update the category label to expanded state
                if ($categoryHasMatch) {
                    $anyMatch = $true
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
        if (-not $anyMatch -and $SearchString.Length -ge 3) {
            if (-not $sync.PackageSearchCache) { $sync.PackageSearchCache = @{} }; $source = $sync.preferences.packagemanager.ToString(); $q = [uri]::EscapeDataString($SearchString); $cacheKey = "$source|$q"; $appKey = $sync.PackageSearchCache[$cacheKey]
            if (-not $appKey) { $id = $name = $desc = $link = $null
                try {
                    if ($source -eq "Choco") {
                        $entry = @(Invoke-RestMethod -Uri "https://community.chocolatey.org/api/v2/Search()?searchTerm='$q'&targetFramework=''&includePrerelease=false&`$skip=0&`$top=1" -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop)[0]
                        if ($entry) { $id = $entry.title.InnerText; $name = (($entry.properties.ChildNodes | Where-Object { $_.LocalName -eq "Title" } | Select-Object -First 1).InnerText); $desc = $entry.summary.InnerText; $link = "https://community.chocolatey.org/packages/$id" }
                    } else {
                        $json = (Invoke-WebRequest -Uri "https://api.winget.run/v2/packages?query=$q&take=1" -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop).Content
                        $id = [regex]::Match($json, '"Id":"([^"]+)"').Groups[1].Value; $name = [regex]::Match($json, '"Name":"([^"]+)"').Groups[1].Value; $desc = [regex]::Match($json, '"Description":"([^"]*)"').Groups[1].Value; $link = "https://winget.run/pkg/$id"
                    }
                    if (-not $id) { return }
                    if (-not $name) { $name = $id }; if (-not $desc) { $desc = $name }
                    $appKey = "WPFInstallCustom_$($source)_$($id -replace '[^a-zA-Z0-9]', '_')"
                    $sync.configs.applicationsHashtable[$appKey] = [pscustomobject]@{ category="Search Results"; foss=$false; content=$name; description=$desc; link=$link; choco=$(if ($source -eq "Choco") { $id } else { "na" }); winget=$(if ($source -eq "Winget") { $id } else { "na" }) }
                    $sync.PackageSearchCache[$cacheKey] = $appKey
                } catch {}
            }
            if ($appKey) {
                if ($null -eq $sync.SearchResultsWrapPanel) {
                    $Apps = @{}; $Apps[$appKey] = $sync.configs.applicationsHashtable[$appKey]
                    Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $Apps
                    $sync.SearchResultsWrapPanel = $sync.ItemsControl.Items[$sync.ItemsControl.Items.Count - 1].Children[1]
                } else { $Apps = $sync.configs.applicationsHashtable; $sync.$appKey = Initialize-InstallAppEntry -TargetElement $sync.SearchResultsWrapPanel -appKey $appKey }
                if ($sync.selectedApps -contains $appKey) { $sync.$appKey.IsChecked = $true }
                $sync.SearchResultsWrapPanel.Parent.Visibility = $sync.SearchResultsWrapPanel.Visibility = [Windows.Visibility]::Visible
            }
        }
    }
    catch {
        Write-Warning "Find-AppsByNameOrDescription: An error occurred during search: $_"
        # Fail gracefully - do not crash the UI thread
        return
    }
}
