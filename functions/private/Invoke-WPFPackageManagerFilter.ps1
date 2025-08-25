function Invoke-WPFPackageManagerFilter {
    <#
        .SYNOPSIS
            Filters the displayed applications based on the selected package manager.
            Works with both original and enhanced responsive layouts.

        .PARAMETER FilterType
            The package manager filter to apply: "Winget", "Chocolatey"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$FilterType = "Winget"
    )

    # Determine which filter is currently active
    if ([string]::IsNullOrWhiteSpace($FilterType)) {
        if ($sync.WingetRadioButton.IsChecked -eq $true) {
            $FilterType = "Winget"
        } elseif ($sync.ChocoRadioButton.IsChecked -eq $true) {
            $FilterType = "Chocolatey"
        } else {
            $FilterType = "Winget"  # Default fallback
        }
    }

    # Store current filter for search integration
    $sync.CurrentPackageFilter = $FilterType

    # Determine layout type by checking if sync.ItemsControl exists and what type it is
    $isResponsiveLayout = $false
    $targetElement = $null

    if ($sync.ItemsControl) {
        $targetElement = $sync.ItemsControl
        $isResponsiveLayout = $sync.ItemsControl -is [Windows.Controls.StackPanel]
    } else {
        Write-Warning "Could not find ItemsControl for applications filter"
        return
    }

    # Apply filter based on layout type
    if ($isResponsiveLayout) {
        Hide-AppsResponsiveLayout -TargetElement $targetElement -FilterType $FilterType
    } else {
        Hide-AppsTraditionalLayout -TargetElement $targetElement -FilterType $FilterType
    }

    Write-Host "Filtered applications to show: $FilterType"
}

function Hide-AppsResponsiveLayout {
    param($TargetElement, $FilterType)

    foreach ($categorySection in $TargetElement.Children) {
        if ($categorySection -is [Windows.Controls.StackPanel]) {
            $categoryVisible = $false
            $categoryHeader = $null
            $wrapPanel = $null

            # Find category header and wrap panel
            foreach ($child in $categorySection.Children) {
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
                # Store items to reorganize
                $visibleItems = @()
                $hiddenItems = @()

                # Separate visible and hidden items
                foreach ($appItem in $wrapPanel.Children) {
                    if ($appItem -is [Windows.Controls.Border]) {
                        $appKey = $appItem.Tag
                        $appData = $sync.configs.applicationsHashtable.$appKey

                        $showApp = $false
                        if ($appData) {
                                                    switch ($FilterType) {
                            "Winget" {
                                $showApp = ($appData.winget -and $appData.winget -ne "na")
                            }
                            "Chocolatey" {
                                $showApp = ($appData.choco -and $appData.choco -ne "na")
                            }
                        }
                        }

                        if ($showApp) {
                            $visibleItems += $appItem
                            $categoryVisible = $true
                        } else {
                            $hiddenItems += $appItem
                        }
                    }
                }

                # Performance optimized reorganization - batch operations for better performance
                $wrapPanel.BeginInit()

                try {
                    # Only reorganize if there are items to move
                    if ($hiddenItems.Count -gt 0) {
                        # Clear and re-add in one batch
                        $wrapPanel.Children.Clear()

                        # Add visible items with efficient bulk operation
                        foreach ($item in $visibleItems) {
                            $item.Visibility = [Windows.Visibility]::Visible
                            $wrapPanel.Children.Add($item) | Out-Null
                        }

                        # Add hidden items (collapsed) for search functionality
                        foreach ($item in $hiddenItems) {
                            $item.Visibility = [Windows.Visibility]::Collapsed
                            $wrapPanel.Children.Add($item) | Out-Null
                        }
                    } else {
                        # Just update visibility if no reorganization needed
                        foreach ($item in $visibleItems) {
                            $item.Visibility = [Windows.Visibility]::Visible
                        }
                    }
                } finally {
                    $wrapPanel.EndInit()
                }

                # Single layout update at the end with null check
                if ($wrapPanel) {
                    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
                        [System.Windows.Threading.DispatcherPriority]::Loaded,
                        [System.Action]{
                            if ($wrapPanel) {
                                $wrapPanel.InvalidateArrange()
                                $wrapPanel.UpdateLayout()
                            }
                        }
                    ) | Out-Null
                }
            }

            # Show/hide category based on whether any apps are visible
            if ($categoryVisible) {
                $categorySection.Visibility = [Windows.Visibility]::Visible
                if ($categoryHeader) {
                    $categoryHeader.Visibility = [Windows.Visibility]::Visible
                }
            } else {
                $categorySection.Visibility = [Windows.Visibility]::Collapsed
            }
        }
    }
}

function Hide-AppsTraditionalLayout {
    param($TargetElement, $FilterType)

    foreach ($item in $TargetElement.Items) {
        # Skip category headers
        if ($item.Tag -like "CategoryToggleButton") {
            $item.Visibility = [Windows.Visibility]::Visible
            continue
        }

        if ($item.Tag -like "CategoryWrapPanel_*") {
            $categoryVisible = $false

            # Filter apps in this category wrap panel
            foreach ($appItem in $item.Children) {
                if ($appItem.Tag) {
                    $appData = $sync.configs.applicationsHashtable.$($appItem.Tag)

                    $showApp = $false
                    if ($appData) {
                        switch ($FilterType) {
                            "Winget" {
                                $showApp = ($appData.winget -and $appData.winget -ne "na")
                            }
                            "Chocolatey" {
                                $showApp = ($appData.choco -and $appData.choco -ne "na")
                            }
                        }
                    }

                    if ($showApp) {
                        $appItem.Visibility = [Windows.Visibility]::Visible
                        $categoryVisible = $true
                    } else {
                        $appItem.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }

            # Show/hide the entire category wrap panel
            if ($categoryVisible) {
                $item.Visibility = [Windows.Visibility]::Visible
            } else {
                $item.Visibility = [Windows.Visibility]::Collapsed
            }
        }
    }
}

function Get-PackageManagerStats {
    <#
        .SYNOPSIS
            Gets statistics about available applications per package manager
    #>
    $stats = @{
        Winget = 0
        Chocolatey = 0
        Both = 0
    }

    foreach ($appKey in $sync.configs.applicationsHashtable.Keys) {
        $appData = $sync.configs.applicationsHashtable.$appKey
        $hasWinget = ($appData.winget -and $appData.winget -ne "na")
        $hasChoco = ($appData.choco -and $appData.choco -ne "na")

        if ($hasWinget) { $stats.Winget++ }
        if ($hasChoco) { $stats.Chocolatey++ }
        if ($hasWinget -and $hasChoco) { $stats.Both++ }
    }

    return $stats
}
