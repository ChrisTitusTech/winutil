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
        $undo = $false,
        $tabname = "tweaks"
    )

    Write-Debug "$($tabname): $($CheckBox)"
    if($undo){
        $Values = @{
            Registry = "OriginalValue"
            ScheduledTask = "OriginalState"
            Service = "OriginalType"
            ScriptType = "UndoScript"
        }

    }
    Else{
        $Values = @{
            Registry = "Value"
            ScheduledTask = "State"
            Service = "StartupType"
            ScriptType = "InvokeScript"
        }
    }
    if($sync.configs.$tabname.$CheckBox.ScheduledTask){
        $sync.configs.$tabname.$CheckBox.ScheduledTask | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.ScheduledTask))"
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.$($values.ScheduledTask)
        }
    }
    if($sync.configs.$tabname.$CheckBox.service){
        $sync.configs.$tabname.$CheckBox.service | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.service))"
            Set-WinUtilService -Name $psitem.Name -StartupType $psitem.$($values.Service)
        }
    }
    if($sync.configs.$tabname.$CheckBox.registry){
        $sync.configs.$tabname.$CheckBox.registry | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.registry))"
            Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
        }
    }
    if($sync.configs.$tabname.$CheckBox.$($values.ScriptType)){
        $sync.configs.$tabname.$CheckBox.$($values.ScriptType) | ForEach-Object {
            Write-Debug "$($psitem) and state is $($psitem.$($values.ScriptType))"
            $Scriptblock = [scriptblock]::Create($psitem)
            Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
        }
    }

    if(!$undo){
        if($sync.configs.$tabname.$CheckBox.appx){
            $sync.configs.$tabname.$CheckBox.appx | ForEach-Object {
                Write-Debug "UNDO $($psitem.Name)"
                Remove-WinUtilAPPX -Name $psitem
            }
        }
        if($sync.configs.$tabname.$CheckBox.feature){
            Foreach( $feature in $sync.configs.feature.$CheckBox.feature ){
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
    
    }
}