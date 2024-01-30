function Invoke-WinUtilTweaks {
    <#

    .SYNOPSIS
        Invokes the function associated with each provided checkbox

    .PARAMETER CheckBox
        The checkbox to invoke

    .PARAMETER undo
        Indicates whether to undo the operation contained in the checkbox

    #>

    param(
        $CheckBox,
        $undo = $false
    )

    Write-Debug "Tweaks: $($CheckBox)"
    if($undo){
        $Values = @{
            Registry = "OriginalValue"
            ScheduledTask = "OriginalState"
            Service = "OriginalType"
            ScriptType = "UndoScript"
            WingetArg = "Uninstall -e --purge --force"
        }

    }
    Else{
        $Values = @{
            Registry = "Value"
            ScheduledTask = "State"
            Service = "StartupType"
            ScriptType = "InvokeScript"
            WingetArg = "Install -e --accept-source-agreements --accept-package-agreements --scope=machine"
        }
    }
    # if($sync.configs.tweaks.$CheckBox.apps){
    #     $sync.configs.tweaks.$CheckBox.apps | ForEach-Object {
    #         Write-Host "$(($values.WingetArg -split " ")[0]) $($psitem.WingetArg)"
    #         Start-Process -FilePath winget -ArgumentList "$($values.WingetArg) --silent $($psitem.winget)" -NoNewWindow -Wait
    #     }
    # }
    if($sync.configs.applications.$CheckBox.winget){
        Write-Host "$(($values.WingetArg -split " ")[0]) $sync.configs.tweaks.$CheckBox.content "
        Start-Process -FilePath winget -ArgumentList "$($values.WingetArg) --silent $($sync.configs.applications.$CheckBox.winget)" -NoNewWindow -Wait
    }
    if($sync.configs.tweaks.$CheckBox.winget){
        Write-Host "$(($values.WingetArg -split " ")[0]) $sync.configs.tweaks.$CheckBox.content "
        Start-Process -FilePath winget -ArgumentList "$($values.WingetArg) --silent $($sync.configs.tweaks.$CheckBox.winget)" -NoNewWindow -Wait
    }
    if($sync.configs.tweaks.$CheckBox.ScheduledTask){
        $sync.configs.tweaks.$CheckBox.ScheduledTask | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.ScheduledTask))"
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.$($values.ScheduledTask)
        }
    }
    if($sync.configs.tweaks.$CheckBox.service){
        $sync.configs.tweaks.$CheckBox.service | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.service))"
            Set-WinUtilService -Name $psitem.Name -StartupType $psitem.$($values.Service)
        }
    }
    if($sync.configs.tweaks.$CheckBox.registry){
        $sync.configs.tweaks.$CheckBox.registry | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.registry))"
            Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
        }
    }
    if($sync.configs.tweaks.$CheckBox.$($values.ScriptType)){
        $sync.configs.tweaks.$CheckBox.$($values.ScriptType) | ForEach-Object {
            Write-Debug "$($psitem) and state is $($psitem.$($values.ScriptType))"
            $Scriptblock = [scriptblock]::Create($psitem)
            Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
        }
    }
    if(!$undo){
        if($sync.configs.tweaks.$CheckBox.appx){
            $sync.configs.tweaks.$CheckBox.appx | ForEach-Object {
                Write-Debug "UNDO $($psitem.Name)"
                Remove-WinUtilAPPX -Name $psitem
            }
        }

    }
    Write-Debug $sync.configs.feature.$CheckBox.feature
    Write-Debug "11111111111111111111111"
    if($sync.configs.feature.$CheckBox.feature){
        Write-Debug "11111111111111111111111"
        Foreach( $feature in $sync.configs.feature.$CheckBox.feature ){
            Try{
                Write-Host "Installing $feature"
                Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
            }
            Catch{
                if ($CheckBox.Exception.Message -like "*requires elevation*"){
                    Write-Warning "Unable to Install $feature due to permissions. Are you running as admin?"
                }

                else{
                    Write-Warning "Unable to Install $feature due to unhandled exception"
                    Write-Warning $CheckBox.Exception.StackTrace
                }
            }
        }
    }
    if($sync.configs.feature.$CheckBox.InvokeScript){
        Write-Debug "11111111111111111111111"
        Foreach( $script in $sync.configs.feature.$CheckBox.InvokeScript ){
            Try{
                $Scriptblock = [scriptblock]::Create($script)

                Write-Host "Running Script for $CheckBox"
                Invoke-Command $scriptblock -ErrorAction stop
            }
            Catch{
                if ($CheckBox.Exception.Message -like "*requires elevation*"){
                    Write-Warning "Unable to Install $feature due to permissions. Are you running as admin?"
                }

                else{
                    Write-Warning "Unable to Install $feature due to unhandled exception"
                    Write-Warning $CheckBox.Exception.StackTrace
                }
            }
        }
    }
}