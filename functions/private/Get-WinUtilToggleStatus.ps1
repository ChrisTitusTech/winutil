Function Get-WinUtilToggleStatus {
    param(
        [string]$ToggleSwitch
    )

    $toggleSwitchReg = if ($ToggleSwitch) {
        $sync.configs.tweaks.$ToggleSwitch.registry
    } else {
        $ToggleSwitchReg
    }

    if (-not $toggleSwitchReg) {
        return $false
    }

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
    }

    foreach ($regentry in $toggleSwitchReg) {

        $regstate = $null
        if (Test-Path $regentry.Path) {
            $regstate = (Get-ItemProperty -Path $regentry.Path -ErrorAction SilentlyContinue).$($regentry.Name)
        }

        if ($null -eq $regstate) {
            # Missing values should be treated as "not enabled" to avoid defaulting toggles on.
            $regstate = $regentry.OriginalValue
        }

        if ($regstate -ne $regentry.Value) {
            return $false
        }
    }

    return $true
}
