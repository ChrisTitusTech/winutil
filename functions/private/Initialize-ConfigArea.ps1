function Initialize-ConfigArea {
    <#
        .SYNOPSIS
            Enhanced version for Config/Features section with modern card layout similar to Install section.
            Creates responsive card-based layout for features with better spacing and styling.

        .PARAMETER TargetGridName
            The name of the target grid (should be "featurespanel")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TargetGridName
    )

    $targetGrid = $sync.Form.FindName($TargetGridName)
    if (-not $targetGrid) {
        Write-Error "Could not find target grid: $TargetGridName"
        return
    }

    # Clear existing content
    $targetGrid.Children.Clear()
    $targetGrid.ColumnDefinitions.Clear()

    # Create 3 columns with equal width
    for ($i = 0; $i -lt 3; $i++) {
        $columnDefinition = New-Object Windows.Controls.ColumnDefinition
        $columnDefinition.Width = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)
        $targetGrid.ColumnDefinitions.Add($columnDefinition) | Out-Null
    }

        # Create enhanced columns with modern card styling
    $categoriesByColumn = @{0 = @(); 1 = @(); 2 = @()}

    # Organize categories across columns
    $categories = $sync.configs.feature.PSObject.Properties.Name |
        ForEach-Object { $sync.configs.feature.$_.Category } |
        Sort-Object | Get-Unique

    $categoryIndex = 0
    foreach ($category in $categories) {
        $categoriesByColumn[$categoryIndex % 3] += $category
        $categoryIndex++
    }

    # Create each column
    for ($col = 0; $col -lt 3; $col++) {
        # Enhanced border for each column - no ScrollViewer since XAML already has one
        $border = New-Object Windows.Controls.Border
        $border.VerticalAlignment = "Stretch"
        $border.HorizontalAlignment = "Stretch"
        $border.Margin = "8,8,8,8"
        $border.Padding = "12,12,12,12"
        $border.CornerRadius = "8"
        $border.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
        $border.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
        $border.BorderThickness = "1"
        [System.Windows.Controls.Grid]::SetColumn($border, $col)
        $targetGrid.Children.Add($border) | Out-Null

        # Enhanced stack panel directly - let XAML ScrollViewer handle scrolling
        $stackPanel = New-Object Windows.Controls.StackPanel
        $stackPanel.Orientation = "Vertical"
        $stackPanel.HorizontalAlignment = "Stretch"
        $stackPanel.VerticalAlignment = "Top"
        $stackPanel.Margin = "4,4,4,4"
        $border.Child = $stackPanel

        # Add categories to this column
        foreach ($category in $categoriesByColumn[$col]) {
            Add-ConfigCategory -Category $category -StackPanel $stackPanel
        }
    }
}

function Add-ConfigCategory {
    param(
        [string]$Category,
        [System.Windows.Controls.StackPanel]$StackPanel
    )

    # Enhanced category header with transparent background and centered text
    $categoryLabel = New-Object Windows.Controls.Label
    $categoryLabel.Content = $Category -replace ".*__", ""
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $categoryLabel.FontWeight = "Bold"
    $categoryLabel.Margin = "0,12,0,8"
    $categoryLabel.Padding = "8,6,8,6"
    $categoryLabel.Background = [System.Windows.Media.Brushes]::Transparent
    $categoryLabel.HorizontalContentAlignment = "Center"
    $StackPanel.Children.Add($categoryLabel) | Out-Null
    $sync[$Category] = $categoryLabel

    # Add features for this category
    $features = $sync.configs.feature.PSObject.Properties |
        Where-Object { $_.Value.Category -eq $Category } |
        Sort-Object { $_.Value.order }, Name

    foreach ($feature in $features) {
        $featureInfo = $feature.Value

        switch ($featureInfo.Type) {
            "Toggle" {
                $featureCard = New-ConfigToggleCard -FeatureName $feature.Name -FeatureInfo $featureInfo
                $StackPanel.Children.Add($featureCard) | Out-Null
            }
            "Button" {
                $featureButton = New-ConfigButton -FeatureName $feature.Name -FeatureInfo $featureInfo
                $StackPanel.Children.Add($featureButton) | Out-Null
            }
            "CheckBox" {
                $featureCheck = New-ConfigCheckBox -FeatureName $feature.Name -FeatureInfo $featureInfo
                $StackPanel.Children.Add($featureCheck) | Out-Null
            }
            "ComboBox" {
                $featureCombo = New-ConfigCombo -FeatureName $feature.Name -FeatureInfo $featureInfo
                $StackPanel.Children.Add($featureCombo) | Out-Null
            }
            default {
                # Fallback for buttons or other types
                $featureButton = New-ConfigButton -FeatureName $feature.Name -FeatureInfo $featureInfo
                $StackPanel.Children.Add($featureButton) | Out-Null
            }
        }
    }
}

