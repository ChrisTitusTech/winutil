function Initialize-InstallCategoryAppList {
    <#
        .SYNOPSIS
            Enhanced version with responsive grid layout, better performance, and modern styling.
            Creates category sections with responsive WrapPanels for optimal space utilization.

        .PARAMETER TargetElement
            The Element into which the Categories and Apps should be placed
        .PARAMETER Apps
            The Hashtable of Apps to be added to the UI
        .PARAMETER ItemWidth
            Width for individual app items (default: auto-calculated based on screen size)
        .PARAMETER UseResponsiveLayout
            Enable responsive WrapPanel layout (default: true)
    #>
    param(
        $TargetElement,
        $Apps,
        [double]$ItemWidth = 0,
        [bool]$UseResponsiveLayout = $true
    )

    # Calculate optimal item width based on screen size
    if ($ItemWidth -eq 0) {
        $windowWidth = if ($sync.form.ActualWidth -gt 0) { $sync.form.ActualWidth } else { $sync.form.MaxWidth }
        if ($windowWidth -eq 0) { $windowWidth = 1200 }

        # Dynamic item width calculation for optimal layout
        if ($windowWidth -gt 1600) {
            $ItemWidth = 200  # 6+ items per row on wide screens
        } elseif ($windowWidth -gt 1200) {
            $ItemWidth = 220  # 5 items per row on large screens
        } elseif ($windowWidth -gt 900) {
            $ItemWidth = 240  # 4 items per row on medium screens
        } else {
            $ItemWidth = 260  # 3 items per row on smaller screens
        }
    }

    function Add-Category {
        param(
            [string]$Category,
            [System.Object]$TargetElement,
            [double]$ItemWidth,
            [bool]$UseResponsiveLayout
        )

        # Enhanced category section
        $categorySection = New-Object Windows.Controls.StackPanel
        $categorySection.Orientation = 'Vertical'
        $categorySection.Margin = '0,20,0,15'
        $categorySection.HorizontalAlignment = 'Stretch'

        # Modern category header with enhanced styling
        $categoryHeader = New-Object Windows.Controls.Border
        $categoryHeader.SetResourceReference([Windows.Controls.Control]::StyleProperty, "BorderStyle")
        $categoryHeader.Padding = '16,12,16,12'
        $categoryHeader.Margin = '0,0,0,12'
        $categoryHeader.CornerRadius = '8'
        $categoryHeader.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
        $categoryHeader.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
        $categoryHeader.BorderThickness = '1'

        # Category label with improved typography
        $categoryLabel = New-Object Windows.Controls.Label
        $categoryLabel.Content = $Category
        $categoryLabel.Tag = "CategoryToggleButton"
        $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
        $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
        $categoryLabel.FontWeight = 'SemiBold'
        $categoryLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $categoryLabel.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "Transparent")
        $categoryLabel.HorizontalAlignment = 'Center'
        $categoryLabel.VerticalAlignment = 'Center'
        $categoryLabel.Padding = '4,2,4,2'

        $categoryHeader.Child = $categoryLabel
        $categorySection.Children.Add($categoryHeader) | Out-Null
        $sync.$Category = $categoryLabel

        if ($UseResponsiveLayout) {
            # Enhanced responsive WrapPanel with better performance
            $wrapPanel = New-Object Windows.Controls.WrapPanel
            $wrapPanel.Orientation = "Horizontal"
            $wrapPanel.HorizontalAlignment = "Stretch"
            $wrapPanel.VerticalAlignment = "Top"
            $wrapPanel.ItemWidth = $ItemWidth
            $wrapPanel.Margin = '0,0,0,25'
            $wrapPanel.Tag = "CategoryWrapPanel_$Category"

            # Add subtle background for better visual grouping
            $wrapPanelBorder = New-Object Windows.Controls.Border
            $wrapPanelBorder.Child = $wrapPanel
            $wrapPanelBorder.Padding = '8'
            $wrapPanelBorder.CornerRadius = '6'
            $wrapPanelBorder.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallBackgroundColor")
            $wrapPanelBorder.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
            $wrapPanelBorder.BorderThickness = '0.5'

            $categorySection.Children.Add($wrapPanelBorder) | Out-Null
            $TargetElement.Children.Add($categorySection) | Out-Null

            return $wrapPanel
        } else {
            # Traditional WrapPanel layout (fallback)
            $wrapPanel = New-Object Windows.Controls.WrapPanel
            $wrapPanel.Orientation = "Horizontal"
            $wrapPanel.HorizontalAlignment = "Stretch"
            $wrapPanel.VerticalAlignment = "Center"
            $wrapPanel.Margin = '0,0,0,20'
            $wrapPanel.Visibility = [Windows.Visibility]::Visible
            $wrapPanel.Tag = "CategoryWrapPanel_$Category"

            $categorySection.Children.Add($wrapPanel) | Out-Null
            $TargetElement.Children.Add($categorySection) | Out-Null

            return $wrapPanel
        }
    }

    # Pre-group apps by category and sort for consistent ordering
    $appsByCategory = @{}
    foreach ($appKey in $Apps.Keys) {
        $category = $Apps.$appKey.Category
        if (-not $appsByCategory.ContainsKey($category)) {
            $appsByCategory[$category] = @()
        }
        $appsByCategory[$category] += $appKey
    }

    # Sort categories alphabetically for consistent display
    $sortedCategories = $appsByCategory.Keys | Sort-Object

    # Create progress tracking for large datasets
    $totalApps = ($appsByCategory.Values | Measure-Object -Property Count -Sum).Sum
    $currentApp = 0

    foreach ($category in $sortedCategories) {
        # Add category with enhanced styling
        $wrapPanel = Add-Category -Category $category -TargetElement $TargetElement -ItemWidth $ItemWidth -UseResponsiveLayout $UseResponsiveLayout

        # Sort apps within category and add them
        $sortedApps = $appsByCategory[$category] | Sort-Object
        foreach ($appKey in $sortedApps) {
            $currentApp++

            # Create enhanced app entry
            $sync.$appKey = Initialize-InstallAppEntry -TargetElement $wrapPanel -AppKey $appKey -Apps $Apps -ItemWidth $ItemWidth

            # Update progress for large datasets (optional - only if there's a progress indicator)
            if ($totalApps -gt 500 -and $sync.ProgressBar) {
                $progress = ($currentApp / $totalApps) * 100
                $sync.ProgressBar.Value = $progress

                # Allow UI to update during long operations
                if ($currentApp % 50 -eq 0) {
                    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
                        [System.Windows.Threading.DispatcherPriority]::Background,
                        [System.Action]{}
                    )
                }
            }
        }
    }

    # Add window resize handler for responsive design
    if ($UseResponsiveLayout) {
        $resizeHandler = {
            param($source, $e)

            # Debounced resize handling
            if (-not $sync.AppLayoutResizeTimer) {
                $sync.AppLayoutResizeTimer = New-Object System.Windows.Threading.DispatcherTimer
                $sync.AppLayoutResizeTimer.Interval = [TimeSpan]::FromMilliseconds(300)
                $sync.AppLayoutResizeTimer.Add_Tick({
                    $sync.AppLayoutResizeTimer.Stop()

                    # Recalculate item widths based on new window size
                    $newWidth = $sync.form.ActualWidth
                    if ($newWidth -gt 0) {
                        $newItemWidth = if ($newWidth -gt 1600) { 200 }
                                       elseif ($newWidth -gt 1200) { 220 }
                                       elseif ($newWidth -gt 900) { 240 }
                                       else { 260 }

                        # Update all WrapPanels with new item width
                        $allWrapPanels = $TargetElement.Children | ForEach-Object {
                            if ($_ -is [Windows.Controls.StackPanel]) {
                                $_.Children | Where-Object {
                                    ($_ -is [Windows.Controls.Border] -and $_.Child -is [Windows.Controls.WrapPanel]) -or
                                    ($_ -is [Windows.Controls.WrapPanel])
                                }
                            }
                        }

                        foreach ($panel in $allWrapPanels) {
                            $wrapPanel = if ($panel -is [Windows.Controls.Border]) { $panel.Child } else { $panel }
                            if ($wrapPanel -is [Windows.Controls.WrapPanel]) {
                                $wrapPanel.ItemWidth = $newItemWidth
                            }
                        }
                    }
                })
            }

            $sync.AppLayoutResizeTimer.Stop()
            $sync.AppLayoutResizeTimer.Start()
        }

        # Only add the handler once
        if (-not $sync.AppLayoutResizeHandlerAdded) {
            $sync.form.Add_SizeChanged($resizeHandler)
            $sync.AppLayoutResizeHandlerAdded = $true
        }
    }
}
