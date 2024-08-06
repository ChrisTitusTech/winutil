function Invoke-WinUtilNumLock {
    <#
    .SYNOPSIS
        Disables/Enables NumLock on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Numlock on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Numlock on startup"
            $value = 2
        } else {
            Write-Host "Disabling Numlock on startup"
            $value = 0
        }
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        $HKUPath = "HKU:\.Default\Control Panel\Keyboard"
        $HKCUPath = "HKCU:\Control Panel\Keyboard"
        Set-ItemProperty -Path $HKUPath -Name InitialKeyboardIndicators -Value $value
        Set-ItemProperty -Path $HKCUPath -Name InitialKeyboardIndicators -Value $value
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
