function Invoke-WPFPresets {
    <#

    .SYNOPSIS
        Sets the options in the tweaks panel to the given preset

    .PARAMETER preset
        The preset to set the options to

    .PARAMETER imported
        If the preset is imported from a file, defaults to false

    .PARAMETER checkbox
        The checkbox to set the options to, defaults to 'WPFTweaks'

    #>

    param(
        $preset,
        [bool]$imported = $false
    )

    if($imported -eq $true){
        $CheckBoxesToCheck = $preset
    }
    Else{
        $CheckBoxesToCheck = $sync.configs.preset.$preset
    }

    $CheckBoxes = $sync.GetEnumerator() | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] -and $_.Name -notlike "WPFToggle*" }
    Write-Debug "Getting checkboxes to set $($CheckBoxes.Count)"

    $CheckBoxesToCheck | ForEach-Object {
        if ($_ -ne $null) {
            Write-Debug $_
        }
    }

    foreach ($CheckBox in $CheckBoxes) {
        $checkboxName = $CheckBox.Key

        if (-not $CheckBoxesToCheck)
        {
            $sync.$checkboxName.IsChecked = $false
            continue
        }

        # Check if the checkbox name exists in the flattened JSON hashtable
        if ($CheckBoxesToCheck.Contains($checkboxName)) {
            # If it exists, set IsChecked to true
            $sync.$checkboxName.IsChecked = $true
            Write-Debug "$checkboxName is checked"
        } else {
            # If it doesn't exist, set IsChecked to false
            $sync.$checkboxName.IsChecked = $false
            Write-Debug "$checkboxName is not checked"
        }
    }
}
