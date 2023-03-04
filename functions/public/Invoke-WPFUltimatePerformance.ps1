Function Invoke-WPFUltimatePerformance {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>
    param($State)
    Try{
        $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"

        if($state -eq "Enabled"){
            Write-Host "Adding Ultimate Performance Profile"
            [scriptblock]$command = {powercfg -duplicatescheme $guid}
            
        }
        if($state -eq "Disabled"){
            Write-Host "Removing Ultimate Performance Profile"
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