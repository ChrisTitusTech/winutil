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
        Future me/contributor: If possible, please wrap this into a runspace to make it load all panels at the same time.
    #>

    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject]$configVariable,

        [Parameter(Mandatory, Position = 1)]
        [string]$targetGridName,

        [Parameter(Mandatory, Position = 2)]
        [int]$columncount
    )

    $window = $sync.form

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

    $radioButtonGroups = @{}

    $organizedData = @{}
    # Iterate through JSON data and organize by panel and category
    foreach ($entry in $configHashtable.Keys) {
        $entryInfo = $configHashtable[$entry]

        # Create an object for the application
        $entryObject = [PSCustomObject]@{
            Name        = $entry
            Order       = $entryInfo.order
            Category    = $entryInfo.Category
            Content     = $entryInfo.Content
            Choco       = $entryInfo.choco
            Winget      = $entryInfo.winget
            Panel       = if ($entryInfo.Panel) { $entryInfo.Panel } else { "0" }
            Link        = $entryInfo.link
            Description = $entryInfo.description
            Type        = $entryInfo.type
            ComboItems  = $entryInfo.ComboItems
            Checked     = $entryInfo.Checked
            ButtonWidth = $entryInfo.ButtonWidth
            GroupName   = $entryInfo.GroupName  # Added for RadioButton groupings
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

    # Initialize panel count
    $panelcount = 0

    # Iterate through 'organizedData' by panel, category, and application
    $count = 0
    foreach ($panelKey in ($organizedData.Keys | Sort-Object)) {
        # Create a Border for each column
        $border = New-Object Windows.Controls.Border
        $border.VerticalAlignment = "Stretch" # Ensure the border stretches vertically
        [System.Windows.Controls.Grid]::SetColumn($border, $panelcount)
        $border.style = $borderstyle
        $targetGrid.Children.Add($border) | Out-Null

        # Use a DockPanel to contain both the top buttons and the main content
        $dockPanelContainer = New-Object Windows.Controls.DockPanel
        $border.Child = $dockPanelContainer

        # Check if configVariable equals $sync.configs.applications
        if ($configVariable -eq $sync.configs.applications) {
            # Create a WrapPanel to hold buttons at the top
            $wrapPanelTop = New-Object Windows.Controls.WrapPanel
            $wrapPanelTop.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
            $wrapPanelTop.HorizontalAlignment = "Left"
            $wrapPanelTop.VerticalAlignment = "Top"
            $wrapPanelTop.Orientation = "Horizontal"
            $wrapPanelTop.Margin = $window.FindResource("TabContentMargin")

            # Create buttons and add them to the WrapPanel with dynamic widths
            $installButton = New-Object Windows.Controls.Button
            $installButton.Name = "WPFInstall"
            $installButton.Content = "Install/Upgrade Selected"
            $installButton.Margin = New-Object Windows.Thickness(2)
            $installButton.HorizontalAlignment = "Stretch"
            $wrapPanelTop.Children.Add($installButton) | Out-Null
            $sync["WPFInstall"] = $installButton

            $upgradeButton = New-Object Windows.Controls.Button
            $upgradeButton.Name = "WPFInstallUpgrade"
            $upgradeButton.Content = "Upgrade All"
            $upgradeButton.Margin = New-Object Windows.Thickness(2)
            $upgradeButton.HorizontalAlignment = "Stretch"
            $wrapPanelTop.Children.Add($upgradeButton) | Out-Null
            $sync["WPFInstallUpgrade"] = $upgradeButton

            $uninstallButton = New-Object Windows.Controls.Button
            $uninstallButton.Name = "WPFUninstall"
            $uninstallButton.Content = "Uninstall Selected"
            $uninstallButton.Margin = New-Object Windows.Thickness(2)
            $uninstallButton.HorizontalAlignment = "Stretch"
            $wrapPanelTop.Children.Add($uninstallButton) | Out-Null
            $sync["WPFUninstall"] = $uninstallButton

            $selectedLabel = New-Object Windows.Controls.Label
            $selectedLabel.Name = "WPFSelectedLabel"
            $selectedLabel.Content = "Selected Apps: 0"
            $selectedLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSizeHeading")
            $selectedLabel.SetResourceReference([Windows.Controls.Control]::MarginProperty, "TabContentMargin")
            $selectedLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $selectedLabel.HorizontalAlignment = "Center"
            $selectedLabel.VerticalAlignment = "Center"

            $wrapPanelTop.Children.Add($selectedLabel) | Out-null
            $sync.$($selectedLabel.Name) = $selectedLabel

            # Dock the WrapPanel at the top of the DockPanel
            [Windows.Controls.DockPanel]::SetDock($wrapPanelTop, [Windows.Controls.Dock]::Top)
            $dockPanelContainer.Children.Add($wrapPanelTop) | Out-Null
        }

        # Create a ScrollViewer to contain the main content (excluding buttons)
        $scrollViewer = New-Object Windows.Controls.ScrollViewer
        $scrollViewer.VerticalScrollBarVisibility = 'Auto'
        $scrollViewer.HorizontalScrollBarVisibility = 'Auto'
        $scrollViewer.HorizontalAlignment = 'Stretch'
        $scrollViewer.VerticalAlignment = 'Stretch'
        $scrollViewer.CanContentScroll = $true  # Enable virtualization

        # Create an ItemsControl inside the ScrollViewer for application content
        $itemsControl = New-Object Windows.Controls.ItemsControl
        $itemsControl.HorizontalAlignment = 'Stretch'
        $itemsControl.VerticalAlignment = 'Stretch'

        # Set the ItemsPanel to a VirtualizingStackPanel
        $itemsPanelTemplate = New-Object Windows.Controls.ItemsPanelTemplate
        $factory = New-Object Windows.FrameworkElementFactory ([Windows.Controls.VirtualizingStackPanel])
        $itemsPanelTemplate.VisualTree = $factory
        $itemsControl.ItemsPanel = $itemsPanelTemplate

        # Set virtualization properties
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [Windows.Controls.VirtualizationMode]::Recycling)

        # Add the ItemsControl to the ScrollViewer
        $scrollViewer.Content = $itemsControl

        # Add the ScrollViewer to the DockPanel (it will be below the top buttons StackPanel)
        [Windows.Controls.DockPanel]::SetDock($scrollViewer, [Windows.Controls.Dock]::Bottom)
        $dockPanelContainer.Children.Add($scrollViewer) | Out-Null
        $panelcount++

        # Now proceed with adding category labels and entries to $itemsControl
        foreach ($category in ($organizedData[$panelKey].Keys | Sort-Object)) {
            $count++

            $label = New-Object Windows.Controls.Label
            $label.Content = $category -replace ".*__", ""
            $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSizeHeading")
            $label.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
            $itemsControl.Items.Add($label) | Out-Null

            $sync[$category] = $label

            # Sort entries by Order and then by Name
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
                    $border.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
                    $border.Add_MouseUp({
                        $childCheckbox = ($this.Child.Children | Where-Object {$_.Template.TargetType -eq [System.Windows.Controls.Checkbox]})[0]
                        $childCheckBox.isChecked = -not $childCheckbox.IsChecked
                    })
                    # Create a DockPanel inside the Border
                    $dockPanel = New-Object Windows.Controls.DockPanel
                    $dockPanel.LastChildFill = $true
                    $border.Child = $dockPanel

                    # Create the CheckBox, vertically centered
                    $checkBox = New-Object Windows.Controls.CheckBox
                    $checkBox.Name = $entryInfo.Name
                    $checkBox.Background = "Transparent"
                    $checkBox.HorizontalAlignment = "Left"
                    $checkBox.VerticalAlignment = "Center"
                    $checkBox.Margin = New-Object Windows.Thickness(5, 0, 10, 0)
                    $checkbox.Add_Checked({
                        Invoke-WPFSelectedLabelUpdate -type "Add" -checkbox $this
                        $borderElement = $this.Parent.Parent
                        $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallSelectedColor")
                    })

                    $checkbox.Add_Unchecked({
                        Invoke-WPFSelectedLabelUpdate -type "Remove" -checkbox $this
                        $borderElement = $this.Parent.Parent
                        $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
                    })
                    # Create a StackPanel for the image and name
                    $imageAndNamePanel = New-Object Windows.Controls.StackPanel
                    $imageAndNamePanel.Orientation = "Horizontal"
                    $imageAndNamePanel.VerticalAlignment = "Center"

                    # Create the Image and set a placeholder
                    $image = New-Object Windows.Controls.Image
                    $image.Name = "wpfapplogo" + $entryInfo.Name
                    $image.Width = 40
                    $image.Height = 40
                    $image.Margin = New-Object Windows.Thickness(0, 0, 10, 0)
                    $image.Source = $noimage  # Ensure $noimage is defined in your script

                    # Clip the image corners
                    $image.Clip = New-Object Windows.Media.RectangleGeometry
                    $image.Clip.Rect = New-Object Windows.Rect(0, 0, $image.Width, $image.Height)
                    $image.Clip.RadiusX = 5
                    $image.Clip.RadiusY = 5

                    $imageAndNamePanel.Children.Add($image) | Out-Null

                    # Create the TextBlock for the application name
                    $appName = New-Object Windows.Controls.TextBlock
                    $appName.Text = $entryInfo.Content
                    $appName.FontSize = 16
                    $appName.FontWeight = [Windows.FontWeights]::Bold
                    $appName.VerticalAlignment = "Center"
                    $appName.Margin = New-Object Windows.Thickness(5, 0, 0, 0)
                    $appName.Background = "Transparent"
                    $imageAndNamePanel.Children.Add($appName) | Out-Null

                    # Add the image and name panel to the Checkbox
                    $checkBox.Content = $imageAndNamePanel

                    # Add the checkbox to the DockPanel
                    [Windows.Controls.DockPanel]::SetDock($checkBox, [Windows.Controls.Dock]::Left)
                    $dockPanel.Children.Add($checkBox) | Out-Null

                    # Create the StackPanel for the buttons and dock it to the right
                    $buttonPanel = New-Object Windows.Controls.StackPanel
                    $buttonPanel.Orientation = "Horizontal"
                    $buttonPanel.HorizontalAlignment = "Right"
                    $buttonPanel.VerticalAlignment = "Center"
                    $buttonPanel.Margin = New-Object Windows.Thickness(10, 0, 0, 0)
                    [Windows.Controls.DockPanel]::SetDock($buttonPanel, [Windows.Controls.Dock]::Right)

                    # Create the "Install" button
                    $installButton = New-Object Windows.Controls.Button
                    $installButton.Width = 45
                    $installButton.Height = 35
                    $installButton.Margin = New-Object Windows.Thickness(0, 0, 10, 0)

                    $installIcon = New-Object Windows.Controls.TextBlock
                    $installIcon.Text = [char]0xE118  # Install Icon
                    $installIcon.FontFamily = "Segoe MDL2 Assets"
                    $installIcon.FontSize = 20
                    $installIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                    $installIcon.Background = "Transparent"
                    $installIcon.HorizontalAlignment = "Center"
                    $installIcon.VerticalAlignment = "Center"

                    $installButton.Content = $installIcon
                    $buttonPanel.Children.Add($installButton) | Out-Null

                    # Add Click event for the "Install" button
                    $installButton.Add_Click({
                        Write-Host "Installing $($entryInfo.Name) ..."
                    })

                    # Create the "Uninstall" button
                    $uninstallButton = New-Object Windows.Controls.Button
                    $uninstallButton.Width = 45
                    $uninstallButton.Height = 35

                    $uninstallIcon = New-Object Windows.Controls.TextBlock
                    $uninstallIcon.Text = [char]0xE74D  # Uninstall Icon
                    $uninstallIcon.FontFamily = "Segoe MDL2 Assets"
                    $uninstallIcon.FontSize = 20
                    $uninstallIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                    $uninstallIcon.Background = "Transparent"
                    $uninstallIcon.HorizontalAlignment = "Center"
                    $uninstallIcon.VerticalAlignment = "Center"

                    $uninstallButton.Content = $uninstallIcon
                    $buttonPanel.Children.Add($uninstallButton) | Out-Null

                    $uninstallButton.Add_Click({
                        Write-Host "Uninstalling $($entryInfo.Name) ..."
                    })

                    # Create the "Info" button
                    $infoButton = New-Object Windows.Controls.Button
                    $infoButton.Width = 45
                    $infoButton.Height = 35
                    $infoButton.Margin = New-Object Windows.Thickness(10, 0, 0, 0)

                    $infoIcon = New-Object Windows.Controls.TextBlock
                    $infoIcon.Text = [char]0xE946  # Info Icon
                    $infoIcon.FontFamily = "Segoe MDL2 Assets"
                    $infoIcon.FontSize = 20
                    $infoIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                    $infoIcon.Background = "Transparent"
                    $infoIcon.HorizontalAlignment = "Center"
                    $infoIcon.VerticalAlignment = "Center"

                    $infoButton.Content = $infoIcon
                    $buttonPanel.Children.Add($infoButton) | Out-Null

                    $infoButton.Add_Click({
                        Write-Host "Getting info for $($entryInfo.Name) ..."
                    })

                    # Add the button panel to the DockPanel
                    $dockPanel.Children.Add($buttonPanel) | Out-Null

                    # Add the border to the main items control in the grid
                    $itemsControl.Items.Add($border) | Out-Null

                    # Sync the CheckBox, buttons, and info to the sync object for further use
                    $sync[$entryInfo.Name] = $checkBox
                    $sync[$entryInfo.Name + "_InstallButton"] = $installButton
                    $sync[$entryInfo.Name + "_UninstallButton"] = $uninstallButton
                    $sync[$entryInfo.Name + "_InfoButton"] = $infoButton

                    $image.Source = $noimage
                    if (-not [string]::IsNullOrEmpty($none)) { # replace $none with $entryInfo.choco to get images, takes a lot longer but works for many packages
                        try {
                            $packageinfo = (choco info $entryInfo.choco --limit-output).Split(' ')[0]
                            $packageinfo = $packageinfo -replace '\|', '.'
                            $iconlink = "https://community.chocolatey.org/content/packageimages/" + $packageinfo
                            $finishediconlink = $iconlink + ".png"
                            $webimage = Invoke-WebRequest -Uri $finishediconlink -Method Head -ErrorAction SilentlyContinue
                            if ($webimage.StatusCode -eq 200) {
                                $image.Source = [Windows.Media.Imaging.BitmapImage]::new([Uri]::new($finishediconlink))
                            } else {
                                # TODO: use UniGetUI's image db as a fallback
                                $image.Source = $noimage
                            }
                        } catch {
                            $image.Source = $noimage
                        }
                    }

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
                            $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
                            $label.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                            $dockPanel.Children.Add($label) | Out-Null
                            $itemsControl.Items.Add($dockPanel) | Out-Null

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
                            $toggleButton.HorizontalAlignment = "Left"
                            $toggleButton.SetResourceReference([Windows.Controls.Control]::HeightProperty, "TabButtonHeight")
                            $toggleButton.SetResourceReference([Windows.Controls.Control]::WidthProperty, "TabButtonWidth")
                            $toggleButton.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ButtonInstallBackgroundColor")
                            $toggleButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                            $toggleButton.FontWeight = [Windows.FontWeights]::Bold

                            $textBlock = New-Object Windows.Controls.TextBlock
                            $textBlock.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "TabButtonFontSize")
                            $textBlock.Background = [Windows.Media.Brushes]::Transparent
                            $textBlock.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "ButtonInstallForegroundColor")

                            $underline = New-Object Windows.Documents.Underline
                            $underline.Inlines.Add($entryInfo.Name -replace "(.).*", "$1")

                            $run = New-Object Windows.Documents.Run
                            $run.Text = $entryInfo.Name -replace "^.", ""

                            $textBlock.Inlines.Add($underline)
                            $textBlock.Inlines.Add($run)

                            $toggleButton.Content = $textBlock

                            $itemsControl.Items.Add($toggleButton) | Out-Null

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
                            $label.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")
                            $horizontalStackPanel.Children.Add($label) | Out-Null

                            $comboBox = New-Object Windows.Controls.ComboBox
                            $comboBox.Name = $entryInfo.Name
                            $comboBox.SetResourceReference([Windows.Controls.Control]::HeightProperty, "ButtonHeight")
                            $comboBox.SetResourceReference([Windows.Controls.Control]::WidthProperty, "ButtonWidth")
                            $comboBox.HorizontalAlignment = "Left"
                            $comboBox.VerticalAlignment = "Center"
                            $comboBox.SetResourceReference([Windows.Controls.Control]::MarginProperty, "ButtonMargin")

                            foreach ($comboitem in ($entryInfo.ComboItems -split " ")) {
                                $comboBoxItem = New-Object Windows.Controls.ComboBoxItem
                                $comboBoxItem.Content = $comboitem
                                $comboBoxItem.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")
                                $comboBox.Items.Add($comboBoxItem) | Out-Null
                            }

                            $horizontalStackPanel.Children.Add($comboBox) | Out-Null
                            $itemsControl.Items.Add($horizontalStackPanel) | Out-Null

                            $comboBox.SelectedIndex = 0

                            $sync[$entryInfo.Name] = $comboBox
                        }

                        "Button" {
                            $button = New-Object Windows.Controls.Button
                            $button.Name = $entryInfo.Name
                            $button.Content = $entryInfo.Content
                            $button.HorizontalAlignment = "Left"
                            $button.SetResourceReference([Windows.Controls.Control]::MarginProperty, "ButtonMargin")
                            $button.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")
                            if ($entryInfo.ButtonWidth) {
                                $button.Width = $entryInfo.ButtonWidth
                            }
                            $itemsControl.Items.Add($button) | Out-Null

                            $sync[$entryInfo.Name] = $button
                        }

                        "RadioButton" {
                            # Check if a container for this GroupName already exists
                            if (-not $radioButtonGroups.ContainsKey($entryInfo.GroupName)) {
                                # Create a StackPanel for this group
                                $groupStackPanel = New-Object Windows.Controls.StackPanel
                                $groupStackPanel.Orientation = "Vertical"

                                # Add the group container to the ItemsControl
                                $itemsControl.Items.Add($groupStackPanel) | Out-Null
                            } else {
                                # Retrieve the existing group container
                                $groupStackPanel = $radioButtonGroups[$entryInfo.GroupName]
                            }

                            # Create the RadioButton
                            $radioButton = New-Object Windows.Controls.RadioButton
                            $radioButton.Name = $entryInfo.Name
                            $radioButton.GroupName = $entryInfo.GroupName
                            $radioButton.Content = $entryInfo.Content
                            $radioButton.HorizontalAlignment = "Left"
                            $radioButton.SetResourceReference([Windows.Controls.Control]::MarginProperty, "CheckBoxMargin")
                            $radioButton.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "ButtonFontSize")
                            $radioButton.ToolTip = $entryInfo.Description

                            if ($entryInfo.Checked -eq $true) {
                                $radioButton.IsChecked = $true
                            }

                            # Add the RadioButton to the group container
                            $groupStackPanel.Children.Add($radioButton) | Out-Null
                            $sync[$entryInfo.Name] = $radioButton
                        }

                        default {
                            $horizontalStackPanel = New-Object Windows.Controls.StackPanel
                            $horizontalStackPanel.Orientation = "Horizontal"

                            $checkBox = New-Object Windows.Controls.CheckBox
                            $checkBox.Name = $entryInfo.Name
                            $checkBox.Content = $entryInfo.Content
                            $checkBox.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSize")
                            $checkBox.ToolTip = $entryInfo.Description
                            $checkBox.SetResourceReference([Windows.Controls.Control]::MarginProperty, "CheckBoxMargin")
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

                            $itemsControl.Items.Add($horizontalStackPanel) | Out-Null
                            $sync[$entryInfo.Name] = $checkBox
                        }
                    }
                }
            }
        }
    }
}
