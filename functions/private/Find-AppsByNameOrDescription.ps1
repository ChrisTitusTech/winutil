function Find-AppsByNameOrDescription {
    <#
        .SYNOPSIS
            Enhanced search function that works with both original and responsive app layouts.
            Searches through the Apps on the Install Tab and hides all entries that do not match the string.

        .PARAMETER SearchString
            The string to be searched for
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$SearchString = ""
    )

    # Determine layout type and target element
    $layoutInfo = Get-LayoutInfo
    if (-not $layoutInfo.TargetElement) {
        Write-Warning "Could not find ItemsControl for applications search"
        return
    }

    # Handle empty search string
    if ([string]::IsNullOrWhiteSpace($SearchString)) {
        Reset-AppVisibility -LayoutInfo $layoutInfo
        Invoke-WPFPackageManagerFilter
        return
    }

    # Perform search based on layout type
    Search-Apps -LayoutInfo $layoutInfo -SearchString $SearchString
}

#region Layout Detection

function Get-LayoutInfo {
    <#
        .SYNOPSIS
            Determines the layout type and returns layout information.

        .OUTPUTS
            Hashtable containing layout information
    #>

    $layoutInfo = @{
        TargetElement = $null
        IsResponsive = $false
    }

    if ($sync.ItemsControl) {
        $layoutInfo.TargetElement = $sync.ItemsControl
        $layoutInfo.IsResponsive = $sync.ItemsControl -is [Windows.Controls.StackPanel]
    }

    return $layoutInfo
}

#endregion

#region Search Operations

function Search-Apps {
    <#
        .SYNOPSIS
            Performs search based on layout type.
    #>
    param($LayoutInfo, $SearchString)

    if ($LayoutInfo.IsResponsive) {
        Search-AppsResponsiveLayout -TargetElement $LayoutInfo.TargetElement -SearchString $SearchString
    } else {
        Search-AppsTraditionalLayout -TargetElement $LayoutInfo.TargetElement -SearchString $SearchString
    }
}

function Reset-AppVisibility {
    <#
        .SYNOPSIS
            Resets all app visibility based on layout type.
    #>
    param($LayoutInfo)

    if ($LayoutInfo.IsResponsive) {
        Show-AllAppsResponsive -TargetElement $LayoutInfo.TargetElement
    } else {
        Show-AllAppsTraditional -TargetElement $LayoutInfo.TargetElement
    }
}

#endregion

#region Responsive Layout Handlers

function Show-AllAppsResponsive {
    <#
        .SYNOPSIS
            Shows all apps in responsive layout.
    #>
    param($TargetElement)

    foreach ($categorySection in $TargetElement.Children) {
        if ($categorySection -is [Windows.Controls.StackPanel]) {
            $categorySection.Visibility = [Windows.Visibility]::Visible

            foreach ($child in $categorySection.Children) {
                $child.Visibility = [Windows.Visibility]::Visible

                $wrapPanel = Get-WrapPanelFromChild -Child $child
                if ($wrapPanel) {
                    foreach ($appItem in $wrapPanel.Children) {
                        $appItem.Visibility = [Windows.Visibility]::Visible
                    }
                }
            }
        }
    }
}

function Search-AppsResponsiveLayout {
    <#
        .SYNOPSIS
            Searches apps in responsive layout with performance optimizations.
    #>
    param($TargetElement, $SearchString)

    $currentFilter = Get-CurrentPackageFilter

    foreach ($categorySection in $TargetElement.Children) {
        if ($categorySection -is [Windows.Controls.StackPanel]) {
            $categoryResult = Process-CategorySection -CategorySection $categorySection -SearchString $SearchString -PackageFilter $currentFilter
            Update-CategoryVisibility -CategorySection $categorySection -IsVisible $categoryResult.HasVisibleApps -CategoryHeader $categoryResult.CategoryHeader
        }
    }
}

function Process-CategorySection {
    <#
        .SYNOPSIS
            Processes a category section for search results.
    #>
    param($CategorySection, $SearchString, $PackageFilter)

    $categoryVisible = $false
    $categoryHeader = $null
    $wrapPanel = $null

    # Find category components
    foreach ($child in $CategorySection.Children) {
        if ($child -is [Windows.Controls.Border]) {
            if ($child.Child -is [Windows.Controls.Label]) {
                $categoryHeader = $child
            } elseif ($child.Child -is [Windows.Controls.WrapPanel]) {
                $wrapPanel = $child.Child
            }
        } elseif ($child -is [Windows.Controls.WrapPanel]) {
            $wrapPanel = $child
        }
    }

    if ($wrapPanel) {
        $categoryVisible = Process-WrapPanelApps -WrapPanel $wrapPanel -SearchString $SearchString -PackageFilter $PackageFilter
    }

    return @{
        HasVisibleApps = $categoryVisible
        CategoryHeader = $categoryHeader
    }
}

