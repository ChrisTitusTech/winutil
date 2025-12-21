function Invoke-WPFUpdatesdefault {
    <#

    .SYNOPSIS
        Resets Windows Update settings to default

    #>

    $ErrorActionPreference = 'SilentlyContinue'

    Write-Host "Restoring Windows Update registry settings..." -ForegroundColor Yellow

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 3

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1

    Write-Host "Restoring WaaSMedicSvc settings..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Type DWord -Value 3
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "FailureActions"

    Write-Host "Restoring update services..." -ForegroundColor Yellow

    Write-Host "Restored BITS to Manual"
    Set-Service -Name BITS -StartupType Manual

    Write-Host "Restored wuauserv to Manual"
    Set-Service -Name wuauserv -StartupType Manual

    Write-Host "Restored UsoSvc to Automatic"
    Set-Service -Name UsoSvc -StartupType Automatic

    Write-Host "Restored uhssvc to Disabled"
    Set-Service -Name uhssvc -StartupType Disabled

    Write-Host "Restored WaaSMedicSvc to Manual"
    Set-Service -Name WaaSMedicSvc -StartupType Manual

    Write-Host "Restoring renamed update service dlls..." -ForegroundColor Yellow

    $Path = "C:\Windows\System32"

    Rename-Item -Path "$Path\WaaSMedicSvc.winutil" -NewName "WaaSMedicSvc.dll"
    Rename-Item -Path "$Path\wuaueng.winutil" -NewName "wuaueng.dll"

    Write-Host "Enabling update related scheduled tasks..." -ForegroundColor Yellow

    $Tasks =
        '\Microsoft\Windows\InstallService\*',
        '\Microsoft\Windows\UpdateOrchestrator\*',
        '\Microsoft\Windows\UpdateAssistant\*',
        '\Microsoft\Windows\WaaSMedic\*',
        '\Microsoft\Windows\WindowsUpdate\*',
        '\Microsoft\WindowsUpdate\*'

    foreach ($Task in $Tasks) {
        Get-ScheduledTask -TaskPath $Task | Enable-ScheduledTask
    }

    Write-Host "Enabling driver offering through Windows Update..."

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate"

    Write-Host "Enabling Windows Update automatic restart..."

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement"

    Write-Host "Enabled driver offering through Windows Update"

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays"

    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "---  Windows Update Settings Reset to Default   ---" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green

    secedit /configure /cfg "$Env:SystemRoot\inf\defltbase.inf" /db defltbase.sdb

    Remove-Item "$path\GroupPolicyUsers" -Recurse -Force
    Remove-Item "$path\GroupPolicy" -Recurse -Force

    #Using Start-Process because this command takes along time to run
    Start-Process gpupdate -ArgumentList "/force" -WindowStyle Hidden

    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "---  Windows Local Policies Reset to Default   ---" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
