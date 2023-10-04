function Invoke-WinUtilFeatureInstall {
    <#
    
        .DESCRIPTION
        This function converts all the values from the tweaks.json and routes them to the appropriate function
    
    #>

    param(
        $CheckBox
    )

    $CheckBox | ForEach-Object {
        if($sync.configs.feature.$psitem.feature){
            Foreach( $feature in $sync.configs.feature.$psitem.feature ){
                Try{ 
                    Write-Host "Installing $feature"
                    Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
                }
                Catch{
                    if ($psitem.Exception.Message -like "*requires elevation*"){
                        Write-Warning "Unable to Install $feature due to permissions. Are you running as admin?"
                    }

                    else{
                        Write-Warning "Unable to Install $feature due to unhandled exception"
                        Write-Warning $psitem.Exception.StackTrace 
                    }
                }
            } 
        }
        if($sync.configs.feature.$psitem.InvokeScript){
            Foreach( $script in $sync.configs.feature.$psitem.InvokeScript ){
                Try{
                    $Scriptblock = [scriptblock]::Create($script)

                    Write-Host "Running Script for $psitem"
                    Invoke-Command $scriptblock -ErrorAction stop
                }
                Catch{
                    if ($psitem.Exception.Message -like "*requires elevation*"){
                        Write-Warning "Unable to Install $feature due to permissions. Are you running as admin?"
                    }

                    else{
                        Write-Warning "Unable to Install $feature due to unhandled exception"
                        Write-Warning $psitem.Exception.StackTrace 
                    }
                }
            } 
        }
    }
}
