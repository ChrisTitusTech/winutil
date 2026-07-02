Function Get-WinUtilToggleStatus ($ToggleSwitch) {

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if ($null -eq $sync.ToggleStatusCache) {
        $sync.ToggleStatusCache = @{}
    }

    if ($sync.ToggleStatusCache.ContainsKey($ToggleSwitch)) {
        return [bool]$sync.ToggleStatusCache[$ToggleSwitch]
    }

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    foreach ($regentry in $ToggleSwitchReg) {

        if (Test-Path $regentry.Path) {
            $regstate = (Get-ItemProperty -Path $regentry.Path).$($regentry.Name)
        } else {
            $regstate = $null
        }

        if ($null -eq $regstate) {
            switch ([string]$regentry.DefaultState) {
                "true"  { $regstate = $regentry.Value }
                "false" { $regstate = $regentry.OriginalValue }
            }
        }

        if ($regstate -ne $regentry.Value) {
            $sync.ToggleStatusCache[$ToggleSwitch] = $false
            return $false
        }
    }

    $sync.ToggleStatusCache[$ToggleSwitch] = $true
    return $true
}
