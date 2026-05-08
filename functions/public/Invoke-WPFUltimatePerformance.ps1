function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Do
    )

    if ($Do) {
        powercfg /restoredefaultschemes
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "Ultimate Power Plan plan installed and activated." -ForegroundColor Green
    } else {
        powercfg /setactive SCHEME_BALANCED
        Write-Host "Ultimate Power Plan plan was removed." -ForegroundColor Red
    }
}
