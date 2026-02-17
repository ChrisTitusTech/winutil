function Invoke-WPFSelectedCheckboxesUpdate{
    <#
        .SYNOPSIS
            This is a helper function that is called by the Checked and Unchecked events of the Checkboxes.
            It also Updates the "Selected Apps" selectedAppLabel on the Install Tab to represent the current collection
        .PARAMETER type
            Either: Add | Remove
        .PARAMETER checkboxName
            should contain the name of the current instance of the checkbox that triggered the Event.
            Most of the time will be the automatic variable $this.Parent.Tag
        .EXAMPLE
            $checkbox.Add_Unchecked({Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName $this.Parent.Tag})
            OR
            Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName $specificCheckbox.Parent.Tag
    #>
    param (
        $type,
        $checkboxName
    )

    if (($type -ne "Add") -and ($type -ne "Remove"))
    {
        Write-Error "Type: $type not implemented"
        return
    }

    # Get the actual Name from the selectedAppLabel inside the Checkbox
    $appKey = $checkboxName
    $group = if ($appKey.StartsWith("WPFInstall")) { "Install" }
                elseif ($appKey.StartsWith("WPFTweaks")) { "Tweaks" }
                elseif ($appKey.StartsWith("WPFToggle")) { "Toggle" }
                elseif ($appKey.StartsWith("WPFFeature")) { "Feature" }
                else { "na" }

    switch ($group) {
        "Install" {
            if ($type -eq "Add") {
               if (!$sync.selectedApps.Contains($appKey)) {
                    $sync.selectedApps.Add($appKey)
                    # The List type needs to be specified again, because otherwise Sort-Object will convert the list to a string if there is only a single entry
                    [System.Collections.Generic.List[pscustomobject]]$sync.selectedApps = $sync.SelectedApps | Sort-Object
                }
            }
            else{
                $sync.selectedApps.Remove($appKey)
            }

            $count = $sync.SelectedApps.Count
            $sync.WPFselectedAppsButton.Content = "Selected Apps: $count"
            # On every change, remove all entries inside the Popup Menu. This is done, so we can keep the alphabetical order even if elements are selected in a random way
            $sync.selectedAppsstackPanel.Children.Clear()
            $sync.selectedApps | Foreach-Object { Add-SelectedAppsMenuItem -name $($sync.configs.applicationsHashtable.$_.Content) -key $_ }
        }
        "Tweaks" {
            if ($type -eq "Add") {
                if (!$sync.selectedTweaks.Contains($appKey)) {
                    $sync.selectedTweaks.Add($appKey)
                }
            }
            else{
                $sync.selectedTweaks.Remove($appKey)
            }
        }
        "Toggle" {
            if ($type -eq "Add") {
                if (!$sync.selectedToggles.Contains($appKey)) {
                    $sync.selectedToggles.Add($appKey)
                }
            }
            else{
                $sync.selectedToggles.Remove($appKey)
            }
        }
        "Feature" {
            if ($type -eq "Add") {
                if (!$sync.selectedFeatures.Contains($appKey)) {
                    $sync.selectedFeatures.Add($appKey)
                }
            }
            else{
                $sync.selectedFeatures.Remove($appKey)
            }
        }
        default {
            Write-Host "Unknown group for checkbox: $($appKey)"
        }
    }

    Write-Debug "-------------------------------------"
    Write-Debug "Selected Apps: $($sync.selectedApps)"
    Write-Debug "Selected Tweaks: $($sync.selectedTweaks)"
    Write-Debug "Selected Toggles: $($sync.selectedToggles)"
    Write-Debug "Selected Features: $($sync.selectedFeatures)"
    Write-Debug "--------------------------------------"
}
