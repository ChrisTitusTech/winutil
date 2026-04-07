function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Do
    )

    if ($Do) {
        if (-not (powercfg /list | Select-String "Ultimate Performance")) {
            powercfg /restoredefaultschemes
            powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
            Write-Host "Ultimate Performance plan installed and activated." -ForegroundColor Green
        } else {
            Write-Host "Ultimate Performance plan is already installed." -ForegroundColor Red
            return
        }
    } else {
        if (powercfg /list | Select-String "Ultimate Performance") {
            powercfg /setactive SCHEME_BALANCED
            powercfg /delete e9a42b02-d5df-448d-aa00-03f14749eb61
            Write-Host "Ultimate Performance plan was removed." -ForegroundColor Red
        } else {
            Write-Host "Ultimate Performance plan is not installed." -ForegroundColor Yellow
        }
    }
}
