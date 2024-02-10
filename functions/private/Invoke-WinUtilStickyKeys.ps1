Function Invoke-WinUtilStickyKeys {
    <#
    .SYNOPSIS
        Disables/Enables Sticky Keyss on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Sticky Keys on startup
    #>
    Param($Enabled)
    Try { 
        if ($Enabled -eq $false){
            Write-Host "Enabling Sticky Keys On startup"
            $value = 510
        }
        else {
            Write-Host "Disabling Sticky Keys On startup"
            $value = 58
        }
        $Path = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Set-ItemProperty -Path $Path -Name Flags -Value $value
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