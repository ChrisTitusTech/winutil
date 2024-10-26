function Set-CategoryVisibility {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.ItemsControl]$ItemsControl,
        [bool]$isChecked = $true,
        [switch]$automaticVisibility
    )
    if ($automaticVisibility) {
        $isChecked = $sync.CompactView
    }

    # If all the Categories are affected, update the Checked state of the ToggleButtons.
    # Otherwise, the state is not synced when toggling between the display modes
    if  ($category -eq "*") {
        $items = $ItemsControl.Items | Where-Object {($_.Tag -like "CategoryWrapPanel_*")}
        $ItemsControl.Items | Where-Object {($_.Tag -eq "CategoryToggleButton")} | Foreach-Object { $_.Visibility = [Windows.Visibility]::Visible; $_.IsChecked = $isChecked }
    } else {
        $items = $ItemsControl.Items | Where-Object {($_.Tag -eq "CategoryWrapPanel_$Category")}
    }

    $elementVisibility = if ($isChecked -eq $true) {[Windows.Visibility]::Visible} else {[Windows.Visibility]::Collapsed}
    $items | ForEach-Object {
        $_.Visibility = $elementVisibility
        }
    $items.Children | ForEach-Object {
        $_.Visibility = $elementVisibility
    }
}

function Find-AppsByNameOrDescription {
    param(
        [Parameter(Mandatory=$false)]
        [string]$SearchString = "",
        [Parameter(Mandatory=$false)]
        [System.Windows.Controls.ItemsControl]$ItemsControl = $sync.ItemsControl
    )

    if ([string]::IsNullOrWhiteSpace($SearchString)) {
            Set-CategoryVisibility -Category "*" -ItemsControl $ItemsControl -automaticVisibility


        $ItemsControl.Items | ForEach-Object {
            if ($_.Tag -like "CategoryWrapPanel_*") {
                # If CompactView is enabled, show all Apps when the search bar is empty
                # otherwise, hide all Apps
                if ($sync.CompactView -eq $true) {
                $_.Visibility = [Windows.Visibility]::Visible
                } else {
                    $_.Visibility = [Windows.Visibility]::Collapsed
                }
                # Reset Items visibility
                $_.Children | ForEach-Object {$_.Visibility = [Windows.Visibility]::Visible}
            }
            else {
                # Reset Rest (Category Label) visibility
                $_.Visibility = [Windows.Visibility]::Visible
            }
        }
    } else {
        $ItemsControl.Items | ForEach-Object {
            # Hide all CategoryWrapPanel and ToggleButton
            $_.Visibility = [Windows.Visibility]::Collapsed
            if ($_.Tag -like "CategoryWrapPanel_*") {
                # Search for Apps that match the search string
                $_.Children | Foreach-Object {
                    if ($sync.configs.applicationsHashtable.$($_.Tag).Content -like "*$SearchString*") {
                        # Show the App and the parent CategoryWrapPanel
                        $_.Visibility = [Windows.Visibility]::Visible
                        $_.parent.Visibility = [Windows.Visibility]::Visible
                    }
                    else {
                        $_.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }
        }
    }
}

function Show-OnlyCheckedApps {
    param (
        [Parameter(Mandatory=$false)]
        [String[]]$appKeys,
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.ItemsControl]$ItemsControl
    )
    # If no apps are selected, do not allow switching to show only selected
    if (($false -eq $sync.ShowOnlySelected) -and ($appKeys.Count -eq 0)) {
        Write-Host "No apps selected"
        $sync.wpfselectedfilter.IsChecked = $false
        return
    }
    $sync.ShowOnlySelected = -not $sync.ShowOnlySelected
    if ($sync.ShowOnlySelected) {
        $sync.Buttons | Where-Object {$_.Name -like "ShowSelectedAppsButton"} | ForEach-Object {
            $_.Content = "Show All"
        }

        $ItemsControl.Items | Foreach-Object {
            # Search for App Container and set them to visible
            if ($_.Tag -like "CategoryWrapPanel_*") {
                $_.Visibility = [Windows.Visibility]::Visible
                # Iterate through all the apps in the container and set them to visible if they are in the appKeys array
                $_.Children | ForEach-Object {
                    if ($appKeys -contains $_.Tag) {
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                    else {
                        $_.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }
            else {
                # Set all other items to collapsed
                $_.Visibility = [Windows.Visibility]::Collapsed
            }
        }
    } else {
        $sync.Buttons | Where-Object {$_.Name -like "ShowSelectedAppsButton"} | ForEach-Object {
            $_.Content = "Show Selected"
        }
        Set-CategoryVisibility -Category "*" -ItemsControl $ItemsControl -automaticVisibility
    }
}

function Invoke-WPFUIApps {
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject[]]$Apps,
        [Parameter(Mandatory, Position = 1)]
        [string]$TargetGridName
    )

    function Initialize-StackPanel {
        $targetGrid = $window.FindName($TargetGridName)
        $borderStyle = $window.FindResource("BorderStyle")

        $null = $targetGrid.Children.Clear()

        $mainBorder = New-Object Windows.Controls.Border
        $mainBorder.VerticalAlignment = "Stretch"
        $mainBorder.Style = $borderStyle

        $null = $targetGrid.Children.Add($mainBorder)
        return $targetGrid
    }

    function Initialize-Header {
        param($TargetGrid)
        $mainBorder = $TargetGrid.Children[0]
        $dockPanel = New-Object Windows.Controls.DockPanel
        $mainBorder.Child = $dockPanel

        function New-WPFButton {
            param (
                [string]$Name,
                [string]$Content
            )
            $button = New-Object Windows.Controls.Button
            $button.Name = $Name
            $button.Content = $Content
            $button.Margin = New-Object Windows.Thickness(2)
            $button.HorizontalAlignment = "Stretch"
            return $button
        }

        $wrapPanelTop = New-Object Windows.Controls.WrapPanel
        $wrapPanelTop.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
        $wrapPanelTop.HorizontalAlignment = "Left"
        $wrapPanelTop.VerticalAlignment = "Top"
        $wrapPanelTop.Orientation = "Horizontal"
        $wrapPanelTop.Margin = $window.FindResource("TabContentMargin")

        $buttonConfigs = @(
            @{Name="WPFInstall"; Content="Install/Upgrade Selected"},
            @{Name="WPFInstallUpgrade"; Content="Upgrade All"},
            @{Name="WPFUninstall"; Content="Uninstall Selected"}
        )

        foreach ($config in $buttonConfigs) {
            $button = New-WPFButton -Name $config.Name -Content $config.Content
            $null = $wrapPanelTop.Children.Add($button)
            $sync[$config.Name] = $button
        }

        $selectedLabel = New-Object Windows.Controls.Label
        $selectedLabel.Name = "WPFSelectedLabel"
        $selectedLabel.Content = "Selected Apps: 0"
        $selectedLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSizeHeading")
        $selectedLabel.SetResourceReference([Windows.Controls.Control]::MarginProperty, "TabContentMargin")
        $selectedLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $selectedLabel.HorizontalAlignment = "Center"
        $selectedLabel.VerticalAlignment = "Center"

        $null = $wrapPanelTop.Children.Add($selectedLabel)
        $sync.$($selectedLabel.Name) = $selectedLabel

        [Windows.Controls.DockPanel]::SetDock($wrapPanelTop, [Windows.Controls.Dock]::Top)
        $null = $dockPanel.Children.Add($wrapPanelTop)
        return $dockPanel
    }

    function Initialize-AppArea {
        param($TargetGrid)
        $scrollViewer = New-Object Windows.Controls.ScrollViewer
        $scrollViewer.VerticalScrollBarVisibility = 'Auto'
        $scrollViewer.HorizontalAlignment = 'Stretch'
        $scrollViewer.VerticalAlignment = 'Stretch'
        $scrollViewer.CanContentScroll = $true

        $itemsControl = New-Object Windows.Controls.ItemsControl
        $itemsControl.HorizontalAlignment = 'Stretch'
        $itemsControl.VerticalAlignment = 'Stretch'

        $itemsPanelTemplate = New-Object Windows.Controls.ItemsPanelTemplate
        $factory = New-Object Windows.FrameworkElementFactory ([Windows.Controls.VirtualizingStackPanel])
        $itemsPanelTemplate.VisualTree = $factory
        $itemsControl.ItemsPanel = $itemsPanelTemplate

        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [Windows.Controls.VirtualizationMode]::Recycling)

        $scrollViewer.Content = $itemsControl

        [Windows.Controls.DockPanel]::SetDock($scrollViewer, [Windows.Controls.Dock]::Bottom)
        $null = $TargetGrid.Children.Add($scrollViewer)
        return $itemsControl
    }

    function Add-Category {
        param(
            [string]$Category,
            $ItemsControl
        )

        $toggleButton = New-Object Windows.Controls.Primitives.ToggleButton
        $toggleButton.Content = "$Category"
        $toggleButton.Tag = "CategoryToggleButton"
        $toggleButton.Cursor = [System.Windows.Input.Cursors]::Hand
        $toggleButton.Style = $window.FindResource("CategoryToggleButtonStyle")
        $sync.Buttons.Add($toggleButton)
        $toggleButton.Add_Checked({
            # Clear the search bar when a category is clicked
            $sync.SearchBar.Text = ""
            Set-CategoryVisibility -Category $this.Content -ItemsControl $this.Parent -isChecked $true
        })
        $toggleButton.Add_Unchecked({
            Set-CategoryVisibility -Category $this.Content -ItemsControl $this.Parent -isChecked $false
        })
        $null = $ItemsControl.Items.Add($toggleButton)
    }

    function New-CategoryAppList {
        param(
            $TargetGrid,
            $Apps
        )
        $loadingLabel = New-Object Windows.Controls.Label
        $loadingLabel.Content = "Loading, please wait..."
        $loadingLabel.HorizontalAlignment = "Center"
        $loadingLabel.VerticalAlignment = "Center"
        $loadingLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSizeHeading")
        $loadingLabel.FontWeight = [Windows.FontWeights]::Bold
        $loadingLabel.Foreground = [Windows.Media.Brushes]::Gray
        $sync.LoadingLabel = $loadingLabel

        $itemsControl.Items.Clear()
        $null = $itemsControl.Items.Add($sync.LoadingLabel)

        $itemsControl.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
            $itemsControl.Items.Clear()

            $categories = $Apps.Values | Select-Object -ExpandProperty category -Unique | Sort-Object
            foreach ($category in $categories) {
                Add-Category -Category $category -ItemsControl $itemsControl
                $wrapPanel = New-Object Windows.Controls.WrapPanel
                $wrapPanel.Orientation = "Horizontal"
                $wrapPanel.HorizontalAlignment = "Stretch"
                $wrapPanel.VerticalAlignment = "Center"
                $wrapPanel.Margin = New-Object Windows.Thickness(0, 0, 0, 20)
                $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                $wrapPanel.Tag = "CategoryWrapPanel_$category"
                $null = $itemsControl.Items.Add($wrapPanel)
                $Apps.Keys | Where-Object { $Apps.$_.Category -eq $category } | Sort-Object | ForEach-Object {
                    New-AppEntry -WrapPanel $wrapPanel -AppKey $_
                }
            }
        })
    }

    function New-AppEntry {
        param(
            $WrapPanel,
            $AppKey
        )
        $App = $Apps.$AppKey
        # Create the outer Border for the application type
        $border = New-Object Windows.Controls.Border
        $border.BorderBrush = [Windows.Media.Brushes]::Gray
        $border.SetResourceReference([Windows.Controls.Control]::BorderThicknessProperty, "AppTileBorderThickness")
        $border.CornerRadius = 5
        $border.SetResourceReference([Windows.Controls.Control]::PaddingProperty, "AppTileMargins")
        $border.SetResourceReference([Windows.Controls.Control]::WidthProperty, "AppTileWidth")
        $border.VerticalAlignment = "Top"
        $border.SetResourceReference([Windows.Controls.Control]::MarginProperty, "AppTileMargins")
        $border.Cursor = [System.Windows.Input.Cursors]::Hand
        $border.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
        $border.Tag = $Appkey
        $border.ToolTip = $App.description
        $border.Add_MouseUp({
            $childCheckbox = ($this.Child.Children | Where-Object {$_.Template.TargetType -eq [System.Windows.Controls.Checkbox]})[0]
            $childCheckBox.isChecked = -not $childCheckbox.IsChecked
        })
        $border.Add_MouseEnter({
            if (($sync.$($this.Tag).IsChecked) -eq $false){
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallHighlightedColor")
            }
        })
        $border.Add_MouseLeave({
            if (($sync.$($this.Tag).IsChecked) -eq $false){
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
            }
        })
        # Create a DockPanel inside the Border
        $dockPanel = New-Object Windows.Controls.DockPanel
        $dockPanel.LastChildFill = $true
        $border.Child = $dockPanel

        # Create the CheckBox, vertically centered
        $checkBox = New-Object Windows.Controls.CheckBox
        $checkBox.Name = $AppKey
        $checkBox.Background = "Transparent"
        $checkBox.HorizontalAlignment = "Left"
        $checkBox.VerticalAlignment = "Center"
        $checkBox.SetResourceReference([Windows.Controls.Control]::MarginProperty, "AppTileMargins")
        $checkBox.SetResourceReference([Windows.Controls.Control]::StyleProperty, "CollapsedCheckBoxStyle")
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
        $sync.$($checkBox.Name) = $checkBox
        # Create a StackPanel for the image and name
        $imageAndNamePanel = New-Object Windows.Controls.StackPanel
        $imageAndNamePanel.Orientation = "Horizontal"
        $imageAndNamePanel.VerticalAlignment = "Center"

        # Create the Image and set a placeholder
        $image = New-Object Windows.Controls.Image
        # $image.Name = "wpfapplogo" + $App.Name
        $image.Width = 40
        $image.Height = 40
        $image.Margin = New-Object Windows.Thickness(0, 0, 10, 0)
        $image.Source = $noimage  # Ensure $noimage is defined in your script

        # Clip the image corners
        $image.Clip = New-Object Windows.Media.RectangleGeometry
        $image.Clip.Rect = New-Object Windows.Rect(0, 0, $image.Width, $image.Height)
        $image.Clip.RadiusX = 5
        $image.Clip.RadiusY = 5
        $image.SetResourceReference([Windows.Controls.Control]::VisibilityProperty, "AppTileCompactVisibility")

        $imageAndNamePanel.Children.Add($image) | Out-Null

        # Create the TextBlock for the application name
        $appName = New-Object Windows.Controls.TextBlock
        $appName.Text = $App.Content
        $appName.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "AppTileFontSize")
        $appName.FontWeight = [Windows.FontWeights]::Bold
        $appName.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $appName.VerticalAlignment = "Center"
        $appName.SetResourceReference([Windows.Controls.Control]::MarginProperty, "AppTileMargins")
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
        $buttonPanel.SetResourceReference([Windows.Controls.Control]::MarginProperty, "AppTileMargins")
        $buttonPanel.SetResourceReference([Windows.Controls.Control]::VisibilityProperty, "AppTileCompactVisibility")
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
        $installButton.ToolTip = "Install or Upgrade the application"
        $buttonPanel.Children.Add($installButton) | Out-Null

        # Add Click event for the "Install" button
        $installButton.Add_Click({
            $appKey = $this.Parent.Parent.Parent.Tag
            $appObject = $sync.configs.applicationsHashtable.$appKey
            Invoke-WPFInstall -PackagesToInstall $appObject
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

        $uninstallButton.ToolTip = "Uninstall the application"
        $uninstallButton.Add_Click({
            $appKey = $this.Parent.Parent.Parent.Tag
            $appObject = $sync.configs.applicationsHashtable.$appKey
            Invoke-WPFUnInstall -PackagesToUninstall $appObject
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
        $infoButton.ToolTip = "Open the application's website in your default browser"
        $buttonPanel.Children.Add($infoButton) | Out-Null

        $infoButton.Add_Click({
            $appKey = $this.Parent.Parent.Parent.Tag
            $appObject = $sync.configs.applicationsHashtable.$appKey
            Start-Process $appObject.link
        })

        # Add the button panel to the DockPanel
        $dockPanel.Children.Add($buttonPanel) | Out-Null

        # Add the border to the main items control in the grid
        $wrapPanel.Children.Add($border) | Out-Null
    }


    $window = $sync.Form

    switch ($TargetGridName) {
        "appspanel" {
            $targetGrid = Initialize-StackPanel
            $dockPanelContainer = Initialize-Header -TargetGrid $targetGrid
            $itemsControl = Initialize-AppArea -TargetGrid $dockPanelContainer
            $sync.ItemsControl = $itemsControl
            New-CategoryAppList -TargetGrid $itemsControl -Apps $Apps
        }
        default {
            Write-Output "$TargetGridName not yet implemented"
        }
    }
}

