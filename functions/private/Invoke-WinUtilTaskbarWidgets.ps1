function Invoke-WinUtilTaskbarWidgets {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Widgets

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Widgets

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Taskbar Widgets"
            $value = 1
        } else {
            Write-Host "Disabling Taskbar Widgets"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name TaskbarDa -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
