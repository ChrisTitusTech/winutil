Function Get-WinUtilToggleStatus {
    param(
        $ToggleSwitch,
        [switch]$BypassCache,
        [switch]$StopOnReadError
    )

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if (-not $BypassCache) {
        if ($null -eq $sync.ToggleStatusCache) {
            $sync.ToggleStatusCache = @{}
        }

        if ($sync.ToggleStatusCache.ContainsKey($ToggleSwitch)) {
            return [bool]$sync.ToggleStatusCache[$ToggleSwitch]
        }
    }

    $readErrorAction = if ($StopOnReadError) { "Stop" } else { "Continue" }

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction $readErrorAction | Out-Null
    }

    foreach ($regentry in $ToggleSwitchReg) {

        if (Test-Path $regentry.Path -ErrorAction $readErrorAction) {
            $regstate = (Get-ItemProperty -Path $regentry.Path -ErrorAction $readErrorAction).$($regentry.Name)
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
            if (-not $BypassCache) {
                $sync.ToggleStatusCache[$ToggleSwitch] = $false
            }
            return $false
        }
    }

    if (-not $BypassCache) {
        $sync.ToggleStatusCache[$ToggleSwitch] = $true
    }
    return $true
}
