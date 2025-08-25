function Add-CategoryNavigationBar {
    <#
    .SYNOPSIS
        Creates a modern category navigation bar with highlighting and hover effects.

    .PARAMETER TargetContainer
        The container to add the navigation bar to

    .PARAMETER Categories
        Array of category names to create navigation items for
    #>
    param(
        [Parameter(Mandatory=$true)]
        $TargetContainer,

        [Parameter(Mandatory=$true)]
        [string[]]$Categories
    )

        # Create sticky navigation container with wrapping
    $navContainer = New-Object Windows.Controls.Border
    $navContainer.Name = "CategoryNavigationBar"
    $navContainer.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
    $navContainer.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
    $navContainer.BorderThickness = '0,0,0,1'
    $navContainer.Padding = '4,4'
    $navContainer.Margin = '0,0,0,8'

    # Make the navigation sticky by setting it to dock at top
    $navContainer.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
    $navContainer.VerticalAlignment = [Windows.VerticalAlignment]::Top

    # Create wrap panel for category buttons that wrap to new lines
    $categoryPanel = New-Object Windows.Controls.WrapPanel
    $categoryPanel.Orientation = [Windows.Controls.Orientation]::Horizontal
    $categoryPanel.HorizontalAlignment = [Windows.HorizontalAlignment]::Left
    $categoryPanel.ItemWidth = [Double]::NaN  # Allow natural width
    $categoryPanel.ItemHeight = 34
    $navContainer.Child = $categoryPanel

    # Add "All Categories" button first
    $allButton = New-Object Windows.Controls.Button
    $allButton.Content = "All Categories"
    $allButton.Name = "CategoryNav_All"
    $allButton.Tag = "All"
    # Remove non-existent style reference
    $allButton.Margin = '1,1'
    $allButton.Padding = '6,3'
    $allButton.IsDefault = $true

    # Enhanced styling for category buttons with blue color (start as selected since "All Categories" is default)
    $allButton.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ToggleButtonOnColor")
    $allButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainBackgroundColor")
    $allButton.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "ToggleButtonOnColor")
    $allButton.BorderThickness = '2'
    $allButton.FontWeight = 'SemiBold'
    $allButton.FontSize = 10
    $allButton.MinWidth = 60
    $allButton.Height = 28
    $allButton.MaxWidth = 100

    # Click event for all categories (use $this to avoid null reference)
    $allButton.add_Click({
        Set-ActiveCategoryButton -ActiveButton $this
        Show-CategoryApps -CategoryName $this.Tag
    })

    $categoryPanel.Children.Add($allButton) | Out-Null
    $sync.ActiveCategoryButton = $allButton

    # Add category-specific buttons
    foreach ($category in $Categories) {
        if ([string]::IsNullOrWhiteSpace($category)) { continue }

        $categoryButton = New-Object Windows.Controls.Button
        $categoryButton.Content = $category
        $categoryButton.Name = "CategoryNav_$($category -replace '[^a-zA-Z0-9]', '')"
        $categoryButton.Tag = $category
        $categoryButton.Margin = '1,1'
        $categoryButton.Padding = '6,3'

        # Modern button styling with proper text visibility
        $categoryButton.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
        $categoryButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $categoryButton.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
        $categoryButton.BorderThickness = '1'
        $categoryButton.FontSize = 10
        $categoryButton.MinWidth = 60
        $categoryButton.Height = 28
        $categoryButton.MaxWidth = 100

                        # Enhanced hover and active effects with blue color
        $categoryButton.add_MouseEnter({
            if ($this -ne $sync.ActiveCategoryButton) {
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ToggleButtonOnColor")
                $this.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainBackgroundColor")
                $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "ToggleButtonOnColor")
                $this.BorderThickness = '1'
                $this.Opacity = 0.9
            }
        })

        $categoryButton.add_MouseLeave({
            if ($this -ne $sync.ActiveCategoryButton) {
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
                $this.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
                $this.BorderThickness = '1'
                $this.Opacity = 1.0
            }
        })

        # Click event with category filtering
        $categoryButton.add_Click({
            Set-ActiveCategoryButton -ActiveButton $this
            Show-CategoryApps -CategoryName $this.Tag
        })

        $categoryPanel.Children.Add($categoryButton) | Out-Null
    }

    # Add to target container at the top (sticky position)
    if ($TargetContainer -is [Windows.Controls.StackPanel]) {
        # For StackPanel, insert at top
        $TargetContainer.Children.Insert(0, $navContainer)
    } elseif ($TargetContainer -is [Windows.Controls.Grid]) {
        # For Grid, add as first row
        $navRow = New-Object Windows.Controls.RowDefinition
        $navRow.Height = [Windows.GridLength]::Auto
        $TargetContainer.RowDefinitions.Insert(0, $navRow)

        # Shift existing content down
        foreach ($child in $TargetContainer.Children) {
            $currentRow = [Windows.Controls.Grid]::GetRow($child)
            [Windows.Controls.Grid]::SetRow($child, $currentRow + 1)
        }

        # Add navigation at row 0
        [Windows.Controls.Grid]::SetRow($navContainer, 0)
        [Windows.Controls.Grid]::SetColumnSpan($navContainer, [Math]::Max(1, $TargetContainer.ColumnDefinitions.Count))
        $TargetContainer.Children.Add($navContainer) | Out-Null
    } else {
        # Default fallback
        $TargetContainer.Children.Insert(0, $navContainer)
    }

    # Store reference for later use
    $sync.CategoryNavigationBar = $navContainer
    $sync.CategoryPanel = $categoryPanel

    Write-Host "Category navigation bar created with $($Categories.Count + 1) categories"
}

