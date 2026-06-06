Function Get-WinUtilToggleStatus ($ToggleSwitch) {

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    foreach ($regentry in $ToggleSwitchReg) {

        $regPath = Get-WinUtilHKCURedirectPath -Path $regentry.Path

        $regstate = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).$($regentry.Name)

        if ($null -eq $regstate) {
            switch ($regentry.DefaultState) {
                "true"  { $regstate = $regentry.Value }
                "false" { $regstate = $regentry.OriginalValue }
            }
        }

        if ($regstate -ne $regentry.Value) {
            return $false
        }
    }

    return $true
}
