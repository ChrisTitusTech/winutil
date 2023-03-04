function Set-WinUtilScheduledTask {
    <#
    
        .DESCRIPTION
        This function will enable/disable the provided Scheduled Task

        .EXAMPLE

        Set-WinUtilScheduledTask -Name "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -State "Disabled"
    
    #>
    param (
        $Name,
        $State
    )

    Try{
        if($State -eq "Disabled"){
            Write-Host "Disabling Scheduled Task $Name"
            Disable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
        if($State -eq "Enabled"){
            Write-Host "Enabling Scheduled Task $Name"
            Enable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
    }
    Catch [System.Exception]{
        if($psitem.Exception.Message -like "*The system cannot find the file specified*"){
            Write-Warning "Scheduled Task $name was not Found"
        }
        Else{
            Write-Warning "Unable to set $Name due to unhandled exception"
            Write-Warning $psitem.Exception.Message
        }
    }
    Catch{
        Write-Warning "Unable to run script for $name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}