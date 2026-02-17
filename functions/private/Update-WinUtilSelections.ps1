function Update-WinUtilSelections {
    <#

    .SYNOPSIS
        Updates the $sync.selected variables with a given preset.

    .PARAMETER flatJson
        The flattened json list of $sync values to select.
    #>

    param (
        $flatJson
    )

    Write-Debug "JSON to import: $($flatJson)"

    foreach ($cbkey in $flatJson) {
        $group = if ($cbkey.StartsWith("WPFInstall")) { "Install" }
                    elseif ($cbkey.StartsWith("WPFTweaks")) { "Tweaks" }
                    elseif ($cbkey.StartsWith("WPFToggle")) { "Toggle" }
                    elseif ($cbkey.StartsWith("WPFFeature")) { "Feature" }
                    else { "na" }

        switch ($group) {
            "Install" {
                if (!$sync.selectedApps.Contains($cbkey)) {
                    $sync.selectedApps.Add($cbkey)
                    # The List type needs to be specified again, because otherwise Sort-Object will convert the list to a string if there is only a single entry
                    [System.Collections.Generic.List[pscustomobject]]$sync.selectedApps = $sync.SelectedApps | Sort-Object
                }
            }
            "Tweaks" {
                if (!$sync.selectedTweaks.Contains($cbkey)) {
                    $sync.selectedTweaks.Add($cbkey)
                }
            }
            "Toggle" {
                if (!$sync.selectedToggles.Contains($cbkey)) {
                    $sync.selectedToggles.Add($cbkey)
                }
            }
            "Feature" {
                if (!$sync.selectedFeatures.Contains($cbkey)) {
                    $sync.selectedFeatures.Add($cbkey)
                }
            }
            default {
                Write-Host "Unknown group for checkbox: $($cbkey)"
            }
        }
    }

    Write-Debug "-------------------------------------"
    Write-Debug "Selected Apps: $($sync.selectedApps)"
    Write-Debug "Selected Tweaks: $($sync.selectedTweaks)"
    Write-Debug "Selected Toggles: $($sync.selectedToggles)"
    Write-Debug "Selected Features: $($sync.selectedFeatures)"
    Write-Debug "--------------------------------------"
}
