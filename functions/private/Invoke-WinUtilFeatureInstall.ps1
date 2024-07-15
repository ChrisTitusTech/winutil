function Invoke-WinUtilFeatureInstall {
    <#

    .SYNOPSIS
        Converts all the values from the tweaks.json and routes them to the appropriate function

    #>

    param(
        $CheckBox
    )

    $x = 0

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
                        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" })
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
                        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" })
                    }

                    else{
                        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" })
                        Write-Warning "Unable to Install $feature due to unhandled exception"
                        Write-Warning $psitem.Exception.StackTrace
                    }
                }
            }
        }
        $X++
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$CheckBox.Count) })
    }
}
