function UltimatePerformance {
    param([switch]$Enable)
    $name = "ChrisTitus - Ultimate Power Plan"

    if ($Enable) {
        if (-not (powercfg /list | Select-String $name)) {
            $guid = (powercfg /duplicatescheme "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" | Select-String '[a-f0-9-]{36}').Matches.Value

            powercfg /changename $guid $name
            powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100
            powercfg /setacvalueindex $guid SUB_PROCESSOR IDLEDISABLE 1

            powercfg /setactive $guid
            Write-Host "$name enabled" -ForegroundColor Green
        }
    } else {
        if (powercfg /list | Select-String $name) {
            $guid = (powercfg /list | Select-String $name).ToString().Split()[3]

            powercfg /setactive SCHEME_BALANCED
            powercfg /delete $guid

            Write-Host "$name removed" -ForegroundColor Red
        }
    }
}
