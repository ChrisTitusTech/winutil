function Invoke-WinUtilShowExt {
    <#
    .SYNOPSIS
        Disables/Enables Show file Extentions
    .PARAMETER Enabled
        Indicates whether to enable or disable Show file extentions
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Showing file extentions"
            $value = 0
        } else {
            Write-Host "hiding file extensions"
            $value = 1
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name HideFileExt -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
