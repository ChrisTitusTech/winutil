function Reset-WPFCheckBoxes {
    <#

    .SYNOPSIS
        Set WinUtil checkboxes to match $sync.selected values.
        Should only need to be run if $sync.selected updated outside of UI (i.e. presets or import)

    .PARAMETER doToggles
        Whether or not to set UI toggles. WARNING: they will trigger if altered

    .PARAMETER checkboxfilterpattern
        The Pattern to use when filtering through CheckBoxes, defaults to "**"
        Used to make reset blazingly fast.
    #>

    param (
        [Parameter(position=0)]
        [bool]$doToggles = $false,

        [Parameter(position=1)]
        [string]$checkboxfilterpattern = "**"
    )
    $selectedSet = [System.Collections.Generic.HashSet[string]]::new([string[]]@($sync.selectedApps + $sync.selectedTweaks + $sync.selectedFeatures + $sync.selectedAppx), [StringComparer]::OrdinalIgnoreCase)

    # A synchronized Hashtable protects individual operations, not enumeration. Materialize the
    # snapshot under its lock, then release it before handlers run and mutate $sync.
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $syncEntries = @($sync.GetEnumerator())
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }
    foreach ($syncEntry in $syncEntries) {
        $checkBox = $syncEntry.Value
        if ($checkBox -is [System.Windows.Controls.CheckBox] -and -not $syncEntry.Key.StartsWith("WPFToggle") -and ($checkboxfilterpattern -eq "**" -or $syncEntry.Key -like $checkboxfilterpattern)) {
            # Assigning the state a box already has is not free for the hundreds of boxes the
            # Install tab adds, so only the ones that differ are touched
            $selected = $selectedSet.Contains($syncEntry.Key)
            if ($checkBox.IsChecked -ne $selected) {
                $checkBox.IsChecked = $selected
            }
        }
    }

    # Update Installs tab UI values. These are built with the Install tab, and this runs for
    # whichever tab is built first: offline starts on Tweaks, so they are not there yet.
    if ($sync.selectedAppsstackPanel) {
        $count = $sync.SelectedApps.Count
        $sync.WPFselectedAppsButton.Content = "Selected Apps: $count"
        # On every change, remove all entries inside the Popup Menu. This is done, so we can keep the alphabetical order even if elements are selected in a random way
        $sync.selectedAppsstackPanel.Children.Clear()
        $sync.selectedApps | Foreach-Object { Add-SelectedAppsMenuItem -name $($sync.configs.applicationsHashtable.$_.Content) -key $_ }
    }

    if($doToggles) {
        # Restore toggle switch states from imported config.
        # Only act on toggles that are explicitly listed in the import - toggles absent
        # from the export file were not part of the saved config and should keep whatever
        # state the live system already has (set during UI initialisation via Get-WinUtilToggleStatus).
        $importedToggles = [System.Collections.Generic.HashSet[string]]::new([string[]]@($sync.selectedToggles), [StringComparer]::OrdinalIgnoreCase)
        [System.Threading.Monitor]::Enter($sync.SyncRoot)
        try {
            $toggleEntries = @($sync.GetEnumerator())
        } finally {
            [System.Threading.Monitor]::Exit($sync.SyncRoot)
        }
        foreach ($toggle in $toggleEntries) {
            if ($toggle.Key -like "WPFToggle*" -and $toggle.Value -is [System.Windows.Controls.CheckBox] -and $importedToggles.Contains($toggle.Key)) {
                $sync[$toggle.Key].IsChecked = $true
            }
            # Toggles not present in the import are intentionally left untouched;
            # their current UI state already reflects the real system state.
        }
    }
}
