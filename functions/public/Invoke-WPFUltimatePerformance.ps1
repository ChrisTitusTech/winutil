function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Enable
    )

    if ($Enable) {
        powercfg /setactive (powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String -Pattern '[A-Fa-f0-9-]{36}').Matches.Value
        Write-Host "Ultimate Power Plan plan installed and activated." -ForegroundColor Green
    } else {
        powercfg /restoredefaultschemes
        Write-Host "Power Plan was reset to defaults" -ForegroundColor Red
    }
}