function Set-ActiveCategoryButton {
    <#
    .SYNOPSIS
        Sets the active state for a category navigation button
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ActiveButton
    )

    # Null check to prevent errors
    if (-not $ActiveButton) {
        Write-Warning "ActiveButton parameter is null, skipping activation"
        return
    }

    # Reset all category buttons to inactive state with proper contrast
    if ($sync.CategoryPanel) {
        foreach ($button in $sync.CategoryPanel.Children) {
            if ($button -is [Windows.Controls.Button]) {
                $button.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
                $button.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                $button.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
                $button.FontWeight = 'Normal'
                $button.Opacity = 1.0
            }
        }
    }

    # Set active button styling with the blue color (same as Actions tab buttons)
    $ActiveButton.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ToggleButtonOnColor")
    $ActiveButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainBackgroundColor")
    $ActiveButton.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "ToggleButtonOnColor")
    $ActiveButton.BorderThickness = '2'
    $ActiveButton.FontWeight = 'SemiBold'
    $ActiveButton.Opacity = 1.0

    # Store active button reference
    $sync.ActiveCategoryButton = $ActiveButton
}

function Show-CategoryApps {
    <#
    .SYNOPSIS
        Filters applications to show only those in the specified category
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CategoryName
    )

    # Store current category filter
    $sync.CurrentCategoryFilter = $CategoryName

    # Apply category filter to responsive layout
    if ($sync.ItemsControl -and $sync.ItemsControl -is [Windows.Controls.StackPanel]) {
        foreach ($categorySection in $sync.ItemsControl.Children) {
            if ($categorySection -is [Windows.Controls.StackPanel]) {
                $sectionVisible = $false

                # Get category name from header
                foreach ($child in $categorySection.Children) {
                    if ($child -is [Windows.Controls.Border] -and $child.Child -is [Windows.Controls.Label]) {
                        $headerText = $child.Child.Content

                        # Show section if category matches or "All" is selected
                        if ($CategoryName -eq "All" -or $headerText -eq $CategoryName) {
                            $sectionVisible = $true
                        }
                        break
                    }
                }

                # Set section visibility and force layout update
                if ($sectionVisible) {
                    $categorySection.Visibility = [Windows.Visibility]::Visible
                } else {
                    $categorySection.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }

        # Force the main container to update its layout to prevent empty scrolling
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [System.Action]{
                if ($sync.ItemsControl) {
                    $sync.ItemsControl.InvalidateArrange()
                    $sync.ItemsControl.UpdateLayout()

                    # If there's a parent scroll viewer, update it too
                    $parent = $sync.ItemsControl.Parent
                    while ($parent -and $parent -isnot [Windows.Controls.ScrollViewer]) {
                        $parent = $parent.Parent
                    }
                    if ($parent -is [Windows.Controls.ScrollViewer]) {
                        $parent.InvalidateScrollInfo()
                        $parent.ScrollToTop()
                    }
                }
            }
        ) | Out-Null
    }

    Write-Host "Filtered to show category: $CategoryName"
}
