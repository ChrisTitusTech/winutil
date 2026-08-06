function Invoke-WPFUltimatePerformance ([switch]$Enable) {
    <#

    .SYNOPSIS
        Adds or removes the Ultimate Performance power plan

    #>

    if ($Enable) {
        Write-WinUtilJobProgress -Status "Adding the Ultimate Performance power plan" -State "Indeterminate"
        Write-WinUtilLog -Component "Power" -Message "Duplicating and activating the Ultimate Performance power plan."

        powercfg /setactive (powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String -Pattern '[A-Fa-f0-9-]{36}').Matches.Value

        Write-Host "Ultimate Performance power plan installed and activated."
        Show-WinUtilMessage -Message "Ultimate Power Plan plan installed and activated." -Title "Success" -Button "OK" -Icon "Information" | Out-Null
    } else {
        Write-WinUtilJobProgress -Status "Restoring the default power plans" -State "Indeterminate"
        Write-WinUtilLog -Component "Power" -Message "Restoring the default power schemes."

        powercfg /restoredefaultschemes

        Write-Host "Power plan was reset to defaults."
        Show-WinUtilMessage -Message "Power Plan was reset to defaults." -Title "Success" -Button "OK" -Icon "Information" | Out-Null
    }
}
