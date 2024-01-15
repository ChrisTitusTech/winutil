Function Get-WinUtilCheckBoxes {

    <#

    .SYNOPSIS
        Finds all checkboxes that are checked on the specific tab and inputs them into a script.

    .PARAMETER Group
        The group of checkboxes to check

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
    }

    $CheckBoxes = $sync.GetEnumerator() | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] }

    foreach ($CheckBox in $CheckBoxes) {
        $group = if ($CheckBox.Key.StartsWith("WPFInstall")) { "Install" }
                elseif ($CheckBox.Key.StartsWith("WPFTweaks")) { "WPFTweaks" }
                elseif ($CheckBox.Key.StartsWith("WPFFeature")) { "WPFFeature" }

        if ($group) {
            if ($CheckBox.Value.IsChecked -eq $true) {
                $feature = switch ($group) {
                    "Install" {
                        # Get the winget value
                        $wingetValue = $sync.configs.applications.$($CheckBox.Name).winget

                        if (-not [string]::IsNullOrWhiteSpace($wingetValue) -and $wingetValue -ne "na") {
                            $wingetValue -split ";"
                        } else {
                            $sync.configs.applications.$($CheckBox.Name).choco
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

                if ($uncheck -eq $true) {
                    $CheckBox.Value.IsChecked = $false
                }
            }
        }
    }

    return  $Output
}
