function Invoke-WinUtilSnapFlyout {
    <#
    .SYNOPSIS
        Disables/Enables Snap Assist Flyout on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Snap Assist Flyout on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Snap Assist Flyout On startup"
            $value = 1
        } else {
            Write-Host "Disabling Snap Assist Flyout On startup"
            $value = 0
        }

        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        taskkill.exe /F /IM "explorer.exe"
        Set-ItemProperty -Path $Path -Name EnableSnapAssistFlyout -Value $value
        Start-Process "explorer.exe"
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
