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
        if (-not ($list.Contains($checkboxName))) {
            $list.Add($checkboxName)
        }
    } else {
        $list.Remove($checkboxName)
    }
}
