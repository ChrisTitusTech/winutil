function Initialize-WPFActionsTab {
    <#
    .SYNOPSIS
        Initializes the Actions tab in the Install section with proper styling and layout

    .PARAMETER TargetGridName
        The name of the target grid/panel to initialize (should be "appscategory")

    .DESCRIPTION
        This function creates a properly styled Actions sidebar with:
        - Action buttons (Install, Uninstall, Upgrade All)
        - Package Manager radio buttons (All, Winget, Chocolatey)
        - Selection controls (Clear, Get Installed, Selected Apps)

        Ensures proper spacing, text wrapping, and no button cutoff issues.
    #>

    param(
        [Parameter(Mandatory)]
        [string]$TargetGridName
    )

    if ($TargetGridName -ne "appscategory") {
        Write-Warning "Initialize-WPFActionsTab is specifically designed for 'appscategory' target grid"
        return
    }

    # Get the target container (appscategoryPanel StackPanel)
    $targetPanel = $sync.Form.FindName("appscategoryPanel")
    if (-not $targetPanel) {
        Write-Error "Could not find appscategoryPanel StackPanel"
        return
    }

    # Clear existing content
    $targetPanel.Children.Clear()

    # Define the Actions tab structure from appnavigation config
    $actionsConfig = $sync.configs.appnavigation

    # Organize items by category
    $organizedItems = @{
        "Actions" = @()
        "Package Manager" = @()
        "Selection" = @()
    }

    # Process each item from the config
    foreach ($itemKey in $actionsConfig.PSObject.Properties.Name) {
        $item = $actionsConfig.$itemKey
        $categoryName = switch ($item.Category) {
            "____Actions" { "Actions" }
            "__Package Manager" { "Package Manager" }
            "__Selection" { "Selection" }
            default { "Other" }
        }

        if ($organizedItems.ContainsKey($categoryName)) {
            $organizedItems[$categoryName] += [PSCustomObject]@{
                Key = $itemKey
                Content = $item.Content
                Type = $item.Type
                Order = [int]$item.Order
                Description = $item.Description
                GroupName = $item.GroupName
                Checked = $item.Checked
            }
        }
    }

    # Sort items by order within each category - use explicit keys array to avoid enumeration issues
    $categoryKeys = @($organizedItems.Keys)
    foreach ($category in $categoryKeys) {
        $organizedItems[$category] = $organizedItems[$category] | Sort-Object Order
    }

    # Create each category section - use explicit array to avoid enumeration issues
    $categoryOrder = @("Actions", "Package Manager", "Selection")
    foreach ($categoryName in $categoryOrder) {
        if (-not $organizedItems.ContainsKey($categoryName) -or $organizedItems[$categoryName].Count -eq 0) { continue }

        # Create category header
        $categoryHeader = New-Object Windows.Controls.TextBlock
        $categoryHeader.Text = $categoryName
        $categoryHeader.FontWeight = "Bold"
        $categoryHeader.FontSize = 14
        $categoryHeader.Margin = "5,10,5,5"
        $categoryHeader.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $targetPanel.Children.Add($categoryHeader) | Out-Null

        # Create container for this category's items
        $categoryContainer = New-Object Windows.Controls.StackPanel
        $categoryContainer.Margin = "2,0,4,5"  # Minimal margin since buttons have wrappers
        $targetPanel.Children.Add($categoryContainer) | Out-Null

        # Add items to this category
        foreach ($item in $organizedItems[$categoryName]) {
            switch ($item.Type) {
                                "Button" {
                    # Create a wrapper Border to ensure proper spacing and prevent clipping
                    $buttonWrapper = New-Object Windows.Controls.Border
                    $buttonWrapper.Margin = "2,1,4,2"  # Wrapper handles spacing

                    $button = New-Object Windows.Controls.Button
                    $button.Name = $item.Key
                    $button.Tag = $item.Key
                    $button.ToolTip = $item.Description

                    # Create text block for proper wrapping
                    $textBlock = New-Object Windows.Controls.TextBlock
                    $textBlock.Text = $item.Content
                    $textBlock.TextWrapping = "Wrap"
                    $textBlock.TextAlignment = "Center"
                    $textBlock.HorizontalAlignment = "Center"
                    $textBlock.VerticalAlignment = "Center"
                    $textBlock.Background = "Transparent"  # Force transparent background
                    $textBlock.IsHitTestVisible = $false  # Prevent mouse events on TextBlock
                    $textBlock.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "ButtonForegroundColor")
                    $button.Content = $textBlock

                    # Styling for Actions tab buttons - remove margins, wrapper handles spacing
                    $button.Width = 210
                    $button.Height = [Double]::NaN  # Auto height
                    $button.MinHeight = 28
                    $button.Margin = "0"  # No margin - wrapper handles it
                    $button.Padding = "4,6"
                    $button.HorizontalContentAlignment = "Center"
                    $button.VerticalContentAlignment = "Center"
                    $button.HorizontalAlignment = "Stretch"

                    # Force layout rounding to prevent border clipping
                    $button.UseLayoutRounding = $true
                    $button.SnapsToDevicePixels = $true

                    # Apply styling with explicit border thickness
                    $button.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ButtonBackgroundColor")
                    $button.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
                    $button.BorderThickness = "1"  # Explicit border thickness
                    $button.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")

                    # Put button inside wrapper and add wrapper to container
                    $buttonWrapper.Child = $button
                    $categoryContainer.Children.Add($buttonWrapper) | Out-Null

                    # Store in sync for main.ps1 to find
                    $sync[$item.Key] = $button
                }

                "RadioButton" {
                    $radioButton = New-Object Windows.Controls.RadioButton
                    $radioButton.Name = $item.Key
                    $radioButton.Content = $item.Content
                    $radioButton.GroupName = $item.GroupName
                    $radioButton.IsChecked = $item.Checked -eq $true
                    $radioButton.ToolTip = $item.Description
                    $radioButton.Margin = "5,2,6,2"  # Conservative margin
                    $radioButton.Padding = "3,3"

                    # Styling
                    $radioButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                    $radioButton.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")

                    # Add change event for package manager filtering
                    $radioButton.Add_Checked({
                        $filterType = switch ($this.Name) {
                            "WingetRadioButton" { "Winget" }
                            "ChocoRadioButton" { "Chocolatey" }
                            default { "Winget" }
                        }
                        Invoke-WPFPackageManagerFilter -FilterType $filterType
                    })

                    $categoryContainer.Children.Add($radioButton) | Out-Null

                    # Store in sync
                    $sync[$item.Key] = $radioButton
                }
            }
        }

        # Add spacing after each category (except the last one)
        if ($categoryName -ne "Selection") {
            $spacer = New-Object Windows.Controls.Border
            $spacer.Height = 1
            $spacer.Margin = "10,5,10,5"
            $spacer.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "BorderColor")
            $spacer.Opacity = 0.3
            $targetPanel.Children.Add($spacer) | Out-Null
        }
    }

    Write-Host "Actions tab initialized successfully with $(($organizedItems.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum) controls"
}
