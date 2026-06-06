Function Get-WinUtilToggleStatus ($ToggleSwitch) {

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if (-not $ToggleSwitchReg) {
        return $false
    }

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    foreach ($regentry in $ToggleSwitchReg) {

        $regstate = $null
        if (Test-Path $regentry.Path) {
            $regstate = (Get-ItemProperty -Path $regentry.Path -ErrorAction SilentlyContinue).$($regentry.Name)
        }

        $regstate = Resolve-WinUtilRegistryEffectiveValue `
            -CurrentValue $regstate `
            -DefaultState $regentry.DefaultState `
            -Value $regentry.Value `
            -OriginalValue $regentry.OriginalValue

        if ($null -eq $regstate) {
            return $false
        }

        if (-not (Test-WinUtilRegistryValueMatch -CurrentValue $regstate -ExpectedValue $regentry.Value -Type $regentry.Type)) {
            return $false
        }
    }

    return $true
}
