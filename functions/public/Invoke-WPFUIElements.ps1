function Invoke-WPFUIElements {
    <#
    .SYNOPSIS
        Adds UI elements to a specified Grid in the WinUtil GUI based on a JSON configuration.
    .PARAMETER configVariable
        The variable/link containing the JSON configuration.
    .PARAMETER targetGridName
        The name of the grid to which the UI elements should be added.
    .PARAMETER columncount
        The number of columns to be used in the Grid. If not provided, a default value is used based on the panel.
    .PARAMETER categoryPanelMap
        A hashtable that maps specific categories to specific panels.
    .EXAMPLE
        $categoryPanelMap = @{
            "Essential Tweaks" = 0
            "Customize Preferences" = 1
        }
        Invoke-WPFUIElements -configVariable $sync.configs.applications -targetGridName "install" -columncount 4 -categoryPanelMap $categoryPanelMap
    #>

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$configVariable,

        [Parameter(Mandatory)]
        [string]$targetGridName,

        [int]$columncount
    )

    $theme = $sync.configs.themes.$ctttheme

    # Convert PSCustomObject to Hashtable
    $configHashtable = @{}
    $configVariable.PSObject.Properties.Name | ForEach-Object {
        $configHashtable[$_] = $configVariable.$_
    }

    $organizedData = @{}
    # Iterate through JSON data and organize by panel and category
    foreach ($entry in $configHashtable.Keys) {
        $appInfo = $configHashtable[$entry]

        # Create an object for the application
        $appObject = [PSCustomObject]@{
            Name = $entry
            Category = $appInfo.Category
            Content = $appInfo.Content
            Choco = $appInfo.choco
            Winget = $appInfo.winget
            Panel = if ($appInfo.Panel -ne $null) { $appInfo.Panel } else { "0" }
            Link = $appInfo.link
            Description = $appInfo.description
            Type = $appInfo.type
            ComboItems = $appInfo.ComboItems
            Checked = $appInfo.Checked
            ButtonWidth = $appInfo.ButtonWidth
        }

        if (-not $organizedData.ContainsKey($appObject.Panel)) {
            $organizedData[$appObject.Panel] = @{}
        }

        if (-not $organizedData[$appObject.Panel].ContainsKey($appObject.Category)) {
            $organizedData[$appObject.Panel][$appObject.Category] = @{}
        }

        # Store application data in a sub-array under the category
        $organizedData[$appObject.Panel][$appInfo.Category]["$($appInfo.order)$entry"] = $appObject
    }

    # Retrieve the main window and the target Grid by name
    $window = $sync["Form"]
    $targetGrid = $window.FindName($targetGridName)

    if ($null -eq $targetGrid) {
        throw "Grid '$targetGridName' not found."
    }

    # Calculate the needed number of panels and columns
    $panelcount = 0
    $paneltotal = $columncount # Use columncount for even distribution
    $appcount = $configHashtable.Keys.Count + $organizedData["0"].Keys.Count
    $maxcount = [Math]::Round($appcount / $columncount + 0.5)

    # Clear existing ColumnDefinitions and Children
    $targetGrid.ColumnDefinitions.Clear() | Out-Null
    $targetGrid.Children.Clear() | Out-Null

    # Add ColumnDefinitions to the target Grid
    for ($i = 0; $i -lt $paneltotal; $i++) {
        $colDef = New-Object Windows.Controls.ColumnDefinition
        $colDef.Width = New-Object Windows.GridLength(1, [Windows.GridUnitType]::Star)
        $targetGrid.ColumnDefinitions.Add($colDef) | Out-Null
    }

    # Iterate through 'organizedData' by panel, category, and application
    $count = 0
    foreach ($panelKey in ($organizedData.Keys | Sort-Object)) {
        # Create a Border for each column
        $border = New-Object Windows.Controls.Border
        $border.BorderBrush = [Windows.Media.Brushes]::Gray
        $border.BorderThickness = [Windows.Thickness]::new(1)
        $border.Margin = [Windows.Thickness]::new(5)
        $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
        [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
        $targetGrid.Children.Add($border) | Out-Null

        # Create a StackPanel inside the Border
        $stackPanel = New-Object Windows.Controls.StackPanel
        $stackPanel.Background = [Windows.Media.Brushes]::Transparent
        $stackPanel.SnapsToDevicePixels = $true
        $stackPanel.VerticalAlignment = "Stretch" # Ensure the stack panel stretches vertically
        $border.Child = $stackPanel
        $panelcount++

        foreach ($category in ($organizedData[$panelKey].Keys | Sort-Object)) {
            $count++
            if ($columncount -gt 0) {
                $panelcount2 = [Int](($count) / $maxcount - 0.5)
                if ($panelcount -eq $panelcount2) {
                    # Create a new Border for the new column
                    $border = New-Object Windows.Controls.Border
                    $border.BorderBrush = [Windows.Media.Brushes]::Gray
                    $border.BorderThickness = [Windows.Thickness]::new(1)
                    $border.Margin = [Windows.Thickness]::new(5)
                    $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
                    [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
                    $targetGrid.Children.Add($border) | Out-Null

                    # Create a new StackPanel inside the Border
                    $stackPanel = New-Object Windows.Controls.StackPanel
                    $stackPanel.Background = [Windows.Media.Brushes]::Transparent
                    $stackPanel.SnapsToDevicePixels = $true
                    $stackPanel.VerticalAlignment = "Stretch" # Ensure the stack panel stretches vertically
                    $border.Child = $stackPanel
                    $panelcount++
                }
            }

            $label = New-Object Windows.Controls.Label
            $label.Content = $category -replace ".*__"
            $label.FontSize = $theme.FontSizeHeading
            $label.FontFamily = $theme.HeaderFontFamily
            $stackPanel.Children.Add($label) | Out-Null

            $sortedApps = $organizedData[$panelKey][$category].Keys | Sort-Object
            foreach ($entry in $sortedApps) {
                $count++
                if ($columncount -gt 0) {
                    $panelcount2 = [Int](($count) / $maxcount - 0.5)
                    if ($panelcount -eq $panelcount2) {
                        # Create a new Border for the new column
                        $border = New-Object Windows.Controls.Border
                        $border.BorderBrush = [Windows.Media.Brushes]::Gray
                        $border.BorderThickness = [Windows.Thickness]::new(1)
                        $border.Margin = [Windows.Thickness]::new(5)
                        $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
                        [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
                        $targetGrid.Children.Add($border) | Out-Null

                        # Create a new StackPanel inside the Border
                        $stackPanel = New-Object Windows.Controls.StackPanel
                        $stackPanel.Background = [Windows.Media.Brushes]::Transparent
                        $stackPanel.SnapsToDevicePixels = $true
                        $stackPanel.VerticalAlignment = "Stretch" # Ensure the stack panel stretches vertically
                        $border.Child = $stackPanel
                        $panelcount++
                    }
                }

                $appInfo = $organizedData[$panelKey][$category][$entry]
                switch ($appInfo.Type) {
                    "Toggle" {
                        $dockPanel = New-Object Windows.Controls.DockPanel
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $appInfo.Name
                        $checkBox.HorizontalAlignment = "Right"
                        $dockPanel.Children.Add($checkBox) | Out-Null
                        $checkBox.Style = $window.FindResource("ColorfulToggleSwitchStyle")

                        $label = New-Object Windows.Controls.Label
                        $label.Content = $appInfo.Content
                        $label.ToolTip = $appInfo.Description
                        $label.HorizontalAlignment = "Left"
                        $label.FontSize = $theme.FontSize
                        # Implement for consistent theming later on $label.Style = $window.FindResource("labelfortweaks")
                        $dockPanel.Children.Add($label) | Out-Null

                        $stackPanel.Children.Add($dockPanel) | Out-Null
                    }

                    "Combobox" {
                        $horizontalStackPanel = New-Object Windows.Controls.StackPanel
                        $horizontalStackPanel.Orientation = "Horizontal"
                        $horizontalStackPanel.Margin = "0,5,0,0"

                        $label = New-Object Windows.Controls.Label
                        $label.Content = $appInfo.Content
                        $label.HorizontalAlignment = "Left"
                        $label.VerticalAlignment = "Center"
                        $label.FontSize = $theme.ButtonFontSize
                        $horizontalStackPanel.Children.Add($label) | Out-Null

                        $comboBox = New-Object Windows.Controls.ComboBox
                        $comboBox.Name = $appInfo.Name
                        $comboBox.Height = $theme.ButtonHeight
                        $comboBox.Width = $theme.ButtonWidth
                        $comboBox.HorizontalAlignment = "Left"
                        $comboBox.VerticalAlignment = "Center"
                        $comboBox.Margin = "5,5"

                        foreach ($comboitem in ($appInfo.ComboItems -split " ")) {
                            $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                            $comboBoxItem.Content = $comboitem
                            $comboBoxItem.FontSize = $theme.ButtonFontSize
                            $comboBox.Items.Add($comboBoxItem) | Out-Null
                        }

                        $horizontalStackPanel.Children.Add($comboBox) | Out-Null
                        $stackPanel.Children.Add($horizontalStackPanel) | Out-Null
                    }

                    "Button" {
                        $button = New-Object Windows.Controls.Button
                        $button.Name = $appInfo.Name
                        $button.Content = $appInfo.Content
                        $button.HorizontalAlignment = "Left"
                        $button.Margin = "5"
                        $button.Padding = "20,5"
                        $button.FontSize = $theme.ButtonFontSize
                        if ($appInfo.ButtonWidth -ne $null) {
                            $button.Width = $appInfo.ButtonWidth
                        }
                        $stackPanel.Children.Add($button) | Out-Null
                    }

                    default {
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $appInfo.Name
                        $checkBox.Content = $appInfo.Content
                        $checkBox.FontSize = $theme.FontSize
                        $checkBox.ToolTip = $appInfo.Description
                        $checkBox.Margin = $theme.CheckBoxMargin
                        if ($appInfo.Checked -ne $null) {
                            $checkBox.IsChecked = $appInfo.Checked
                        }
                        if ($appInfo.Link -ne $null) {
                            $horizontalStackPanel = New-Object Windows.Controls.StackPanel
                            $horizontalStackPanel.Orientation = "Horizontal"
                            $horizontalStackPanel.Children.Add($checkBox) | Out-Null

                            $textBlock = New-Object Windows.Controls.TextBlock
                            $textBlock.Text = "(?)"
                            $textBlock.ToolTip = $appInfo.Link
                            $textBlock.Style = $window.FindResource("HoverTextBlockStyle")

                            # Add event handler for click to open link
                            $handler = [System.Windows.Input.MouseButtonEventHandler]{
                                param($sender, $e)
                                Start-Process $sender.ToolTip.ToString()
                            }
                            $textBlock.AddHandler([Windows.Controls.TextBlock]::MouseLeftButtonUpEvent, $handler)

                            $horizontalStackPanel.Children.Add($textBlock) | Out-Null

                            $stackPanel.Children.Add($horizontalStackPanel) | Out-Null
                        } else {
                            $stackPanel.Children.Add($checkBox) | Out-Null
                        }
                    }
                }
            }
        }
    }
}
