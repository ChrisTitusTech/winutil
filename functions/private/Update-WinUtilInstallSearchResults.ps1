function Update-WinUtilInstallSearchResults {
    if ($sync.currentTab -eq "Install") {
        $manager = $sync.preferences.packagemanager
        $incompatibleApps = @()
        if ($null -ne $sync.selectedApps) {
            foreach ($appKey in $sync.selectedApps) {
                $appEntry = if ($sync.configs.applicationsHashtable.ContainsKey($appKey)) { $sync.configs.applicationsHashtable[$appKey] } else { $null }
                if ($null -ne $appEntry) {
                    $val = if ($manager -eq "Winget") { $appEntry.winget } else { $appEntry.choco }
                    if ([string]::IsNullOrWhiteSpace($val) -or $val -match '(?i)^na$') {
                        $incompatibleApps += $appKey
                    }
                }
            }
        }
        foreach ($appKey in $incompatibleApps) {
            if ($null -ne $sync.$appKey) {
                $sync.$appKey.IsChecked = $false
            } else {
                if (Get-Command Invoke-WPFSelectedCheckboxesUpdate -ErrorAction SilentlyContinue) {
                    Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName $appKey
                }
            }
        }

        Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Categories $sync.SelectedAppCategories.ToArray()
    }
}
