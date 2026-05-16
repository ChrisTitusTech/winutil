function Invoke-WPFUpdatesdefault {

    Write-Host "Showing Windows Updates in settings"
    Remove-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name SettingsPageVisibility

    Set-Service -Name wuauserv -StartupType Manual
    Start-Service -Name wuauserv
    Write-Host "Restored wuauserv to Manual"

    Set-Service -Name UsoSvc -StartupType Automatic
    Start-Service -Name UsoSvc
    Write-Host "Restored UsoSvc to Automatic"

    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "---  Windows Update Settings Reset to Default   ---" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
}
