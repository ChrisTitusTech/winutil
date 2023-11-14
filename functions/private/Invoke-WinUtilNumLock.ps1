function Invoke-WinUtilNumLock {
    <#
    .SYNOPSIS
        Disables/Enables NumLock on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Numlock on startup
    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Numlock on startup"
            $value = 2
        }
        else {
            Write-Host "Disabling Numlock on startup"
            $value = 0
        }
        $Path = "HKCU:\Control Panel\Keyboard"
        Set-ItemProperty -Path $Path -Name InitialKeyboardIndicators -Value $value
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