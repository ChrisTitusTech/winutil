function Invoke-WinUtilTaskbarWidgets {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Widgets

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Widgets

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Taskbar Widgets"
            $value = 1
        }
        else {
            Write-Host "Disabling Taskbar Widgets"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name TaskbarDa -Value $value
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
