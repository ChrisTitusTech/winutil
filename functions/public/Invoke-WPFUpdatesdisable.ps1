function Invoke-WPFUpdatesdisable {
    <#

    .SYNOPSIS
        Disables Windows Update

    .NOTES
        Disabling Windows Update is not recommended. This is only for advanced users who know what they are doing.
        This function requires administrator privileges.

    #>

    Write-Host "Stoping and disabling Windows Updates service"

    Stop-Service usosvc -Force
    Set-Service usosvc -StartupType Disabled

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates ARE DISABLED    ---" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
}
