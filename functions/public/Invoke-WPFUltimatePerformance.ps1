function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Do
    )

    if ($Do) {
        if (-not (powercfg /list | Select-String "Ultimate Performance")) {
            powercfg /setactive ((powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61).Split()[3])
            Write-Host "Ultimate Performance plan installed and activated." -ForegroundColor Green
        } else {
            Write-Host "Ultimate Performance plan is already installed." -ForegroundColor Red
            return
        }
    } else {
        powercfg /setactive SCHEME_BALANCED

        foreach ($line in powercfg /list) {
            if ($line -like '*Ultimate Performance*') {
                powercfg /delete ($line.Split()[3])
            }

        Write-Host "Ultimate Performance plan was removed." -ForegroundColor Red
    }
}
