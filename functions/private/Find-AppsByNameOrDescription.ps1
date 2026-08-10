function Get-WinUtilPackageLink {
    <#
        .SYNOPSIS
            Resolves a website/domain link for a package manager package ID to enable favicon icon loading.
            Uses dynamic querying of the package manager to avoid hardcoded lookups.
    #>
    param(
        [string]$PackageId,
        [string]$Manager = "Winget"
    )

    if ([string]::IsNullOrWhiteSpace($PackageId)) { return "https://github.com" }

    if ($null -ne $sync -and $null -eq $sync.PackageLinkCache) {
        $sync.PackageLinkCache = [Hashtable]::Synchronized(@{})
    }

    $cacheKey = "$($Manager)_$PackageId"
    if ($null -ne $sync -and $sync.PackageLinkCache.ContainsKey($cacheKey)) {
        return $sync.PackageLinkCache[$cacheKey]
    }

    $url = $null
    $publisher = ($PackageId -split '\.')[0]
    if ($publisher.Length -gt 1 -and $publisher -match '^[a-zA-Z0-9\-]+$') {
        $url = "https://$($publisher.ToLowerInvariant()).com"
    }
    else {
        $url = "https://github.com"
    }

    if ($null -ne $sync) {
        $sync.PackageLinkCache[$cacheKey] = $url
    }
    return $url
}

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

    if ($null -eq $sync -or $null -eq $sync.ItemsControl -or $null -eq $sync.configs -or $null -eq $sync.configs.applicationsHashtable) {
        Write-Warning "Find-AppsByNameOrDescription: Missing required sync state or ItemsControl."
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
                if ($null -ne $_.PSObject.Properties['Tag'] -and $_.Tag -eq "CategoryContainer_PackageManagerResults") {
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
                else {
                    # Each item is a StackPanel container
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
            }
            return
        }

        # IndexOf with OrdinalIgnoreCase is faster than -like with wildcard escaping
        $sync.ItemsControl.Items | ForEach-Object {
            if ($null -ne $_.PSObject.Properties['Tag'] -and $_.Tag -eq "CategoryContainer_PackageManagerResults") {
                return
            }

            if ($_.Children.Count -ge 2) {
                $categoryLabel = $_.Children[0]
                $wrapPanel = $_.Children[1]
                $categoryHasMatch = $false
                $categoryLabel.Visibility = [Windows.Visibility]::Visible

                if ($null -ne $wrapPanel.Children) {
                    foreach ($appControl in $wrapPanel.Children) {
                        $appTag = if ($null -ne $appControl.PSObject.Properties['Tag']) { $appControl.Tag } else { $null }
                        $appEntry = if ($appTag -and $sync.configs.applicationsHashtable.ContainsKey($appTag)) { $sync.configs.applicationsHashtable[$appTag] } else { $null }

                    if ($null -ne $appEntry) {
                        $categoryMatch = -not $hasCategories -or $activeCategories -contains $appEntry.Category
                        $textMatch = -not $hasSearch -or
                            ([string]$appEntry.Content).IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                            ([string]$appEntry.Description).IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                            ([string]$appTag).IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0

                        if ($categoryMatch -and $textMatch) {
                            $appControl.Visibility = [Windows.Visibility]::Visible
                            $categoryHasMatch = $true
                        } else {
                            $appControl.Visibility = [Windows.Visibility]::Collapsed
                        }
                    }
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

        # 2. Query package manager repositories for non-curated apps
        if (-not [string]::IsNullOrWhiteSpace($SearchString) -and -not $hasCategories) {
            $manager = if ($null -ne $sync.preferences -and $null -ne $sync.preferences.packagemanager) { $sync.preferences.packagemanager } else { "Winget" }
            $sync.LatestPackageManagerSearch = $SearchString

            if ($null -eq $sync.PackageManagerSearchCache) {
                $sync.PackageManagerSearchCache = [Hashtable]::Synchronized(@{})
            }

            $sync.UpdatePackageManagerUI = {
                param($finalResults, $Manager, $SearchString)

                if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }

                # Cache the results
                $sync.PackageManagerSearchCache["${SearchString}_${Manager}"] = $finalResults

                # Only update the UI if the results are for the currently selected manager
                $currentManager = if ($null -ne $sync.preferences -and $null -ne $sync.preferences.packagemanager) { $sync.preferences.packagemanager } else { "Winget" }
                if ($Manager -ne $currentManager) { return }

                # Locate or create Package Manager Results category container
                $pmContainer = $null
                foreach ($item in $sync.ItemsControl.Items) {
                    if ($null -ne $item.PSObject.Properties['Tag'] -and $item.Tag -eq "CategoryContainer_PackageManagerResults") {
                        $pmContainer = $item
                        break
                    }
                }

                if ($null -eq $pmContainer -and $finalResults.Count -gt 0) {
                    $pmContainer = New-Object System.Windows.Controls.StackPanel
                    $pmContainer.Orientation = "Vertical"
                    $pmContainer.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
                    $pmContainer.Margin = New-Object Windows.Thickness(0, 0, 0, 0)
                    $pmContainer.Tag = "CategoryContainer_PackageManagerResults"
                    
                    if ("System.Windows.Automation.AutomationProperties" -as [type]) {
                        try { [System.Windows.Automation.AutomationProperties]::SetName($pmContainer, "Package Manager Results Container") } catch {}
                    }

                    if ("Windows.Data.Binding" -as [type]) {
                        $binding = New-Object Windows.Data.Binding
                        $binding.Path = New-Object Windows.PropertyPath("ActualWidth")
                        $binding.RelativeSource = New-Object Windows.Data.RelativeSource([Windows.Data.RelativeSourceMode]::FindAncestor, [Windows.Controls.ItemsControl], 1)
                        try { [void][Windows.Data.BindingOperations]::SetBinding($pmContainer, [Windows.FrameworkElement]::WidthProperty, $binding) } catch {}
                    }

                    $lbl = New-Object System.Windows.Controls.Label
                    $lbl.Content = "- Package Manager Results"
                    $lbl.Tag = "CategoryToggleButton_PM"
                    if ("Windows.Controls.Control" -as [type]) {
                        $lbl.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
                        $lbl.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
                        $lbl.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "LabelboxForegroundColor")
                    }
                    if ("System.Windows.Input.Cursors" -as [type]) {
                        $lbl.Cursor = [System.Windows.Input.Cursors]::Hand
                    }
                    $lbl.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch

                    $lbl.Add_MouseLeftButtonUp({
                        param($toggle)
                        $c = $toggle.Parent
                        if ($c -and $c.Children.Count -ge 2) {
                            $wp = $c.Children[1]
                            if ($wp.Visibility -eq [Windows.Visibility]::Visible) {
                                $wp.Visibility = [Windows.Visibility]::Collapsed
                                $toggle.Content = $toggle.Content -replace "^- ", "+ "
                            } else {
                                $wp.Visibility = [Windows.Visibility]::Visible
                                $toggle.Content = $toggle.Content -replace "^\+ ", "- "
                            }
                        }
                    })

                    if ($null -ne $pmContainer.Children) { $null = $pmContainer.Children.Add($lbl) }

                    $pmWrap = New-Object System.Windows.Controls.WrapPanel
                    $pmWrap.Orientation = "Horizontal"
                    $pmWrap.HorizontalAlignment = "Left"
                    $pmWrap.VerticalAlignment = "Top"
                    $pmWrap.Margin = New-Object Windows.Thickness(0, 0, 0, 0)
                    $pmWrap.Visibility = [Windows.Visibility]::Visible
                    $pmWrap.Tag = "CategoryWrapPanel_PackageManagerResults"

                    if ($null -ne $pmContainer.Children) { $null = $pmContainer.Children.Add($pmWrap) }
                    if ($null -ne $sync.ItemsControl.Items) { $null = $sync.ItemsControl.Items.Add($pmContainer) }
                }

                if ($null -ne $pmContainer) {
                    $pmWrap = $pmContainer.Children[1]
                    if ($null -ne $pmWrap -and $null -ne $pmWrap.Children) {
                        # Remove stale UI elements
                        $staleUI = @()
                        foreach ($c in $pmWrap.Children) {
                            if ($c.Tag -like "WPFInstall_dynamic_*") { $staleUI += $c }
                        }
                        foreach ($s in $staleUI) {
                            $pmWrap.Children.Remove($s)
                        }
                        
                        # Remove stale hashtable entries
                        $staleKeys = @()
                        foreach ($k in $sync.configs.applicationsHashtable.Keys) {
                            if ($k -like "WPFInstall_dynamic_*") { 
                                if ($null -ne $sync.selectedApps -and $sync.selectedApps.Contains($k)) {
                                    continue
                                }
                                $staleKeys += $k
                            }
                        }
                        foreach ($sk in $staleKeys) {
                            $sync.configs.applicationsHashtable.Remove($sk)
                        }
                    }

                    if ($finalResults.Count -gt 0) {
                        $pmContainer.Visibility = [Windows.Visibility]::Visible
                        if ($null -ne $pmWrap) { $pmWrap.Visibility = [Windows.Visibility]::Visible }

                        foreach ($res in $finalResults) {
                            $appKey = "WPFInstall_dynamic_$($Manager.ToLower())_$($res.Id -replace '[^a-zA-Z0-9_]', '_')"

                            if (-not $sync.configs.applicationsHashtable.ContainsKey($appKey)) {
                                $sync.configs.applicationsHashtable[$appKey] = [pscustomobject]@{
                                    category    = "Package Manager Results"
                                    content     = "$($res.Name) ($Manager)"
                                    description = "Package ID: $($res.Id) ($Manager)"
                                    winget      = if ($Manager -eq "Winget") { $res.Id } else { "na" }
                                    choco       = if ($Manager -eq "Choco") { $res.Id } else { "na" }
                                    link        = $res.LinkUrl
                                    foss        = $false
                                    isDynamic   = $true
                                }
                            }

                            $ctrl = $null
                            if ($null -ne $pmWrap -and $null -ne $pmWrap.Children) {
                                foreach ($c in $pmWrap.Children) {
                                    if ($null -ne $c.PSObject.Properties['Tag'] -and $c.Tag -eq $appKey) {
                                        $ctrl = $c
                                        break
                                    }
                                }
                            }

                            if ($null -eq $ctrl) {
                                if (Get-Command Initialize-InstallAppEntry -ErrorAction SilentlyContinue) {
                                    $sync.$appKey = Initialize-InstallAppEntry -TargetElement $pmWrap -appKey $appKey
                                }
                            }
                            else {
                                $ctrl.Visibility = [Windows.Visibility]::Visible
                            }
                        }
                    }
                    else {
                        $pmContainer.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }

            if ($sync.PackageManagerSearchCache.ContainsKey("${SearchString}_${manager}")) {
                & $sync.UpdatePackageManagerUI -finalResults $sync.PackageManagerSearchCache["${SearchString}_${manager}"] -Manager $manager -SearchString $SearchString
            }
            else {
                foreach ($item in $sync.ItemsControl.Items) {
                    if ($null -ne $item.PSObject.Properties['Tag'] -and $item.Tag -eq "CategoryContainer_PackageManagerResults") {
                        $item.Visibility = [Windows.Visibility]::Collapsed
                        break
                    }
                }
            }

            if (Get-Command Invoke-WPFRunspace -ErrorAction SilentlyContinue) {
                # Multi-thread: Spawn searches for both Winget and Choco
                foreach ($mgr in @("Winget", "Choco")) {
                    if (-not $sync.PackageManagerSearchCache.ContainsKey("${SearchString}_${mgr}")) {
                        Invoke-WPFRunspace -ParameterList @(
                            @("SearchString", $SearchString),
                            @("Manager", $mgr)
                        ) -ScriptBlock {
                            param($SearchString, $Manager)

                            if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }

                            $pmResults = @()
                            if (Get-Command Find-WinUtilPackageManagerApps -ErrorAction SilentlyContinue) {
                                $pmResults = @(Find-WinUtilPackageManagerApps -SearchString $SearchString -ManagerPreference $Manager)
                            }

                            if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }

                            # deduplicate against curated catalog package IDs and app keys
                            $curatedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                            foreach ($key in $sync.configs.applicationsHashtable.Keys) {
                                $entry = $sync.configs.applicationsHashtable[$key]
                                if ($entry.isDynamic -ne $true) {
                                    if ($entry.winget) {
                                        $w = ($entry.winget -replace '^msstore:', '').Trim()
                                        if ($w -and $w -ne "na") { [void]$curatedIds.Add($w) }
                                    }
                                    if ($entry.choco) {
                                        $c = $entry.choco.Trim()
                                        if ($c -and $c -ne "na") { [void]$curatedIds.Add($c) }
                                    }
                                    if ($key) { [void]$curatedIds.Add($key) }
                                }
                            }

                            $newResults = @(foreach ($res in $pmResults) { if (-not $curatedIds.Contains($res.Id)) { $res } })

                            if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }

                            $finalResults = @()
                            $limit = [Math]::Min($newResults.Count, 15)
                            for ($i = 0; $i -lt $limit; $i++) {
                                if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }
                                $res = $newResults[$i]
                                $linkUrl = ""
                                if (Get-Command Get-WinUtilPackageLink -ErrorAction SilentlyContinue) {
                                    $linkUrl = Get-WinUtilPackageLink -PackageId $res.Id -Manager $Manager
                                }
                                $finalResults += [pscustomobject]@{
                                    Id = $res.Id
                                    Name = $res.Name
                                    LinkUrl = $linkUrl
                                }
                            }

                            if ($sync.LatestPackageManagerSearch -ne $SearchString) { return }

                            $dispatcher = $null
                            if ($null -ne $sync.ItemsControl -and $null -ne $sync.ItemsControl.Dispatcher) {
                                $dispatcher = $sync.ItemsControl.Dispatcher
                            }
                            elseif ($null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher) {
                                $dispatcher = $sync.Form.Dispatcher
                            }

                            if ($null -ne $dispatcher) {
                                $action = [System.Action[System.Object, System.Object, System.Object]] {
                                    param($fResults, $mgr, $sString)
                                    if ($sync.LatestPackageManagerSearch -ne $sString) { return }
                                    & $sync.UpdatePackageManagerUI -finalResults $fResults -Manager $mgr -SearchString $sString
                                }
                                $dispatcher.Invoke($action, [object[]]@($finalResults, $Manager, $SearchString))
                            }
                            elseif ($null -ne $sync.MockedTest -and $sync.MockedTest) {
                                & $sync.UpdatePackageManagerUI -finalResults $finalResults -Manager $Manager -SearchString $SearchString
                            }
                        } | Out-Null
                    }
                }
            }
        }
        else {
            if ($null -ne $sync.ItemsControl -and $null -ne $sync.ItemsControl.Items) {
                foreach ($item in $sync.ItemsControl.Items) {
                    if ($null -ne $item.PSObject.Properties['Tag'] -and $item.Tag -eq "CategoryContainer_PackageManagerResults") {
                        $item.Visibility = [Windows.Visibility]::Collapsed
                        break
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Find-AppsByNameOrDescription: Search error: $_"
    }
}
