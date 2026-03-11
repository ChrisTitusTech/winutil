function Reset-WPFCheckBoxes {
    param (
        [Parameter(position=0)]
        [bool]$doToggles = $false,

        [Parameter(position=1)]
        [string]$checkboxfilterpattern = "**"
    )

    $CheckBoxesToCheck = $sync.selectedApps + $sync.selectedTweaks + $sync.selectedFeatures
    $CheckBoxes = ($sync.GetEnumerator()).Where{ $_.Value -is [System.Windows.Controls.CheckBox] -and $_.Name -notlike "WPFToggle*" -and $_.Name -like "$checkboxfilterpattern" }
    Write-Debug "Getting checkboxes to set, number of checkboxes: $($CheckBoxes.Count)"

    if ($CheckBoxesToCheck -ne "") {
        $debugMsg = "CheckBoxes to Check are: "
        $CheckBoxesToCheck | ForEach-Object { $debugMsg += "$_, " }
        $debugMsg = $debugMsg -replace (',\s*$', '')
        Write-Debug "$debugMsg"
    }

    foreach ($CheckBox in $CheckBoxes) {
        $checkboxName = $CheckBox.Key
        if (-not $CheckBoxesToCheck) {
            if ($sync.$checkboxName) { $sync.$checkboxName.IsChecked = $false }
            continue
        }

        if ($CheckBoxesToCheck -contains $checkboxName) {
            if ($sync.$checkboxName) { $sync.$checkboxName.IsChecked = $true }
            Write-Debug "$checkboxName is checked"
        } else {
            if ($sync.$checkboxName) { $sync.$checkboxName.IsChecked = $false }
            Write-Debug "$checkboxName is not checked"
        }
    }

    # Update Installs tab UI values
    $count = $sync.SelectedApps.Count
    $sync.WPFselectedAppsButton.Content = "Selected Apps: $count"
    $sync.selectedAppsstackPanel.Children.Clear()
    $sync.selectedApps | ForEach-Object { Add-SelectedAppsMenuItem -name $($sync.configs.applicationsHashtable.$_.Content) -key $_ }

    if ($doToggles) {
        $importedToggles = $sync.selectedToggles
        $allToggles = $sync.GetEnumerator() | Where-Object { $_.Key -like "WPFToggle*" -and $_.Value -is [System.Windows.Controls.CheckBox] }
        foreach ($toggle in $allToggles) {
            if ($sync[$toggle.Key]) {
                $sync[$toggle.Key].IsChecked = $importedToggles -contains $toggle.Key
                Write-Debug "Restoring toggle: $($toggle.Key) = $($sync[$toggle.Key].IsChecked)"
            }
        }
    }
}
