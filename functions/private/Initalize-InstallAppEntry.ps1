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
            $childCheckbox = ($this.Child | Where-Object {$_.Template.TargetType -eq [System.Windows.Controls.Checkbox]})[0]
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

        # Create the CheckBox, vertically centered
        $checkBox = New-Object Windows.Controls.CheckBox
        $checkBox.Name = $appKey
        $checkbox.Style = $sync.Form.Resources.AppTileCheckboxStyle
        $checkbox.Add_Checked({
            Invoke-WPFSelectedAppsUpdate -type "Add" -checkbox $this
            $borderElement = $this.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallSelectedColor")
        })

        $checkbox.Add_Unchecked({
            Invoke-WPFSelectedAppsUpdate -type "Remove" -checkbox $this
            $borderElement = $this.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
        })

        # Create the TextBlock for the application name
        $appName = New-Object Windows.Controls.TextBlock
        $appName.Style = $sync.Form.Resources.AppTileNameStyle
        $appName.Text = $Apps.$appKey.content

        # Add the name to the Checkbox
        $checkBox.Content = $appName

        $border.Child = $checkBox
        # Add the border to the corresponding Category
        $TargetElement.Children.Add($border) | Out-Null
        return $checkbox
    }
