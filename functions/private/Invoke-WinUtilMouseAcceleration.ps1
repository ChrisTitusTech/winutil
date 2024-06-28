Function Invoke-WinUtilMouseAcceleration {
    <#

    .SYNOPSIS
        Enables/Disables Mouse Acceleration

    .PARAMETER DarkMoveEnabled
        Indicates the current Mouse Acceleration State

    #>
    Param($MouseAccelerationEnabled)
    Try{
        if ($MouseAccelerationEnabled -eq $false){
            Write-Host "Enabling Mouse Acceleration"
            $MouseSpeed = 1
            $MouseThreshold1 = 6
            $MouseThreshold2 = 10
        }
        else {
            Write-Host "Disabling Mouse Acceleration"
            $MouseSpeed = 0
            $MouseThreshold1 = 0
            $MouseThreshold2 = 0

        }

        $Path = "HKCU:\Control Panel\Mouse"
        Set-ItemProperty -Path $Path -Name MouseSpeed -Value $MouseSpeed
        Set-ItemProperty -Path $Path -Name MouseThreshold1 -Value $MouseThreshold1
        Set-ItemProperty -Path $Path -Name MouseThreshold2 -Value $MouseThreshold2
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}