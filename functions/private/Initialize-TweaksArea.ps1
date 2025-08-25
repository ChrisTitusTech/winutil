function Initialize-TweaksArea {
    <#
        .SYNOPSIS
            Enhanced version for Tweaks section with modern card layout similar to Install section.
            Creates responsive card-based layout for tweaks with better spacing and styling.

        .PARAMETER TargetGridName
            The name of the target grid (should be "tweakspanel")
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
    $categories = $sync.configs.tweaks.PSObject.Properties.Name |
        ForEach-Object { $sync.configs.tweaks.$_.Category } |
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
            Add-TweakCategory -Category $category -StackPanel $stackPanel
        }
    }
}

function Add-TweakCategory {
    param(
        [string]$Category,
        [System.Windows.Controls.StackPanel]$StackPanel
    )

    # Enhanced category header with transparent background
    $categoryLabel = New-Object Windows.Controls.Label
    $categoryLabel.Content = $Category -replace ".*__", ""
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
    $categoryLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $categoryLabel.FontWeight = "Bold"
    $categoryLabel.Margin = "0,12,0,8"
    $categoryLabel.Padding = "8,6,8,6"
    $categoryLabel.Background = [System.Windows.Media.Brushes]::Transparent
    $categoryLabel.HorizontalAlignment = "Center"
    $StackPanel.Children.Add($categoryLabel) | Out-Null
    $sync[$Category] = $categoryLabel

    # Add tweaks for this category
    $tweaks = $sync.configs.tweaks.PSObject.Properties |
        Where-Object { $_.Value.Category -eq $Category } |
        Sort-Object { $_.Value.order }, Name

    foreach ($tweak in $tweaks) {
        $tweakInfo = $tweak.Value

        switch ($tweakInfo.Type) {
            "Toggle" {
                $tweakCard = New-TweakToggleCard -TweakName $tweak.Name -TweakInfo $tweakInfo
                $StackPanel.Children.Add($tweakCard) | Out-Null
            }
            "Button" {
                $tweakButton = New-TweakButton -TweakName $tweak.Name -TweakInfo $tweakInfo
                $StackPanel.Children.Add($tweakButton) | Out-Null
            }
            "ComboBox" {
                $tweakCombo = New-TweakCombo -TweakName $tweak.Name -TweakInfo $tweakInfo
                $StackPanel.Children.Add($tweakCombo) | Out-Null
            }
            default {
                # Fallback for other types
                $tweakCard = New-TweakToggleCard -TweakName $tweak.Name -TweakInfo $tweakInfo
                $StackPanel.Children.Add($tweakCard) | Out-Null
            }
        }
    }
}

function New-TweakToggleCard {
    param($TweakName, $TweakInfo)

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
    $checkBox.Name = $TweakName
    $checkBox.HorizontalAlignment = "Right"
    $checkBox.VerticalAlignment = "Center"
    $checkBox.SetValue([Windows.Controls.DockPanel]::DockProperty, [Windows.Controls.Dock]::Right)
    $checkBox.Style = $sync.Form.Resources.ColorfulToggleSwitchStyle
    $checkBox.Margin = "8,0,0,0"

    # Enhanced label with better typography and transparent background
    $label = New-Object Windows.Controls.Label
    $label.Content = $TweakInfo.Content
    $label.ToolTip = $TweakInfo.Description
    $label.HorizontalAlignment = "Stretch"
    $label.HorizontalContentAlignment = "Left"
    $label.VerticalContentAlignment = "Center"
    $label.VerticalAlignment = "Center"
    $label.Padding = "4,2,4,2"
    $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $label.FontWeight = "Normal"
    $label.Background = [System.Windows.Media.Brushes]::Transparent

    $dockPanel.Children.Add($checkBox) | Out-Null
    $dockPanel.Children.Add($label) | Out-Null

    # Click interaction for entire container
    $container.Add_MouseLeftButtonUp({
        $checkBox = $this.Child.Children[0]
        $checkBox.IsChecked = -not $checkBox.IsChecked
    })

    $sync[$TweakName] = $checkBox

    # Use safe wrapper to get toggle status without error messages
    $sync[$TweakName].IsChecked = Get-WinUtilToggleStatusSafe $TweakName

    # Event handlers
    $sync[$TweakName].Add_Checked({
        [System.Object]$Sender = $args[0]
        Invoke-WinUtilTweaks $sender.name
    })

    $sync[$TweakName].Add_Unchecked({
        [System.Object]$Sender = $args[0]
        Invoke-WinUtiltweaks $sender.name -undo $true
    })

    return $container
}

function New-TweakButton {
    param($TweakName, $TweakInfo)

    $button = New-Object Windows.Controls.Button
    $button.Name = $TweakName
    $button.Content = $TweakInfo.Content
    $button.ToolTip = $TweakInfo.Description
    $button.HorizontalAlignment = "Stretch"
    $button.Margin = "4,3,4,3"
    $button.Padding = "12,8,12,8"
    # Note: Button doesn't support CornerRadius property in WPF
    $button.FontWeight = "SemiBold"
    $button.Cursor = "Hand"
    $button.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")

    if ($TweakInfo.ButtonWidth) {
        $button.Width = $TweakInfo.ButtonWidth
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

    $sync[$TweakName] = $button
    return $button
}

function New-TweakCombo {
    param($TweakName, $TweakInfo)

    $container = New-Object Windows.Controls.StackPanel
    $container.Orientation = "Vertical"
    $container.Margin = "4,3,4,3"

    # Enhanced label with transparent background
    $label = New-Object Windows.Controls.Label
    $label.Content = $TweakInfo.Content
    $label.HorizontalAlignment = "Left"
    $label.VerticalAlignment = "Center"
    $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $label.Margin = "0,0,0,4"
    $label.Background = [System.Windows.Media.Brushes]::Transparent
    $container.Children.Add($label) | Out-Null

    # Enhanced combobox
    $comboBox = New-Object Windows.Controls.ComboBox
    $comboBox.Name = $TweakName
    $comboBox.HorizontalAlignment = "Stretch"
    $comboBox.VerticalAlignment = "Center"
    $comboBox.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
    $comboBox.Padding = "8,4,8,4"

    if ($TweakInfo.ComboItems) {
        # Handle both space-separated strings (like DNS) and object arrays
        if ($TweakInfo.ComboItems -is [string]) {
            # Space-separated string format (like DNS ComboBox)
            foreach ($comboitem in ($TweakInfo.ComboItems -split " ")) {
                $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                $comboBoxItem.Content = $comboitem
                $comboBox.Items.Add($comboBoxItem) | Out-Null
            }
        } else {
            # Object array format
            foreach ($comboitem in $TweakInfo.ComboItems) {
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
    $sync[$TweakName] = $comboBox

    return $container
}
