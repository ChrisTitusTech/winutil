function Initialize-InstallAppEntry {
    <#
        .SYNOPSIS
            Creates the app entry to be placed on the isntall tab for a given app
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Element into which the Apps should be placed
        .PARAMETER AppKey
            The Key of the app inside the $sync.configs.applicationsHashtable
    #>
        param(
            [Windows.Controls.WrapPanel]$TargetElement,
            $AppKey
        )
        $App = $sync.configs.applicationsHashtable.$AppKey
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
            if (($sync.$($this.Tag).IsChecked) -eq $false) {
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallHighlightedColor")
            }
        })
        $border.Add_MouseLeave({
            if (($sync.$($this.Tag).IsChecked) -eq $false) {
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
            Invoke-WPFSelectedAppsUpdate -type "Add" -checkbox $this
            $borderElement = $this.Parent.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallSelectedColor")
        })

        $checkbox.Add_Unchecked({
            Invoke-WPFSelectedAppsUpdate -type "Remove" -checkbox $this
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

        # Add the border to the corresponding Category
        $TargetElement.Children.Add($border) | Out-Null
    }
