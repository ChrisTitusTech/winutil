function Update-WinUtilSelections ($flatJson) {
    foreach ($cbkey in $flatJson) {
        $listName = switch -Regex ($cbkey) {
            '^WPFInstall' { 'selectedApps' }
            '^WPFTweaks'  { 'selectedTweaks' }
            '^WPFToggle'  { 'selectedToggles' }
            '^WPFFeature' { 'selectedFeatures' }
            '^WPFAppx'    { 'selectedAppx' }
        }

        if (-not $sync.$listName.Contains($cbkey)) {
            $sync.$listName.Add($cbkey)
        }
    }
}
