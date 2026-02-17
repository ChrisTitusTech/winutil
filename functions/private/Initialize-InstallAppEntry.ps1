function Initialize-InstallAppEntry {
    <#
        .SYNOPSIS
            Creates the app entry to be placed on the install tab for a given app
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
    $border.Style = $sync.Form.Resources.AppEntryBorderStyle
    $border.Tag = $appKey
    $border.ToolTip = $Apps.$appKey.description
    $border.Add_MouseLeftButtonUp({
            $childCheckbox = ($this.Child | Where-Object { $_.Template.TargetType -eq [System.Windows.Controls.Checkbox] })[0]
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
    $border.Add_MouseRightButtonUp({
            # Store the selected app in a global variable so it can be used in the popup
            $sync.appPopupSelectedApp = $this.Tag
            # Set the popup position to the current mouse position
            $sync.appPopup.PlacementTarget = $this
            $sync.appPopup.IsOpen = $true
        })

    $checkBox = New-Object Windows.Controls.CheckBox
    $checkBox.Name = $appKey
    $checkbox.Style = $sync.Form.Resources.AppEntryCheckboxStyle
    $checkbox.Add_Checked({
            Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName $this.Parent.Tag
            $borderElement = $this.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallSelectedColor")
        })

    $checkbox.Add_Unchecked({
            Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName $this.Parent.Tag
            $borderElement = $this.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
        })

    # Create the TextBlock for the application name
    $appName = New-Object Windows.Controls.TextBlock
    $appName.Style = $sync.Form.Resources.AppEntryNameStyle
    $appName.Text = $Apps.$appKey.content
    $appName.VerticalAlignment = "Center"

    # Create a StackPanel to hold the text and the flag
    $contentPanel = New-Object Windows.Controls.StackPanel
    $contentPanel.Orientation = "Horizontal"
    $contentPanel.Children.Add($appName) | Out-Null

    # Add origin country flag if available
    if ($Apps.$appKey.origin) {
        $originFlag = Get-WinUtilCountryFlag -CountryCode $Apps.$appKey.origin
        if ($originFlag) {
            $originFlag.Margin = "5,0,0,0" # Add some spacing
            $originFlag.VerticalAlignment = "Center"
            $originFlag.ToolTip = "Origin: $($Apps.$appKey.origin)"
            $contentPanel.Children.Add($originFlag) | Out-Null

            # Also add the origin to the checkbox tooltip if not present
            if ($checkBox.ToolTip -notlike "*Origin:*") {
                $checkBox.ToolTip = "$($checkBox.ToolTip)`nOrigin: $($Apps.$appKey.origin)"
            }
        }
    }

    # Add the StackPanel to the Checkbox
    $checkBox.Content = $contentPanel

    # Add accessibility properties to make the elements screen reader friendly
    $checkBox.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $Apps.$appKey.content)
    $border.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $Apps.$appKey.content)

    $border.Child = $checkBox
    # Add the border to the corresponding Category
    $TargetElement.Children.Add($border) | Out-Null
    return $checkbox
}
