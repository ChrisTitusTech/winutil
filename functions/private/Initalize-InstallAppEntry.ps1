function Initialize-InstallAppEntry {
    <#
        .SYNOPSIS
            Creates the app entry to be placed on the isntall tab for a given app
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Element into which the Apps should be placed
        .PARAMETER appKey
            The Key of the app inside the $sync.configs.applicationsHashtable
    #>
        param(
            [Windows.Controls.WrapPanel]$TargetElement,
            $appKey
        )

        # Create the outer Border for the application type
        $border = New-Object Windows.Controls.Border
        $border.Style = $sync.Form.Resources.AppTileBorderStyle
        $border.Tag = $appKey
        $border.ToolTip = $Apps.$appKey.description
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
        $checkBox.Name = $appKey
        $checkbox.Style = $sync.Form.Resources.AppTileCheckboxStyle
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

        # Create a StackPanel for the image and name
        $imageAndNamePanel = New-Object Windows.Controls.StackPanel
        $imageAndNamePanel.Orientation = "Horizontal"
        $imageAndNamePanel.VerticalAlignment = "Center"

        # Create the Image and set a placeholder
        $image = New-Object Windows.Controls.Image
        # $image.Name = "wpfapplogo" + $App.Name
        $image.Style = $sync.Form.Resources.AppTileImageStyle
        $image.Source = $noimage  # Ensure $noimage is defined in your script

        $imageAndNamePanel.Children.Add($image) | Out-Null

        # Create the TextBlock for the application name
        $appName = New-Object Windows.Controls.TextBlock
        $appName.Style = $sync.Form.Resources.AppTileNameStyle
        $appName.Text = $Apps.$appKey.content
        $imageAndNamePanel.Children.Add($appName) | Out-Null

        # Add the image and name panel to the Checkbox
        $checkBox.Content = $imageAndNamePanel

        # Add the checkbox to the DockPanel
        [Windows.Controls.DockPanel]::SetDock($checkBox, [Windows.Controls.Dock]::Left)
        $dockPanel.Children.Add($checkBox) | Out-Null

        # Create the StackPanel for the buttons and dock it to the right
        $buttonPanel = New-Object Windows.Controls.StackPanel
        $buttonPanel.Style = $sync.Form.Resources.AppTileButtonPanelStyle
        [Windows.Controls.DockPanel]::SetDock($buttonPanel, [Windows.Controls.Dock]::Right)

        # Define the button properties
        $buttons = @(
            [PSCustomObject]@{ Name = "Install"; Description = "Install or Upgrade the application"; Tooltip = "Install or Upgrade the application"; Icon = [char]0xE118 },
            [PSCustomObject]@{ Name = "Uninstall"; Description = "Uninstall the application"; Tooltip = "Uninstall the application"; Icon = [char]0xE74D },
            [PSCustomObject]@{ Name = "Info"; Description = "Open the application's website in your default browser"; Tooltip = "Open the application's website in your default browser"; Icon = [char]0xE946 }
        )

        # Iterate over each button and create it
        foreach ($button in $buttons) {
            $newButton = New-Object Windows.Controls.Button
            $newButton.Style = $sync.Form.Resources.AppTileButtonStyle
            $newButton.Content = $button.Icon
            $newButton.ToolTip = $button.Tooltip
            $buttonPanel.Children.Add($newButton) | Out-Null

            switch ($button.Name) {
                "Install" {
                    $newButton.Add_Click({
                        $appKey = $this.Parent.Parent.Parent.Tag
                        $appObject = $sync.configs.applicationsHashtable.$appKey
                        Invoke-WPFInstall -PackagesToInstall $appObject
                    })
                }
                "Uninstall" {
                    $newButton.Add_Click({
                        $appKey = $this.Parent.Parent.Parent.Tag
                        $appObject = $sync.configs.applicationsHashtable.$appKey
                        Invoke-WPFUnInstall -PackagesToUninstall $appObject
                    })
                }
                "Info" {
                    $newButton.Add_Click({
                        $appKey = $this.Parent.Parent.Parent.Tag
                        $appObject = $sync.configs.applicationsHashtable.$appKey
                        Start-Process $appObject.link
                    })
                }
            }
        }

        # Add the button panel to the DockPanel
        $dockPanel.Children.Add($buttonPanel) | Out-Null

        # Add the border to the corresponding Category
        $TargetElement.Children.Add($border) | Out-Null
        return $checkbox
    }
