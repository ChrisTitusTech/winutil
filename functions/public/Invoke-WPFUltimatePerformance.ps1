function Invoke-WPFUltimatePerformance ([switch]$Enable) {
    <#

    .SYNOPSIS
        Adds or removes the Ultimate Performance power plan

    #>

    if ($Enable) {
        Step-WinUtilJob -Status "Adding the Ultimate Performance power plan" -State "Indeterminate"
        Write-WinUtilLog -Component "Power" -Message "Duplicating and activating the Ultimate Performance power plan."

        $duplicated = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        if ($LASTEXITCODE -ne 0) {
            throw "powercfg could not duplicate the Ultimate Performance scheme (exit code $LASTEXITCODE)."
        }

        $guid = ($duplicated | Select-String -Pattern '[A-Fa-f0-9-]{36}').Matches.Value
        if (-not $guid) {
            throw "powercfg did not report a scheme GUID to activate."
        }

        powercfg /setactive $guid
        if ($LASTEXITCODE -ne 0) {
            throw "powercfg could not activate the Ultimate Performance scheme (exit code $LASTEXITCODE)."
        }

        Write-WinUtilLog -Component "Power" -Message "Ultimate Performance power plan installed and activated."
    } else {
        Step-WinUtilJob -Status "Restoring the default power plans" -State "Indeterminate"
        Write-WinUtilLog -Component "Power" -Message "Restoring the default power schemes."

        powercfg /restoredefaultschemes
        if ($LASTEXITCODE -ne 0) {
            throw "powercfg could not restore the default power schemes (exit code $LASTEXITCODE)."
        }

        Write-WinUtilLog -Component "Power" -Message "Power plans were reset to defaults."
    }
}
