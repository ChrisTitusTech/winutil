function Invoke-WPFPresets {
    <#

    .SYNOPSIS
        Sets the checkboxes in winutil to the given preset

    .PARAMETER preset
        The preset to set the checkboxes to

    .PARAMETER imported
        If the preset is imported from a file, defaults to false

    .PARAMETER checkboxfilterpattern
        The Pattern to use when filtering through CheckBoxes, defaults to "**"

    #>

    param (
        [Parameter(position=0)]
        [Array]$preset = $null,

        [Parameter(position=1)]
        [bool]$imported = $false,

        [Parameter(position=2)]
        [string]$checkboxfilterpattern = "**"
    )

    if ($imported -eq $true) {
        $CheckBoxesToCheck = $preset
    } else {
        $CheckBoxesToCheck = $sync.configs.preset.$preset
    }

    # clear out the filtered pattern
    if (!$preset) {
        switch ($checkboxfilterpattern) {
            "WPFTweak*" { $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new() }
            "WPFInstall*" { $sync.selectedApps = [System.Collections.Generic.List[string]]::new() }
            "WPFeatures" { $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new() }
            "WPFToggle" { $sync.selectedToggles = [System.Collections.Generic.List[string]]::new() }
            default {}
        }
    }
    else {
        Update-WinUtilSelections -flatJson $CheckBoxesToCheck
    }

    Reset-WPFCheckBoxes -doToggles $false -checkboxfilterpattern $checkboxfilterpattern
}
