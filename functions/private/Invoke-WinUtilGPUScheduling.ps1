function Invoke-WinUtilGPUScheduling {
    <#

    .SYNOPSIS
        Enables/Disables Hardware-Accelerated GPU Scheduling

    .PARAMETER DarkMoveEnabled
        Indicates the current GPU Acceleration State

    #>
    Param($GPUAccelerationEnabled)
    try {
        if ($GPUAccelerationEnabled -eq $false) {
            Write-Host "Enabling Hardware-Accelerated GPU Scheduling | Reboot required!"
            $value = 2

        } else {
            Write-Host "Disabling Hardware-Accelerated GPU Scheduling | Reboot required!"
            $value = 1
        }
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty -Path $Path -Name HwSchMode -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
