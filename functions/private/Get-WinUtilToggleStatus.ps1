Function Get-WinUtilToggleStatus ([string]$ToggleSwitch) {

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    foreach ($regentry in $ToggleSwitchReg) {

        if (-not (Test-Path $regentry.Path)) {
            New-Item -Path $regentry.Path -Force
        }

        $regstate = (Get-ItemProperty -Path $regentry.Path).$($regentry.Name)

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
