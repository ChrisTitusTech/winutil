Function Invoke-WPFUltimatePerformance {
    <#

    .SYNOPSIS
        Enables or disables the Ultimate Performance power scheme based on its GUID.

    .PARAMETER State
        Specifies whether to "Enable" or "Disable" the Ultimate Performance power scheme.

    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Enable", "Disable")]
        [string]$State
    )

    try {
        # GUID of the Ultimate Performance power plan
        $ultimateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"

        switch ($State) {
            "Enable" {
                # Duplicate the Ultimate Performance power plan using its GUID
                $duplicateOutput = powercfg /duplicatescheme $ultimateGUID

                $guid = $null
                $nameFromFile = "ChrisTitus - Ultimate Power Plan"
                $description = "Ultimate Power Plan, added via WinUtils"

                # Extract the new GUID from the duplicateOutput
                foreach ($line in $duplicateOutput) {
                    if ($line -match "\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b") {
                        $guid = $matches[0]  # $matches[0] will contain the first match, which is the GUID
                        Write-Output "GUID: $guid has been extracted and stored in the variable."
                        break
                    }
                }

                if (-not $guid) {
                    Write-Output "No GUID found in the duplicateOutput. Check the output format."
                    exit 1
                }

                # Change the name of the power plan and set its description
                $changeNameOutput = powercfg /changename $guid "$nameFromFile" "$description"
                Write-Output "The power plan name and description have been changed. Output:"
                Write-Output $changeNameOutput

                # Set the duplicated Ultimate Performance plan as active
                $setActiveOutput = powercfg /setactive $guid
                Write-Output "The power plan has been set as active. Output:"
                Write-Output $setActiveOutput

                Write-Host "> Ultimate Performance plan installed and set as active."
            }
            "Disable" {
                # Check if the Ultimate Performance plan is installed by GUID
                $installedPlan = powercfg -list | Select-String -Pattern "ChrisTitus - Ultimate Power Plan"

                if ($installedPlan) {
                    # Extract the GUID of the installed Ultimate Performance plan
                    $ultimatePlanGUID = $installedPlan.Line.Split()[3]

                    # Set a different power plan as active before deleting the Ultimate Performance plan
                    $balancedPlanGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
                    powercfg -setactive $balancedPlanGUID

                    # Delete the Ultimate Performance plan by GUID
                    powercfg -delete $ultimatePlanGUID

                    Write-Host "Ultimate Performance plan has been uninstalled."
                    Write-Host "> Balanced plan is now active."
                } else {
                    Write-Host "Ultimate Performance plan is not installed."
                }
            }
            default {
                Write-Host "Invalid state. Please use 'Enable' or 'Disable'."
            }
        }
    } catch {
        Write-Error "Error occurred: $_"
    }
}
