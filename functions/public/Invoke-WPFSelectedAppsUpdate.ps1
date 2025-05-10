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

    $selectedAppsButton = $sync.WPFselectedAppsButton
    # Get the actual Name from the selectedAppLabel inside the Checkbox
    $appKey = $checkbox.Parent.Tag
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
