function Invoke-WinUtilHiddenFiles {
    <#

    .SYNOPSIS
        Enable/Disable Hidden Files

    .PARAMETER Enabled
        Indicates whether to enable or disable Hidden Files

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Hidden Files"
            $value = 1
        } else {
            Write-Host "Disabling Hidden Files"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name Hidden -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