function New-ConfigToggleCard {
    param($FeatureName, $FeatureInfo)

    # Enhanced container similar to app cards in Install section
    $container = New-Object Windows.Controls.Border
    $container.Margin = "4,3,4,3"
    $container.Padding = "12,8,12,8"
    $container.CornerRadius = "6"
    $container.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
    $container.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
    $container.BorderThickness = "1"
    $container.Cursor = "Hand"

    # Enhanced hover effects like Install section
    $container.Add_MouseEnter({
        $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallHighlightedColor")
        $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")
        $this.BorderThickness = "2"
    })

    $container.Add_MouseLeave({
        $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
        $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
        $this.BorderThickness = "1"
    })

    # Mouse wheel scrolling handled by XAML ScrollViewer - no manual handling needed

    # Layout similar to Install app cards
    $dockPanel = New-Object Windows.Controls.DockPanel
    $dockPanel.HorizontalAlignment = "Stretch"
    $container.Child = $dockPanel

    # Enhanced toggle switch
    $checkBox = New-Object Windows.Controls.CheckBox
    $checkBox.Name = $FeatureName
    $checkBox.HorizontalAlignment = "Right"
    $checkBox.VerticalAlignment = "Center"
    $checkBox.SetValue([Windows.Controls.DockPanel]::DockProperty, [Windows.Controls.Dock]::Right)
    $checkBox.Style = $sync.Form.Resources.ColorfulToggleSwitchStyle
    $checkBox.Margin = "8,0,0,0"

    # Enhanced label with better typography
    $label = New-Object Windows.Controls.Label
    $label.Content = $FeatureInfo.Content
    $label.ToolTip = $FeatureInfo.Description
    $label.HorizontalAlignment = "Stretch"
    $label.HorizontalContentAlignment = "Left"
    $label.VerticalContentAlignment = "Center"
    $label.VerticalAlignment = "Center"
    $label.Padding = "4,2,4,2"
    $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $label.FontWeight = "Normal"

    $dockPanel.Children.Add($checkBox) | Out-Null
    $dockPanel.Children.Add($label) | Out-Null

    # Click interaction for entire container
    $container.Add_MouseLeftButtonUp({
        $checkBox = $this.Child.Children[0]
        $checkBox.IsChecked = -not $checkBox.IsChecked
    })

    $sync[$FeatureName] = $checkBox

    # Use safe wrapper to get toggle status without error messages
    $sync[$FeatureName].IsChecked = Get-WinUtilToggleStatusSafe $FeatureName

    # Event handlers would need to be implemented based on feature type
    # For now, basic toggle functionality

    return $container
}

function New-ConfigButton {
    param($FeatureName, $FeatureInfo)

    $button = New-Object Windows.Controls.Button
    $button.Name = $FeatureName
    $button.Content = $FeatureInfo.Content
    $button.ToolTip = $FeatureInfo.Description
    $button.HorizontalAlignment = "Stretch"
    $button.Margin = "4,3,4,3"
    $button.Padding = "12,8,12,8"
    # Note: Button doesn't support CornerRadius property in WPF
    $button.FontWeight = "SemiBold"
    $button.Cursor = "Hand"
    $button.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")

    if ($FeatureInfo.ButtonWidth) {
        $button.Width = $FeatureInfo.ButtonWidth
    }

    # Enhanced hover effects
    $button.Add_MouseEnter({
        $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ButtonBackgroundColorOver")
        $this.BorderThickness = "2"
    })

    $button.Add_MouseLeave({
        $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ButtonBackgroundColor")
        $this.BorderThickness = "1"
    })

    $sync[$FeatureName] = $button
    return $button
}

