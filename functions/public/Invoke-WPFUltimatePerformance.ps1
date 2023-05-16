Function Invoke-WPFUltimatePerformance {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>
    param($State)
    Try{

        if($state -eq "Enabled"){
            $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
            Write-Host "Adding Ultimate Performance Profile"
            [scriptblock]$command = {powercfg -duplicatescheme $guid}
            
        }
        if($state -eq "Disabled"){
            # Get the GUID of the Ultimate Power Plan
            $ultimatePowerPlan = powercfg /list | Select-String -Pattern "Ultimate Performance" -Context 0,1 | Select-Object -First 1 -ExpandProperty Line
            $powerPlanGuid = $ultimatePowerPlan -replace ".*\((.*)\).*", '$1'

# Check if the Ultimate Power Plan is present
            $existingPlan = Get-WmiObject -Namespace root\cimv2\power -Class Win32_PowerPlan | Where-Object {$_.InstanceID -eq $powerPlanGuid}

            if ($existingPlan) {
                # Delete the Ultimate Power Plan
                $existingPlan.Delete()
                Write-Host "Ultimate Power Plan has been removed."
            } else {
                Write-Host "Ultimate Power Plan not found. No action required."
            }
            [scriptblock]$command = {powercfg -delete $guid}
        }
        
        $output = Invoke-Command -ScriptBlock $command
        if($output -like "*does not exist*"){
            throw [GenericException]::new('Failed to modify profile')
        }
    }
    Catch{
        Write-Warning $psitem.Exception.Message
    }
}
