function Invoke-WPFSelectedCheckboxesUpdate ($type, $checkboxName) {
    $listName = switch -Regex ($checkboxName) {
        '^WPFInstall' { 'selectedApps' }
        '^WPFTweaks'  { 'selectedTweaks' }
        '^WPFToggle'  { 'selectedToggles' }
        '^WPFFeature' { 'selectedFeatures' }
        '^WPFAppx'    { 'selectedAppx' }
    }

    $selectionChanged = $false
    if ($type -eq "Add") {
        if ($sync.$listName -notcontains $checkboxName) {
            $sync.$listName.Add($checkboxName)
            $selectionChanged = $true
        }
    } else {
        # Imported keys are validated case-insensitively, so checkbox events must
        # use the same comparison even when the imported spelling differs.
        for ($index = $sync.$listName.Count - 1; $index -ge 0; $index--) {
            if ($sync.$listName[$index] -eq $checkboxName) {
                $sync.$listName.RemoveAt($index)
                $selectionChanged = $true
            }
        }
    }

    if ($listName -eq "selectedApps" -and $selectionChanged) {
        $sync.WPFselectedAppsButton.Content = "Selected Apps: $($sync.selectedApps.Count)"
        $sync.selectedAppsstackPanel.Children.Clear()
        $sync.selectedApps | Sort-Object | ForEach-Object {
            Add-SelectedAppsMenuItem -name $sync.configs.applicationsHashtable.$_.Content -key $_
        }
    }
}
