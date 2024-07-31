function Invoke-WinUtilUIElements {
    <#
    .SYNOPSIS
        Adds UI elements to a specified Grid in the WinUtil GUI based on a JSON configuration.
    .PARAMETER configVariable
        The variable/link containing the JSON configuration.
    .PARAMETER panel
        The name of the panel for which the UI elements should be added.
    .EXAMPLE
        Invoke-WinUtilUIElements -configVariable $sync.configs.applications -panel "install"
    #>

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$configVariable,

        [Parameter(Mandatory)]
        [ValidateSet("install", "tweaks", "features")]
        [string]$panel
    )

    # Ensure configVariable is not null
    if ($null -eq $configVariable) {
        throw "The configuration variable is null."
    }

    # Determine target grid and column count based on the panel
    switch ($panel) {
        "install" {
            $targetGridName = "appspanel"
            $columncount = 5
        }
        "tweaks" {
            $targetGridName = "tweakspanel"
            $columncount = 2
        }
        "features" {
            $targetGridName = "featurespanel"
            $columncount = 2
        }
    }

    # Convert PSCustomObject to Hashtable
    $configHashtable = @{}
    $configVariable.PSObject.Properties.Name | ForEach-Object {
        $configHashtable[$_] = $configVariable.$_
    }

    $organizedData = @{}
    # Iterate through JSON data and organize by panel and category
    foreach ($appName in $configHashtable.Keys) {
        $appInfo = $configHashtable[$appName]

        # Create an object for the application
        $appObject = [PSCustomObject]@{
            Name = $appName
            Category = $appInfo.Category
            Content = $appInfo.Content
            Choco = $appInfo.choco
            Winget = $appInfo.winget
            Panel = "0" # Set to 0 to force even distribution across columns
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
        $organizedData[$appObject.Panel][$appInfo.Category]["$($appInfo.order)$appName"] = $appObject
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
            $label.Content = $category
            $label.FontSize = 16
            $label.FontFamily = "Segoe UI"
            $stackPanel.Children.Add($label) | Out-Null

            $sortedApps = $organizedData[$panelKey][$category].Keys | Sort-Object
            foreach ($appName in $sortedApps) {
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

                $appInfo = $organizedData[$panelKey][$category][$appName]
                switch ($appInfo.Type) {
                    "Toggle" {
                        $dockPanel = New-Object Windows.Controls.DockPanel
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $appInfo.Name
                        $checkBox.HorizontalAlignment = "Right"
                        $checkBox.FontSize = 14
                        $dockPanel.Children.Add($checkBox) | Out-Null

                        $label = New-Object Windows.Controls.Label
                        $label.Content = $appInfo.Content
                        $label.ToolTip = $appInfo.Description
                        $label.HorizontalAlignment = "Left"
                        $label.FontSize = 14
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
                        $label.FontSize = 14
                        $horizontalStackPanel.Children.Add($label) | Out-Null

                        $comboBox = New-Object Windows.Controls.ComboBox
                        $comboBox.Name = $appInfo.Name
                        $comboBox.Height = 32
                        $comboBox.Width = 186
                        $comboBox.HorizontalAlignment = "Left"
                        $comboBox.VerticalAlignment = "Center"
                        $comboBox.Margin = "5,5"

                        foreach ($comboitem in ($appInfo.ComboItems -split " ")) {
                            $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                            $comboBoxItem.Content = $comboitem
                            $comboBoxItem.FontSize = 14
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
                        if ($appInfo.ButtonWidth -ne $null) {
                            $button.Width = $appInfo.ButtonWidth
                        }
                        $stackPanel.Children.Add($button) | Out-Null
                    }

                    default {
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $appInfo.Name
                        $checkBox.Content = $appInfo.Content
                        $checkBox.ToolTip = $appInfo.Description
                        $checkBox.Margin = "5,0"
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
