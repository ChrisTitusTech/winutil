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
    # Get the actual Name from the checkbox - enhanced layout compatibility
    $appKey = $checkbox.Name

    # If appKey is null, try to find it from parent structure (fallback for different layouts)
    if (-not $appKey) {
        $parent = $checkbox.Parent
        while ($parent -and -not $appKey) {
            if ($parent.Tag) {
                $appKey = $parent.Tag
                break
            }
            $parent = $parent.Parent
        }
    }
    # Ensure the selectedApps list is initialized
    if (-not $sync.selectedApps) {
        $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
    }

    if ($type -eq "Add") {
        if (-not $sync.selectedApps.Contains($appKey)) {
            $sync.selectedApps.Add($appKey)
        }
    }
    elseif ($type -eq "Remove") {
        $sync.selectedApps.Remove($appKey)
    }
    else{
        Write-Error "Type: $type not implemented"
    }

    $count = $sync.selectedApps.Count
    $selectedAppsButton.Content = "Selected Apps: $count"

    # On every change, remove all entries inside the Popup Menu and rebuild
    if ($sync.selectedAppsstackPanel) {
        $sync.selectedAppsstackPanel.Children.Clear()
        # Sort apps alphabetically and add to popup
        $sortedApps = $sync.selectedApps | Sort-Object { $sync.configs.applicationsHashtable.$_.Content }
        $sortedApps | ForEach-Object {
            $appInfo = $sync.configs.applicationsHashtable.$_
            if ($appInfo) {
                Add-SelectedAppsMenuItem -name $appInfo.Content -key $_
            }
        }
    }

}
