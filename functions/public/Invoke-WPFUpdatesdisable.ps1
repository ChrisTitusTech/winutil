function Invoke-WPFUpdatesdisable {
    <#

    .SYNOPSIS
        Disables Windows Update

    .NOTES
        Disabling Windows Update is not recommended. This is only for advanced users who know what they are doing.

    #>

    Write-Host "Configuring registry settings..." -ForegroundColor Yellow
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0

    # Additional registry settings
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Type DWord -Value 4
    $failureActions = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0xd4,0x01,0x00,0x00,0x00,0x00,0x00,0xe0,0x93,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "FailureActions" -Type Binary -Value $failureActions

    Write-Host "Disabling update services..." -ForegroundColor Yellow

    $Services =
        "BITS",
        "wuauserv",
        "UsoSvc",
        "WaaSMedicSvc"

    foreach ($Service in Get-Service $Services) {
        Write-Host "Disabled $($service.Name)"
        Set-Service -Name $service -StartupType Disabled
    }

    Write-Host "Renaming critical update service dlls..." -ForegroundColor Yellow

    $Path = "C:\Windows\System32"

    takeown /f "$Path\WaaSMedicSvc.dll"
    takeown /f "$Path\wuaueng.dll"

    icacls "$Path\WaaSMedicSvc.dll" /grant "Administrators:(F)"
    icacls "$Path\wuaueng.dll" /grant "Administrators:(F)"

    Rename-Item -Path "$Path\WaaSMedicSvc.dll" -NewName "WaaSMedicSvc.winutil"
    Rename-Item -Path "$Path\wuaueng.dll" -NewName "wuaueng.winutil"

    Write-Host "Cleaning up downloaded update files..." -ForegroundColor Yellow

    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force
    Write-Host "Cleared SoftwareDistribution folder"

    Write-Host "Disabling update related scheduled tasks..." -ForegroundColor Yellow

    $Tasks =
        '\Microsoft\Windows\InstallService\*',
        '\Microsoft\Windows\UpdateOrchestrator\*',
        '\Microsoft\Windows\UpdateAssistant\*',
        '\Microsoft\Windows\WaaSMedic\*',
        '\Microsoft\Windows\WindowsUpdate\*',
        '\Microsoft\WindowsUpdate\*'

    foreach ($Task in $Tasks) {
        Get-ScheduledTask -TaskPath $Task | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
