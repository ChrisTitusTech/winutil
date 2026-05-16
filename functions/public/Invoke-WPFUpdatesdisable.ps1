function Invoke-WPFUpdatesdisable {

    Write-Host "Hiding Windows Updates from settings"
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name SettingsPageVisibility -Value hide:windowsupdate

    Stop-Service -Name wuauserv -Force
    Set-Service -Name wuauserv -StartupType Disabled
    Write-Host "Disabled wuauserv Service"

    Stop-Service -Name UsoSvc -Force
    Set-Service -Name UsoSvc -StartupType Disabled
    Write-Host "Disabled UsoSvc Service"

    Write-Host "Clearing SoftwareDistribution folder"
    Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
}
