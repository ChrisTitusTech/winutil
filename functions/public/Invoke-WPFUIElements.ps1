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
    .EXAMPLE
        $categoryPanelMap = @{
            "Essential Tweaks" = 0
            "Customize Preferences" = 1
        }
        Invoke-WPFUIElements -configVariable $sync.configs.applications -targetGridName "install" -columncount 5
    #>

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$configVariable,

        [Parameter(Mandatory)]
        [string]$targetGridName,

        [Parameter(Mandatory)]
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
        $entryInfo = $configHashtable[$entry]

        # Create an object for the application
        $entryObject = [PSCustomObject]@{
            Name = $entry.Name
            Category = $entryInfo.Category
            Content = $entryInfo.Content
            Choco = $entryInfo.choco
            Winget = $entryInfo.winget
            Panel = if ($entryInfo.Panel -ne $null) { $entryInfo.Panel } else { "0" }
            Link = $entryInfo.link
            Description = $entryInfo.description
            Type = $entryInfo.type
            ComboItems = $entryInfo.ComboItems
            Checked = $entryInfo.Checked
            ButtonWidth = $entryInfo.ButtonWidth
        }

        if (-not $organizedData.ContainsKey($entryObject.Panel)) {
            $organizedData[$entryObject.Panel] = @{}
        }

        if (-not $organizedData[$entryObject.Panel].ContainsKey($entryObject.Category)) {
            $organizedData[$entryObject.Panel][$entryObject.Category] = @{}
        }

        # Store application data in a sub-array under the category
        $organizedData[$entryObject.Panel][$entryInfo.Category]["$($entryInfo.order)$entry"] = $entryObject

    }

    # Retrieve the main window and the target Grid by name
    $window = $sync["Form"]
    $targetGrid = $window.FindName($targetGridName)

    # Clear existing ColumnDefinitions and Children
    $targetGrid.ColumnDefinitions.Clear() | Out-Null
    $targetGrid.Children.Clear() | Out-Null

    # Add ColumnDefinitions to the target Grid
    for ($i = 0; $i -lt $columncount; $i++) {
        $colDef = New-Object Windows.Controls.ColumnDefinition
        $colDef.Width = New-Object Windows.GridLength(1, [Windows.GridUnitType]::Star)
        $targetGrid.ColumnDefinitions.Add($colDef) | Out-Null
    }

    # Only apply the logic for distributing entries across columns if the targetGridName is "appspanel"
    if ($targetGridName -eq "appspanel") {
        $panelcount = 0
        $paneltotal = $columncount # Use columncount for even distribution
        $entrycount = $configHashtable.Keys.Count + $organizedData["0"].Keys.Count
        $maxcount = [Math]::Round($entrycount / $columncount + 0.5)
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
            if ($targetGridName -eq "appspanel" -and $columncount -gt 0) {
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

            $entries = $organizedData[$panelKey][$category].Keys | Sort-Object
            foreach ($entry in $entries) {
                $count++
                if ($targetGridName -eq "appspanel" -and $columncount -gt 0) {
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

                $entryInfo = $organizedData[$panelKey][$category][$entry]
                switch ($entryInfo.Type) {
                    "Toggle" {
                        $dockPanel = New-Object Windows.Controls.DockPanel
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $entryInfo.Name
                        write-host $entryInfo.Name
                        $checkBox.HorizontalAlignment = "Right"
                        $dockPanel.Children.Add($checkBox) | Out-Null
                        $checkBox.Style = $window.FindResource("ColorfulToggleSwitchStyle")

                        $label = New-Object Windows.Controls.Label
                        $label.Content = $entryInfo.Content
                        $label.ToolTip = $entryInfo.Description
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
                        $label.Content = $entryInfo.Content
                        $label.HorizontalAlignment = "Left"
                        $label.VerticalAlignment = "Center"
                        $label.FontSize = $theme.ButtonFontSize
                        $horizontalStackPanel.Children.Add($label) | Out-Null

                        $comboBox = New-Object Windows.Controls.ComboBox
                        $comboBox.Name = $entryInfo.Name
                        $comboBox.Height = $theme.ButtonHeight
                        $comboBox.Width = $theme.ButtonWidth
                        $comboBox.HorizontalAlignment = "Left"
                        $comboBox.VerticalAlignment = "Center"
                        $comboBox.Margin = "5,5"

                        foreach ($comboitem in ($entryInfo.ComboItems -split " ")) {
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
                        $button.Name = $entryInfo.Name
                        $button.Content = $entryInfo.Content
                        $button.HorizontalAlignment = "Left"
                        $button.Margin = "5"
                        $button.Padding = "20,5"
                        $button.FontSize = $theme.ButtonFontSize
                        if ($entryInfo.ButtonWidth -ne $null) {
                            $button.Width = $entryInfo.ButtonWidth
                        }
                        $stackPanel.Children.Add($button) | Out-Null
                    }

                    default {
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $entryInfo.Name
                        $checkBox.Content = $entryInfo.Content
                        $checkBox.FontSize = $theme.FontSize
                        $checkBox.ToolTip = $entryInfo.Description
                        $checkBox.Margin = $theme.CheckBoxMargin
                        if ($entryInfo.Checked -ne $null) {
                            $checkBox.IsChecked = $entryInfo.Checked
                        }
                        if ($entryInfo.Link -ne $null) {
                            $horizontalStackPanel = New-Object Windows.Controls.StackPanel
                            $horizontalStackPanel.Orientation = "Horizontal"
                            $horizontalStackPanel.Children.Add($checkBox) | Out-Null

                            $textBlock = New-Object Windows.Controls.TextBlock
                            $textBlock.Text = "(?)"
                            $textBlock.ToolTip = $entryInfo.Link
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
