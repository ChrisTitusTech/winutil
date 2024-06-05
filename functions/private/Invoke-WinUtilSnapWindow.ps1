function Invoke-WinUtilSnapWindow {
    <#
    .SYNOPSIS
        Disables/Enables Snapping Windows on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Snapping Windows on startup
    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Snap Windows On startup | Relogin Required"
            $value = 1
        }
        else {
            Write-Host "Disabling Snap Windows On startup | Relogin Required"
            $value = 0
        }
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name WindowArrangementActive -Value $value
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