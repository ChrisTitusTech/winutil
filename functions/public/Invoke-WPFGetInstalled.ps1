function Invoke-WPFGetInstalled {
    <#
    .SYNOPSIS
        Detects what is already installed or applied and ticks the matching boxes

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)

    if (($sync.ChocoRadioButton.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }

    Start-WinUtilJob -Name "Detect installed" -Description "Checking what is already installed" -Parameters @{
        Checkbox = $checkbox
        ManagerPreference = $sync.preferences.packagemanager
    } -ScriptBlock {
        param($Checkbox, $ManagerPreference)

        Write-WinUtilJobProgress -Status "Checking what is already installed" -State "Indeterminate"

        $found = @()
        if ($Checkbox -eq "winget") {
            $source = if ($ManagerPreference -eq "Choco") { "choco" } else { $Checkbox }
            $found = @(Invoke-WinUtilCurrentSystem -CheckBox $source)
        } elseif ($Checkbox -eq "tweaks") {
            $found = @(Invoke-WinUtilCurrentSystem -CheckBox $Checkbox)
        }

        Write-WinUtilLog -Component "Install" -Message "Detected $($found.Count) existing item(s) for $Checkbox."

        # Ticking boxes touches the controls, so it happens on the UI thread
        Invoke-WPFUIThread -ScriptBlock {
            if ($Checkbox -eq "winget") {
                foreach ($name in $found) {
                    if (-not $sync.selectedApps.Contains($name)) {
                        $sync.selectedApps.Add($name)
                    }
                }
                Reset-WPFCheckBoxes -checkboxfilterpattern "WPFInstall*"
            } else {
                foreach ($name in $found) {
                    $sync.$name.ischecked = $true
                }
            }
        }
    }
}
