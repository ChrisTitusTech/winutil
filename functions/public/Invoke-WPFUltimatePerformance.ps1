Function Invoke-WPFUltimatePerformance {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>
    param($State)
    Try{

        if($state -eq "Enabled"){
            # Define the name and GUID of the power scheme you want to add
            $powerSchemeName = "Ultimate Performance"
            $powerSchemeGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"

            # Get all power schemes
            $schemes = powercfg /list | Out-String -Stream

            # Find the scheme you want to add
            $ultimateScheme = $schemes | Where-Object { $_ -match $powerSchemeName }

            # If the scheme does not exist, add it
            if ($null -eq $ultimateScheme) {
                Write-Host "Power scheme '$powerSchemeName' not found. Adding..."

                # Add the power scheme
                powercfg /duplicatescheme $powerSchemeGuid
                powercfg -attributes SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 -ATTRIB_HIDE

                Write-Host "Power scheme added successfully."
            }
            else {
                Write-Host "Power scheme '$powerSchemeName' already exists."
            }           
        }
        elseif($state -eq "Disabled"){
                # Define the name of the power scheme you want to remove
                $powerSchemeName = "Ultimate Performance"

                # Get all power schemes
                $schemes = powercfg /list | Out-String -Stream

                # Find the scheme you want to remove
                $ultimateScheme = $schemes | Where-Object { $_ -match $powerSchemeName }

                # If the scheme exists, remove it
                if ($null -ne $ultimateScheme) {
                    # Extract the GUID of the power scheme
                    $guid = ($ultimateScheme -split '\s+')[3]

                    if($null -ne $guid){
                        Write-Host "Found power scheme '$powerSchemeName' with GUID $guid. Removing..."
                        
                        # Remove the power scheme
                        powercfg /delete $guid
                        
                        Write-Host "Power scheme removed successfully."
                    }
                    else {
                        Write-Host "Could not find GUID for power scheme '$powerSchemeName'."
                    }
                }
                else {
                    Write-Host "Power scheme '$powerSchemeName' not found."
                }

            }
        
    }
    Catch{
        Write-Warning $psitem.Exception.Message
    }
}