function Process-WrapPanelApps {
    <#
        .SYNOPSIS
            Processes apps within a WrapPanel for search and filtering.
    #>
    param($WrapPanel, $SearchString, $PackageFilter)

    $visibleItems = @()
    $hiddenItems = @()
    $categoryVisible = $false

    # Categorize items based on search and filter criteria
    foreach ($appItem in $WrapPanel.Children) {
        if ($appItem -is [Windows.Controls.Border]) {
            $matchResult = Test-AppMatch -AppItem $appItem -SearchString $SearchString -PackageFilter $PackageFilter

            if ($matchResult) {
                $visibleItems += $appItem
                $categoryVisible = $true
            } else {
                $hiddenItems += $appItem
            }
        }
    }

    # Optimize layout updates
    Update-WrapPanelLayout -WrapPanel $WrapPanel -VisibleItems $visibleItems -HiddenItems $hiddenItems

    return $categoryVisible
}

function Update-WrapPanelLayout {
    <#
        .SYNOPSIS
            Updates WrapPanel layout with performance optimizations.
    #>
    param($WrapPanel, $VisibleItems, $HiddenItems)

    $WrapPanel.BeginInit()

    try {
        # Determine if reorganization is needed
        $needsReorganization = ($HiddenItems.Count -gt 0) -and ($VisibleItems.Count -ne $WrapPanel.Children.Count)

        if ($needsReorganization) {
            Reorganize-WrapPanelItems -WrapPanel $WrapPanel -VisibleItems $VisibleItems -HiddenItems $HiddenItems
        } else {
            Update-ItemVisibility -VisibleItems $VisibleItems -HiddenItems $HiddenItems
        }
    } finally {
        $WrapPanel.EndInit()
    }

    # Async layout update for responsiveness
    Schedule-LayoutUpdate -WrapPanel $WrapPanel
}

function Reorganize-WrapPanelItems {
    <#
        .SYNOPSIS
            Reorganizes WrapPanel items for optimal layout.
    #>
    param($WrapPanel, $VisibleItems, $HiddenItems)

    $WrapPanel.Children.Clear()

    # Add visible items first
    foreach ($item in $VisibleItems) {
        $item.Visibility = [Windows.Visibility]::Visible
        $WrapPanel.Children.Add($item) | Out-Null
    }

    # Add hidden items for future operations
    foreach ($item in $HiddenItems) {
        $item.Visibility = [Windows.Visibility]::Collapsed
        $WrapPanel.Children.Add($item) | Out-Null
    }
}

function Update-ItemVisibility {
    <#
        .SYNOPSIS
            Updates item visibility without reorganization.
    #>
    param($VisibleItems, $HiddenItems)

    foreach ($item in $VisibleItems) {
        $item.Visibility = [Windows.Visibility]::Visible
    }
    foreach ($item in $HiddenItems) {
        $item.Visibility = [Windows.Visibility]::Collapsed
    }
}

function Schedule-LayoutUpdate {
    <#
        .SYNOPSIS
            Schedules asynchronous layout update.
    #>
    param($WrapPanel)

    if ($WrapPanel) {
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [System.Action]{
                if ($WrapPanel) {
                    $WrapPanel.InvalidateArrange()
                    $WrapPanel.UpdateLayout()
                }
            }
        ) | Out-Null
    }
}

function Update-CategoryVisibility {
    <#
        .SYNOPSIS
            Updates category section visibility.
    #>
    param($CategorySection, $IsVisible, $CategoryHeader)

    if ($IsVisible) {
        $CategorySection.Visibility = [Windows.Visibility]::Visible
        if ($CategoryHeader) {
            $CategoryHeader.Visibility = [Windows.Visibility]::Visible
        }
    } else {
        $CategorySection.Visibility = [Windows.Visibility]::Collapsed
    }
}

#endregion

#region Traditional Layout Handlers

