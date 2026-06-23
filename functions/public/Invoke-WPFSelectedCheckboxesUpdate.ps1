function Invoke-WPFSelectedCheckboxesUpdate ($type, $checkboxName) {
    $listName = switch -Regex ($checkboxName) {
        '^WPFInstall' { 'selectedApps' }
        '^WPFTweaks'  { 'selectedTweaks' }
        '^WPFToggle'  { 'selectedToggles' }
        '^WPFFeature' { 'selectedFeatures' }
        '^WPFAppx'    { 'selectedAppx' }
    }

    $list = $sync.$listName

    if ($type -eq "Add") {
        if (!$list.Contains($checkboxName)) {
            $list.Add($checkboxName)
        }
    } else {
        $list.Remove($checkboxName)
    }

    if ($listName -eq "selectedApps") {
        $sync.selectedApps = [System.Collections.Generic.List[string]]($sync.selectedApps | Sort-Object)
        $sync.WPFselectedAppsButton.Content = "Selected Apps: $($sync.selectedApps.Count)"
        $sync.selectedAppsstackPanel.Children.Clear()

        foreach ($app in $sync.selectedApps) {
            Add-SelectedAppsMenuItem -name $sync.configs.applicationsHashtable.$app.Content -key $app
        }
    }
}
