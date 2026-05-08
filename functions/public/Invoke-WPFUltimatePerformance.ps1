function Invoke-WPFUltimatePerformance {
    param(
        [switch]$Do
    )

    if ($Do) {
        powercfg /restoredefaultschemes
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
        [System.Windows.MessageBox]::Show("Ultimate Power Plan installed and activated.")
    } else {
        powercfg /setactive SCHEME_BALANCED
        powercfg /delete e9a42b02-d5df-448d-aa00-03f14749eb61
        [System.Windows.MessageBox]::Show("Ultimate Power Plan plan was removed.")
    }
}
