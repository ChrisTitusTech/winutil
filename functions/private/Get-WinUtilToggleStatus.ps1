Function Get-WinUtilToggleStatus {
    if (-not $ToggleSwitchReg) {
        return $false
    }

    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS

    foreach ($regentry in $ToggleSwitchReg) {

        if (-not (Test-Path $regentry.Path)) {
            New-Item -Path $regentry.Path -Force | Out-Null
        }

        $regstate = (Get-ItemProperty -Path $regentry.Path).$($regentry.Name)

        if ($null -eq $regstate) {
            switch ($regentry.DefaultState) {
                "true" {
                    $regstate = $regentry.Value
                }
                "false" {
                    $regstate = $regentry.OriginalValue
                }
                default {
                    Write-Error "Entry $($regentry.Name): missing value and no DefaultState"
                    $regstate = $regentry.OriginalValue
                }
            }
        }

        if ($regstate -ne $regentry.Value) {
            return $false
        }
    }

    return $true
}
