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
            # Duplicate and activate Ultimate Performance plan
            $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String "Power Scheme GUID").Line.Split()[3]
            
            powercfg /setactive $guid
            Write-Host "Activated Ultimate Performance power plan" -ForegroundColor Green
        }

        "Disable" {
            # Get current plan (the ultimate plan) and switch to Balanced, then remove Ultimate Performance
            powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

            foreach ($line in powercfg /list | Select-String 'Ultimate Performance') {
                powercfg /delete ($line.Line.Split()[3])
            }
            
            Write-Host "Removed Ultimate Performance power plan" -ForegroundColor Red
        }
    }
}
