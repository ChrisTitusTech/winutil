Function Get-WinUtilCheckBoxes {

    <#

    .SYNOPSIS
        Finds all checkboxes that are checked on the specific tab and inputs them into a script.

    .PARAMETER unCheck
        Whether to uncheck the checkboxes that are checked. Defaults to true

    .OUTPUTS
        A List containing the name of each checked checkbox

    .EXAMPLE
        Get-WinUtilCheckBoxes "WPFInstall"

    #>

    Param(
        [boolean]$unCheck = $false
    )

    $Output = @{
        Install      = @()
        WPFTweaks     = @()
        WPFFeature    = @()
        WPFInstall    = @()
        WPFToggle     = @()
    }

    $CheckBoxes = $sync.GetEnumerator() | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] }

    # Collect toggle switch states
    foreach ($CheckBox in $CheckBoxes) {
        if ($CheckBox.Key -like "WPFToggle*" -and $CheckBox.Value.IsChecked -eq $true) {
            $Output["WPFToggle"] += $CheckBox.Key
            Write-Debug "Adding toggle: $($CheckBox.Key)"
        }
    }

    # First check and add WPFTweaksRestorePoint if checked
    $RestorePoint = $CheckBoxes | Where-Object { $_.Key -eq 'WPFTweaksRestorePoint' -and $_.Value.IsChecked -eq $true }
    if ($RestorePoint) {
        $Output["WPFTweaks"] = @('WPFTweaksRestorePoint')
        Write-Debug "Adding WPFTweaksRestorePoint as first in WPFTweaks"

        if ($unCheck) {
            $RestorePoint.Value.IsChecked = $false
        }
    }

    foreach ($CheckBox in $CheckBoxes) {
        if ($CheckBox.Key -eq 'WPFTweaksRestorePoint') { continue }  # Skip since it's already handled

        $group = if ($CheckBox.Key.StartsWith("WPFInstall")) { "Install" }
                elseif ($CheckBox.Key.StartsWith("WPFTweaks")) { "WPFTweaks" }
                elseif ($CheckBox.Key.StartsWith("WPFFeature")) { "WPFFeature" }
        if ($group) {
            if ($CheckBox.Value.IsChecked -eq $true) {
                $feature = switch ($group) {
                    "Install" {
                        # Get the winget value
                        [PsCustomObject]@{
                            winget="$($sync.configs.applications.$($CheckBox.Name).winget)";
                            choco="$($sync.configs.applications.$($CheckBox.Name).choco)";
                        }

                    }
                    default {
                        $CheckBox.Name
                    }
                }

                if (-not $Output.ContainsKey($group)) {
                    $Output[$group] = @()
                }
                if ($group -eq "Install") {
                    $Output["WPFInstall"] += $CheckBox.Name
                    Write-Debug "Adding: $($CheckBox.Name) under: WPFInstall"
                }

                Write-Debug "Adding: $($feature) under: $($group)"
                $Output[$group] += $feature

                if ($unCheck) {
                    $CheckBox.Value.IsChecked = $false
                }
            }
        }
    }
    return  $Output
}
