function Update-WinUtilSelections {
    param(
        [Parameter(Mandatory)]
        [string[]]$flatJson,

        [switch]$Replace,

        [switch]$SkipUnknown
    )

    $nextSelections = @{
        selectedApps     = [System.Collections.Generic.List[string]]::new()
        selectedTweaks   = [System.Collections.Generic.List[string]]::new()
        selectedToggles  = [System.Collections.Generic.List[string]]::new()
        selectedFeatures = [System.Collections.Generic.List[string]]::new()
        selectedAppx     = [System.Collections.Generic.List[string]]::new()
    }

    foreach ($cbkey in $flatJson) {

        $listName = switch -Regex ($cbkey) {
            '^WPFInstall' { 'selectedApps' }
            '^WPFTweaks'  { 'selectedTweaks' }
            '^WPFToggle'  { 'selectedToggles' }
            '^WPFFeature' { 'selectedFeatures' }
            '^WPFAppx'    { 'selectedAppx' }
        }

        if (-not $listName) {
            if ($SkipUnknown) {
                $cbkey
                continue
            }
            throw "Unsupported selection key '$cbkey'."
        }

        $isKnownSelection = switch ($listName) {
            'selectedApps' {
                $sync.configs.applicationsHashtable.ContainsKey($cbkey)
            }
            'selectedTweaks' {
                $null -ne $sync.configs.tweaks.PSObject.Properties[$cbkey]
            }
            'selectedToggles' {
                $null -ne $sync.configs.tweaks.PSObject.Properties[$cbkey]
            }
            'selectedFeatures' {
                $null -ne $sync.configs.feature.PSObject.Properties[$cbkey]
            }
            'selectedAppx' {
                $sync.configs.appxHashtable.ContainsKey($cbkey)
            }
        }

        if (-not $isKnownSelection) {
            if ($SkipUnknown) {
                $cbkey
                continue
            }
            throw "Unknown selection key '$cbkey'."
        }

        $nextSelections[$listName].Add($cbkey)
    }

    $validSelectionCount = ($nextSelections.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    if ($SkipUnknown -and $validSelectionCount -eq 0) {
        return
    }

    if ($Replace) {
        foreach ($listName in $nextSelections.Keys) {
            $sync[$listName] = $nextSelections[$listName]
        }
        return
    }

    foreach ($listName in $nextSelections.Keys) {
        foreach ($cbkey in $nextSelections[$listName]) {
            $sync.$listName.Add($cbkey)
        }
    }
}
