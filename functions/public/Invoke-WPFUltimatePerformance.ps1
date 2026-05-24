function Invoke-WPFUltimatePerformance ([switch]$Enable) {
    if ($Enable) {
        powercfg /setactive (powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String -Pattern '[A-Fa-f0-9-]{36}').Matches.Value
        [System.Windows.MessageBox]::Show("Ultimate Power Plan plan installed and activated.","Success","OK","Information")
    } else {
        powercfg /restoredefaultschemes
        [System.Windows.MessageBox]::Show("Power Plan was reset to defaults.","Success","OK","Information")
    }
}
