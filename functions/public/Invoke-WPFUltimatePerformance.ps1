Function Invoke-WPFUltimatePerformance {
    <#
    .SYNOPSIS
        Enables or disables the Ultimate Performance power plan.

    .PARAMETER State
        "Enable" to enable, "Disable" to disable the Ultimate Performance plan.
    #>

    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Enable", "Disable")]
        [string]$State
    )

    switch ($State) {
        "Enable" {
            if (-not powercfg /list | Select-String 'Ultimate Performance' {
                powercfg /setactive (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String 'Power Scheme GUID').Line.Split()[3]
                Write-Host 'Activated Ultimate Performance power plan' -ForegroundColor Green
            }
            else {
                Write-Host 'Ultimate Performance power plan is already enabled' -ForegroundColor Red
            }
        "Disable" {
            powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

            foreach ($line in powercfg /list) {
                if ($line -like '*Ultimate Performance*') {
                    powercfg /delete ($line.Split()[3])
                }
            }
            Write-Host "Removed Ultimate Performance power plan" -ForegroundColor Red
        }
    }
}
