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
        Invoke-WPFUIElements -configVariable $sync.configs.applications -targetGridName "install" -columncount 5
    .NOTES
        Future me/contributer: If possible please wrap this into a runspace to make it load all panels at the same time.
    #>

    param(
        [Parameter(Mandatory, position=0)]
        [PSCustomObject]$configVariable,

        [Parameter(Mandatory, position=1)]
        [string]$targetGridName,

        [Parameter(Mandatory, position=2)]
        [int]$columncount
    )

    $window = $sync["Form"]

    $theme = $sync.Form.Resources
    $borderstyle = $window.FindResource("BorderStyle")
    $HoverTextBlockStyle = $window.FindResource("HoverTextBlockStyle")
    $ColorfulToggleSwitchStyle = $window.FindResource("ColorfulToggleSwitchStyle")

    if (!$borderstyle -or !$HoverTextBlockStyle -or !$ColorfulToggleSwitchStyle) {
        throw "Failed to retrieve Styles using 'FindResource' from main window element."
    }

    $targetGrid = $window.FindName($targetGridName)

    if (!$targetGrid) {
        throw "Failed to retrieve Target Grid by name, provided name: $targetGrid"
    }

    # Clear existing ColumnDefinitions and Children
    $targetGrid.ColumnDefinitions.Clear() | Out-Null
    $targetGrid.Children.Clear() | Out-Null

    # Add ColumnDefinitions to the target Grid
    for ($i = 0; $i -lt $columncount; $i++) {
        $colDef = New-Object Windows.Controls.ColumnDefinition
        $colDef.Width = New-Object Windows.GridLength(1, [Windows.GridUnitType]::Star)
        $targetGrid.ColumnDefinitions.Add($colDef) | Out-Null
    }

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
            Name = $entry
            Order = $entryInfo.order
            Category = $entryInfo.Category
            Content = $entryInfo.Content
            Choco = $entryInfo.choco
            Winget = $entryInfo.winget
            Panel = if ($entryInfo.Panel) { $entryInfo.Panel } else { "0" }
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
            $organizedData[$entryObject.Panel][$entryObject.Category] = @()
        }

        # Store application data in an array under the category
        $organizedData[$entryObject.Panel][$entryObject.Category] += $entryObject

        # Only apply the logic for distributing entries across columns if the targetGridName is "appspanel"
        if ($targetGridName -eq "appspanel") {
            $panelcount = 0
            $entrycount = $configHashtable.Keys.Count + $organizedData["0"].Keys.Count
            $maxcount = [Math]::Round($entrycount / $columncount + 0.5)
        }
    }

    # Iterate through 'organizedData' by panel, category, and application
    $count = 0
    foreach ($panelKey in ($organizedData.Keys | Sort-Object)) {
        # Create a Border for each column
        $border = New-Object Windows.Controls.Border
        $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
        [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
        $border.style = $borderstyle
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
                    $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
                    [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
                    $border.style = $borderstyle
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
            $label.Content = $category -replace ".*__", ""
            $label.FontSize = $theme.FontSizeHeading
            $label.FontFamily = $theme.HeaderFontFamily
            $stackPanel.Children.Add($label) | Out-Null

            $sync[$category] = $label

            # Sort entries by Order and then by Name, but only display Name
            $entries = $organizedData[$panelKey][$category] | Sort-Object Order, Name
            foreach ($entryInfo in $entries) {
                $count++
                if ($targetGridName -eq "appspanel" -and $columncount -gt 0) {
                    $panelcount2 = [Int](($count) / $maxcount - 0.5)
                    if ($panelcount -eq $panelcount2) {
                        # Create a new Border for the new column
                        $border = New-Object Windows.Controls.Border
                        $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
                        [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
                        $border.style = $borderstyle
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

                switch ($entryInfo.Type) {
                    "Toggle" {
                        $dockPanel = New-Object Windows.Controls.DockPanel
                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $entryInfo.Name
                        $checkBox.HorizontalAlignment = "Right"
                        $dockPanel.Children.Add($checkBox) | Out-Null
                        $checkBox.Style = $ColorfulToggleSwitchStyle

                        $label = New-Object Windows.Controls.Label
                        $label.Content = $entryInfo.Content
                        $label.ToolTip = $entryInfo.Description
                        $label.HorizontalAlignment = "Left"
                        $label.FontSize = $theme.FontSize
                        $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                        $dockPanel.Children.Add($label) | Out-Null
                        $stackPanel.Children.Add($dockPanel) | Out-Null

                        $sync[$entryInfo.Name] = $checkBox

                        $sync[$entryInfo.Name].IsChecked = Get-WinUtilToggleStatus $sync[$entryInfo.Name].Name

                        $sync[$entryInfo.Name].Add_Click({
                            [System.Object]$Sender = $args[0]
                            Invoke-WPFToggle $Sender.name
                        })
                    }

                    "ToggleButton" {
                        $toggleButton = New-Object Windows.Controls.ToggleButton
                        $toggleButton.Name = $entryInfo.Name
                        $toggleButton.Name = "WPFTab" + ($stackPanel.Children.Count + 1) + "BT"
                        $toggleButton.HorizontalAlignment = "Left"
                        $toggleButton.Height = $theme.TabButtonHeight
                        $toggleButton.Width = $theme.TabButtonWidth
                        $toggleButton.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ButtonInstallBackgroundColor")
                        $toggleButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                        $toggleButton.FontWeight = [Windows.FontWeights]::Bold

                        $textBlock = New-Object Windows.Controls.TextBlock
                        $textBlock.FontSize = $theme.TabButtonFontSize
                        $textBlock.Background = [Windows.Media.Brushes]::Transparent
                        $textBlock.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "ButtonInstallForegroundColor")

                        $underline = New-Object Windows.Documents.Underline
                        $underline.Inlines.Add($entryInfo.name -replace "(.).*", "`$1")

                        $run = New-Object Windows.Documents.Run
                        $run.Text = $entryInfo.name -replace "^.", ""

                        $textBlock.Inlines.Add($underline)
                        $textBlock.Inlines.Add($run)

                        $toggleButton.Content = $textBlock

                        $stackPanel.Children.Add($toggleButton) | Out-Null

                        $sync[$entryInfo.Name] = $toggleButton
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
                        $comboBox.Margin = $theme.ButtonMargin

                        foreach ($comboitem in ($entryInfo.ComboItems -split " ")) {
                            $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                            $comboBoxItem.Content = $comboitem
                            $comboBoxItem.FontSize = $theme.ButtonFontSize
                            $comboBox.Items.Add($comboBoxItem) | Out-Null
                        }

                        $horizontalStackPanel.Children.Add($comboBox) | Out-Null
                        $stackPanel.Children.Add($horizontalStackPanel) | Out-Null

                        $comboBox.SelectedIndex = 0

                        $sync[$entryInfo.Name] = $comboBox
                    }

                    "Button" {
                        $button = New-Object Windows.Controls.Button
                        $button.Name = $entryInfo.Name
                        $button.Content = $entryInfo.Content
                        $button.HorizontalAlignment = "Left"
                        $button.Margin = $theme.ButtonMargin
                        $button.FontSize = $theme.ButtonFontSize
                        if ($entryInfo.ButtonWidth) {
                            $button.Width = $entryInfo.ButtonWidth
                        }
                        $stackPanel.Children.Add($button) | Out-Null

                        $sync[$entryInfo.Name] = $button
                    }

                    default {
                        $horizontalStackPanel = New-Object Windows.Controls.StackPanel
                        $horizontalStackPanel.Orientation = "Horizontal"

                        $checkBox = New-Object Windows.Controls.CheckBox
                        $checkBox.Name = $entryInfo.Name
                        $checkBox.Content = $entryInfo.Content
                        $checkBox.FontSize = $theme.FontSize
                        $checkBox.ToolTip = $entryInfo.Description
                        $checkBox.Margin = $theme.CheckBoxMargin
                        if ($entryInfo.Checked -eq $true) {
                            $checkBox.IsChecked = $entryInfo.Checked
                        }
                        $horizontalStackPanel.Children.Add($checkBox) | Out-Null

                        if ($entryInfo.Link) {
                            $textBlock = New-Object Windows.Controls.TextBlock
                            $textBlock.Name = $checkBox.Name + "Link"
                            $textBlock.Text = "(?)"
                            $textBlock.ToolTip = $entryInfo.Link
                            $textBlock.Style = $HoverTextBlockStyle

                            $horizontalStackPanel.Children.Add($textBlock) | Out-Null

                            $sync[$textBlock.Name] = $textBlock
                        }

                        $stackPanel.Children.Add($horizontalStackPanel) | Out-Null
                        $sync[$entryInfo.Name] = $checkBox
                    }
                }
            }
        }
    }
}