function New-ConfigCheckBox {
    param($FeatureName, $FeatureInfo)

    $container = New-Object Windows.Controls.Border
    $container.Margin = "4,3,4,3"
    $container.Padding = "8,6,8,6"
    $container.CornerRadius = "4"
    $container.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "SecondaryBackgroundColor")
    $container.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
    $container.BorderThickness = "1"

    $stackPanel = New-Object Windows.Controls.StackPanel
    $stackPanel.Orientation = "Horizontal"
    $container.Child = $stackPanel

    $checkBox = New-Object Windows.Controls.CheckBox
    $checkBox.Name = $FeatureName
    $checkBox.Content = $FeatureInfo.Content
    $checkBox.ToolTip = $FeatureInfo.Description
    $checkBox.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $checkBox.SetResourceReference([Windows.Controls.Control]::MarginProperty, "CheckBoxMargin")

    if ($FeatureInfo.Checked -eq $true) {
        $checkBox.IsChecked = $FeatureInfo.Checked
    }

    $stackPanel.Children.Add($checkBox) | Out-Null

    if ($FeatureInfo.Link) {
        $textBlock = New-Object Windows.Controls.TextBlock
        $textBlock.Name = $checkBox.Name + "Link"
        $textBlock.Text = "(?)"
        $textBlock.ToolTip = $FeatureInfo.Link
        $textBlock.Style = $sync.Form.Resources.HoverTextBlockStyle
        $textBlock.Margin = "4,0,0,0"
        $stackPanel.Children.Add($textBlock) | Out-Null
        $sync[$textBlock.Name] = $textBlock
    }

    $sync[$FeatureName] = $checkBox
    return $container
}

function New-ConfigCombo {
    param($FeatureName, $FeatureInfo)

    $container = New-Object Windows.Controls.StackPanel
    $container.Orientation = "Vertical"
    $container.Margin = "4,3,4,3"

    # Enhanced label with transparent background
    $label = New-Object Windows.Controls.Label
    $label.Content = $FeatureInfo.Content
    $label.HorizontalAlignment = "Left"
    $label.VerticalAlignment = "Center"
    $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $label.Margin = "0,0,0,4"
    $label.Background = [System.Windows.Media.Brushes]::Transparent
    $container.Children.Add($label) | Out-Null

    # Enhanced combobox
    $comboBox = New-Object Windows.Controls.ComboBox
    $comboBox.Name = $FeatureName
    $comboBox.HorizontalAlignment = "Stretch"
    $comboBox.VerticalAlignment = "Center"
    $comboBox.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $comboBox.Padding = "8,4,8,4"

    if ($FeatureInfo.ComboItems) {
        # Handle both space-separated strings (like DNS) and object arrays
        if ($FeatureInfo.ComboItems -is [string]) {
            # Space-separated string format (like DNS ComboBox)
            foreach ($comboitem in ($FeatureInfo.ComboItems -split " ")) {
                $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                $comboBoxItem.Content = $comboitem
                $comboBox.Items.Add($comboBoxItem) | Out-Null
            }
        } else {
            # Object array format
            foreach ($comboitem in $FeatureInfo.ComboItems) {
                $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                $comboBoxItem.Content = $comboitem.Content
                $comboBoxItem.ToolTip = $comboitem.ToolTip
                $comboBox.Items.Add($comboBoxItem) | Out-Null
            }
        }
    }

    # Set default selection
    $comboBox.SelectedIndex = 0

    $container.Children.Add($comboBox) | Out-Null
    $sync[$FeatureName] = $comboBox

    return $container
}
