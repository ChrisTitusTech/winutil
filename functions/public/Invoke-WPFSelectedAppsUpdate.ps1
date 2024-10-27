function Invoke-WPFSelectedAppsUpdate {
    <#
        .SYNOPSIS
            This is a helper function that is called by the Checked and Unchecked events of the Checkboxes on the install tab.
            It Updates the "Selected Apps" selectedAppLabel on the Install Tab to represent the current collection
        .PARAMETER type
            Eigther: Add | Remove
        .PARAMETER checkbox
            should contain the current instance of the checkbox that triggered the Event.
            Most of the time will be the automatic variable $this
        .EXAMPLE
            $checkbox.Add_Unchecked({Invoke-WPFSelectedAppsUpdate -type "Remove" -checkbox $this})
            OR
            Invoke-WPFSelectedAppsUpdate -type "Add" -checkbox $specificCheckbox
    #>
    param (
        $type,
        $checkbox
    )
    function Add-SelectedAppsMenuItem {
        <#
        .SYNOPSIS 
            This is a helper function that generates and adds the Menu Items to the Selected Apps Popup.
        
        .Parameter name
            The actual Name of an App like "Chrome" or "Brave"
            This name is contained in the "Content" property inside the applications.json
        .PARAMETER key
            The key which identifies an app object in applications.json 
            For Chrome this would be "WPFInstallchrome" because "WPFInstall" is prepended automatically for each key in applications.json 
        #>

        param ([string]$name, [string]$key)
        
        $selectedAppGrid = New-Object Windows.Controls.Grid

        $selectedAppGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = "*"}))
        $selectedAppGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = "30"}))
    
        # Sets the name to the Content as well as the Tooltip, because the parent Popup Border has a fixed width and text could "overflow".
        # With the tooltip, you can still read the whole entry on hover
        $selectedAppLabel = New-Object Windows.Controls.Label
        $selectedAppLabel.Content = $name
        $selectedAppLabel.ToolTip = $name
        $selectedAppLabel.HorizontalAlignment = "Left"
        $selectedAppLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        [System.Windows.Controls.Grid]::SetColumn($selectedAppLabel, 0)
        $selectedAppGrid.Children.Add($selectedAppLabel)

        $selectedAppRemoveButton = New-Object Windows.Controls.Button
        $selectedAppRemoveButton.FontFamily = "Segoe MDL2 Assets"
        $selectedAppRemoveButton.Content = [string]([char]0xE711) 
        $selectedAppRemoveButton.HorizontalAlignment = "Center"
        $selectedAppRemoveButton.Tag = $key
        $selectedAppRemoveButton.ToolTip = "Remove the App from Selection"
        $selectedAppRemoveButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $selectedAppRemoveButton.SetResourceReference([Windows.Controls.Control]::StyleProperty, "HoverButtonStyle")
        
        # Highlight the Remove icon on Hover
        $selectedAppRemoveButton.Add_MouseEnter({ $this.Foreground = "Red" })
        $selectedAppRemoveButton.Add_MouseLeave({ $this.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor") })
        $selectedAppRemoveButton.Add_Click({
            $sync.($this.Tag).isChecked = $false # On click of the remove button, we only have to uncheck the corresponding checkbox. This will kick of all neccessary changes to update the UI
        })
        [System.Windows.Controls.Grid]::SetColumn($selectedAppRemoveButton, 1)
        $selectedAppGrid.Children.Add($selectedAppRemoveButton)
        # Add new Element to Popup
        $sync.selectedAppsstackPanel.Children.Add($selectedAppGrid)   
    }
    $selectedAppsButton = $sync.WPFselectedAppsButton
    # Get the actual Name from the selectedAppLabel inside the Checkbox
    $appKey = $checkbox.Parent.Parent.Tag
    if ($type -eq "Add") {
        $sync.selectedApps.Add($appKey)
        # The List type needs to be specified again, because otherwise Sort-Object will convert the list to a string if there is only a single entry
        [System.Collections.Generic.List[pscustomobject]]$sync.selectedApps = $sync.SelectedApps | Sort-Object
        
    }
    elseif ($type -eq "Remove") {
        $sync.SelectedApps.Remove($appKey)
    }
    else{
        Write-Error "Type: $type not implemented"
    }
    
    $count = $sync.SelectedApps.Count
    $selectedAppsButton.Content = "Selected Apps: $count"
    # On every change, remove all entries inside the Popup Menu. This is done, so we can keep the alphabetical order even if elements are selected in a random way
    $sync.selectedAppsstackPanel.Children.Clear()    
    $sync.SelectedApps | Foreach-Object { Add-SelectedAppsMenuItem -name $($sync.configs.applicationsHashtable.$_.Content) -key $_ }
    
}