function Show-AllAppsTraditional {
    <#
        .SYNOPSIS
            Shows all apps in traditional layout.
    #>
    param($TargetElement)

    $TargetElement.Items | ForEach-Object {
        $_.Visibility = [Windows.Visibility]::Visible
        if ($_.Children) {
            $_.Children | ForEach-Object {
                if ($null -ne $_) {
                    $_.Visibility = [Windows.Visibility]::Visible
                }
            }
        }
    }
}

function Search-AppsTraditionalLayout {
    <#
        .SYNOPSIS
            Searches apps in traditional layout.
    #>
    param($TargetElement, $SearchString)

    $currentFilter = Get-CurrentPackageFilter

    $TargetElement.Items | ForEach-Object {
        # Keep category toggle buttons visible
        if ($_.Tag -like "CategoryToggleButton") {
            $_.Visibility = [Windows.Visibility]::Visible
            return
        }

        # Process category wrap panels
        if ($_.Tag -like "CategoryWrapPanel_*") {
            $categoryHasVisibleApps = Process-TraditionalCategoryApps -CategoryPanel $_ -SearchString $SearchString -PackageFilter $currentFilter
            $_.Visibility = if ($categoryHasVisibleApps) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
        } else {
            $_.Visibility = [Windows.Visibility]::Collapsed
        }
    }
}

function Process-TraditionalCategoryApps {
    <#
        .SYNOPSIS
            Processes apps in traditional category layout.
    #>
    param($CategoryPanel, $SearchString, $PackageFilter)

    $categoryHasVisibleApps = $false

    $CategoryPanel.Children | ForEach-Object {
        if ($_.Tag) {
            $matchResult = Test-AppMatchByTag -AppTag $_.Tag -SearchString $SearchString -PackageFilter $PackageFilter

            if ($matchResult) {
                $_.Visibility = [Windows.Visibility]::Visible
                $categoryHasVisibleApps = $true
            } else {
                $_.Visibility = [Windows.Visibility]::Collapsed
            }
        }
    }

    return $categoryHasVisibleApps
}

#endregion

#region Helper Functions

function Get-WrapPanelFromChild {
    <#
        .SYNOPSIS
            Extracts WrapPanel from a child element.
    #>
    param($Child)

    if ($Child -is [Windows.Controls.Border] -and $Child.Child -is [Windows.Controls.WrapPanel]) {
        return $Child.Child
    } elseif ($Child -is [Windows.Controls.WrapPanel]) {
        return $Child
    }
    return $null
}

function Get-CurrentPackageFilter {
    <#
        .SYNOPSIS
            Gets the current package manager filter.
    #>

    return if ($sync.CurrentPackageFilter) { $sync.CurrentPackageFilter } else { "Winget" }
}

function Test-AppMatch {
    <#
        .SYNOPSIS
            Tests if an app item matches search and filter criteria.
    #>
    param($AppItem, $SearchString, $PackageFilter)

    $appKey = $AppItem.Tag
    $appData = $sync.configs.applicationsHashtable.$appKey

    if (-not $appData) { return $false }

    $searchMatch = Test-SearchMatch -AppData $appData -AppKey $appKey -SearchString $SearchString
    $packageMatch = Test-PackageManagerMatch -AppData $appData -PackageFilter $PackageFilter

    return $searchMatch -and $packageMatch
}

function Test-AppMatchByTag {
    <#
        .SYNOPSIS
            Tests if an app matches criteria using app tag.
    #>
    param($AppTag, $SearchString, $PackageFilter)

    $appEntry = $sync.configs.applicationsHashtable.$AppTag

    if (-not $appEntry) { return $false }

    $searchMatch = Test-SearchMatch -AppData $appEntry -AppKey $AppTag -SearchString $SearchString
    $packageMatch = Test-PackageManagerMatch -AppData $appEntry -PackageFilter $PackageFilter

    return $searchMatch -and $packageMatch
}

function Test-SearchMatch {
    <#
        .SYNOPSIS
            Tests if app data matches search string.
    #>
    param($AppData, $AppKey, $SearchString)

    return ($AppData.content -like "*$SearchString*") -or
           ($AppData.description -like "*$SearchString*") -or
           ($AppKey -like "*$SearchString*")
}

function Test-PackageManagerMatch {
    <#
        .SYNOPSIS
            Tests if app data matches package manager filter.
    #>
    param($AppData, $PackageFilter)

    switch ($PackageFilter) {
        "Winget" { return ($AppData.winget -and $AppData.winget -ne "na") }
        "Chocolatey" { return ($AppData.choco -and $AppData.choco -ne "na") }
        default { return $true }
    }
}

#endregion
