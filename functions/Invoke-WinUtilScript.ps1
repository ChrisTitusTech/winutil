function Invoke-WinUtilScript {
    <#
    
        .DESCRIPTION
        This function will run a seperate powershell script. Meant for things that can't be handled with the other functions

        .EXAMPLE

        $Scriptblock = [scriptblock]::Create({"Write-output 'Hello World'"})
        Invoke-WinUtilScript -ScriptBlock $scriptblock -Name "Hello World"
    
    #>
    param (
        $Name,
        [scriptblock]$scriptblock
    )

    Try{
        Start-Process powershell.exe -Verb runas -ArgumentList "-Command  $scriptblock" -Wait -ErrorAction Stop
    }
    Catch{
        Write-Warning "Unable to run script for $name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}