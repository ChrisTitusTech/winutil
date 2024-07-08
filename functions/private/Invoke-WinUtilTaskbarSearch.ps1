function Invoke-WinUtilTaskbarSearch {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Search Button.

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Search Button.

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Search Button"
            $value = 1
        }
        else {
            Write-Host "Disabling Search Button"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\"
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $value
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
