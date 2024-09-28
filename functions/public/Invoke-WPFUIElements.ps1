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

                if ($configVariable -eq $sync.configs.applications) {
                    # Create the outer Border for the application type
                    $border = New-Object Windows.Controls.Border
                    $border.Name = "wpfappborder" + $entryInfo.Name
                    $border.BorderBrush = [Windows.Media.Brushes]::Gray
                    $border.BorderThickness = 1
                    $border.CornerRadius = 5
                    $border.Padding = New-Object Windows.Thickness(10)
                    $border.HorizontalAlignment = "Stretch"
                    $border.VerticalAlignment = "Top"
                    $border.Margin = New-Object Windows.Thickness(0, 10, 0, 0)

                    # Create a DockPanel inside the Border
                    $dockPanel = New-Object Windows.Controls.DockPanel
                    $dockPanel.LastChildFill = $true
                    $border.Child = $dockPanel

                    # Create the CheckBox, vertically centered
                    $checkBox = New-Object Windows.Controls.CheckBox
                    $checkBox.Name = $entryInfo.Name
                    $checkBox.HorizontalAlignment = "Left"
                    $checkBox.VerticalAlignment = "Center"
                    $checkBox.Margin = New-Object Windows.Thickness(5, 0, 10, 0)
                    [Windows.Controls.DockPanel]::SetDock($checkBox, [Windows.Controls.Dock]::Left)
                    $dockPanel.Children.Add($checkBox) | Out-Null

                    # Create a StackPanel for the image and name (for better alignment)
                    $imageAndNamePanel = New-Object Windows.Controls.StackPanel
                    $imageAndNamePanel.Orientation = "Horizontal"
                    $imageAndNamePanel.VerticalAlignment = "Center"

                    # Create the Image and load it from the local path
                    $image = New-Object Windows.Controls.Image
                    $image.Name = "wpfapplogo" + $entryInfo.Name
                    $image.Width = 40
                    $image.Height = 40
                    $image.Margin = New-Object Windows.Thickness(0, 0, 10, 0)
                    $image.Source = $noimage
                    if (-not [string]::IsNullOrEmpty($kaka)) {
                        try {
                            $packageinfo = (choco info $entryInfo.choco --limit-output).Split(' ')[0]
                            $packageinfo = $packageinfo -replace '\|', '.'
                            $iconlink = "https://community.chocolatey.org/content/packageimages/" + $packageinfo
                            $finishediconlink = $iconlink + ".png"
                            $webimage = Invoke-WebRequest -Uri $finishediconlink -Method Head -ErrorAction SilentlyContinue
                            if ($webimage.StatusCode -eq 200) {
                                $image.Source = [Windows.Media.Imaging.BitmapImage]::new([Uri]::new($finishediconlink))
                            } else {
                                $finishediconlink = $iconlink + ".svg"
                                $image.Source = $noimage
                            }
                        } catch {
                            $image.Source = $noimage
                        }
                    }

                    #$image.Source = $noimage
                    $image.Clip = New-Object Windows.Media.RectangleGeometry
                    $image.Clip.Rect = New-Object Windows.Rect(0, 0, $image.Width, $image.Height)
                    $image.Clip.RadiusX = 5
                    $image.Clip.RadiusY = 5

                    $imageAndNamePanel.Children.Add($image) | Out-Null

                    # Create the TextBlock for the application name (bigger and bold)
                    $appName = New-Object Windows.Controls.TextBlock
                    $appName.Text = $entryInfo.Content
                    $appName.FontSize = 16
                    $appName.FontWeight = [Windows.FontWeights]::Bold
                    $appName.VerticalAlignment = "Center"
                    $appName.Margin = New-Object Windows.Thickness(5, 0, 0, 0)
                    $imageAndNamePanel.Children.Add($appName) | Out-Null

                    # Add the image and name panel to the dock panel (after the checkbox)
                    [Windows.Controls.DockPanel]::SetDock($imageAndNamePanel, [Windows.Controls.Dock]::Left)
                    $dockPanel.Children.Add($imageAndNamePanel) | Out-Null

                    # Create the StackPanel for the buttons and dock it to the right
                    $buttonPanel = New-Object Windows.Controls.StackPanel
                    $buttonPanel.Orientation = "Horizontal"
                    $buttonPanel.HorizontalAlignment = "Right"
                    $buttonPanel.VerticalAlignment = "Center"
                    $buttonPanel.Margin = New-Object Windows.Thickness(10, 0, 0, 0)
                    [Windows.Controls.DockPanel]::SetDock($buttonPanel, [Windows.Controls.Dock]::Right)

                    # Create the "Install" button with the install icon from Segoe MDL2 Assets
                    $button1 = New-Object Windows.Controls.Button
                    $button1.Width = 45
                    $button1.Height = 35
                    $button1.Margin = New-Object Windows.Thickness(0, 0, 10, 0)

                    $installIcon = New-Object Windows.Controls.TextBlock
                    $installIcon.Text = [char]0xE118  # Install Icon
                    $installIcon.FontFamily = "Segoe MDL2 Assets"
                    $installIcon.FontSize = 20
                    $installIcon.Foreground = $theme.MainForegroundColor
                    $installIcon.Background = "Transparent"
                    $installIcon.HorizontalAlignment = "Center"
                    $installIcon.VerticalAlignment = "Center"

                    $button1.Content = $installIcon
                    $buttonPanel.Children.Add($button1) | Out-Null

                    # Create the "Uninstall" button with the uninstall icon from Segoe MDL2 Assets
                    $button2 = New-Object Windows.Controls.Button
                    $button2.Width = 45
                    $button2.Height = 35

                    $uninstallIcon = New-Object Windows.Controls.TextBlock
                    $uninstallIcon.Text = [char]0xE74D  # Uninstall Icon
                    $uninstallIcon.FontFamily = "Segoe MDL2 Assets"
                    $uninstallIcon.FontSize = 20
                    $uninstallIcon.Foreground = $theme.MainForegroundColor
                    $uninstallIcon.Background = "Transparent"
                    $uninstallIcon.HorizontalAlignment = "Center"
                    $uninstallIcon.VerticalAlignment = "Center"

                    $button2.Content = $uninstallIcon
                    $buttonPanel.Children.Add($button2) | Out-Null

                    # Create the "Info" button with the info icon from Segoe MDL2 Assets
                    $infoButton = New-Object Windows.Controls.Button
                    $infoButton.Width = 45
                    $infoButton.Height = 35
                    $infoButton.Margin = New-Object Windows.Thickness(10, 0, 0, 0)

                    $infoIcon = New-Object Windows.Controls.TextBlock
                    $infoIcon.Text = [char]0xE946  # Info Icon
                    $infoIcon.FontFamily = "Segoe MDL2 Assets"
                    $infoIcon.FontSize = 20
                    $infoIcon.Foreground = $theme.MainForegroundColor
                    $infoIcon.Background = "Transparent"
                    $infoIcon.HorizontalAlignment = "Center"
                    $infoIcon.VerticalAlignment = "Center"

                    $infoButton.Content = $infoIcon
                    $buttonPanel.Children.Add($infoButton) | Out-Null

                    # Add the button panel to the DockPanel
                    $dockPanel.Children.Add($buttonPanel) | Out-Null

                    # Add the border to the main stack panel in the grid
                    $stackPanel.Children.Add($border) | Out-Null

                    # Sync the CheckBox, buttons, and info to the sync object for further use
                    $sync[$entryInfo.Name] = $checkBox
                    $sync[$entryInfo.Name + "_InstallButton"] = $button1
                    $sync[$entryInfo.Name + "_UninstallButton"] = $button2
                    $sync[$entryInfo.Name + "_InfoButton"] = $infoButton
                } else {
                    # Create the UI elements based on the entry type
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

                        "RadioButton" {
                            $radioButton = New-Object Windows.Controls.RadioButton
                            $radioButton.Name = $entryInfo.Name
                            $radioButton.GroupName = $entryInfo.GroupName
                            $radioButton.Content = $entryInfo.Content
                            $radioButton.HorizontalAlignment = "Left"
                            $radioButton.Margin = $theme.CheckBoxMargin
                            $radioButton.FontSize = $theme.ButtonFontSize
                            $radioButton.ToolTip = $entryInfo.Description

                            if ($entryInfo.Checked -eq $true) {
                                $radioButton.IsChecked = $true
                            }

                            $stackPanel.Children.Add($radioButton) | Out-Null
                            $sync[$entryInfo.Name] = $radioButton
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
}
