function Invoke-WPFUpdatesdisable {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name SettingsPageVisibility -Value hide:windowsupdate
    Write-Host "Windows Update will not be hidden from settings"

    takeown /f $Env:SystemRoot\System32\usosvc.dll | Out-Null
    icacls $Env:SystemRoot\System32\usosvc.dll /grant Everyone:F | Out-Null
    Rename-Item -Path $Env:SystemRoot\System32\usosvc.dll -NewName usosvc.dlle

    takeown /f $Env:SystemRoot\System32\wuaueng.dll | Out-Null
    icacls $Env:SystemRoot\System32\wuaueng.dll /grant Everyone:F | Out-Null
    Rename-Item -Path $Env:SystemRoot\System32\wuaueng.dll -NewName wuaueng.dlle

    Write-Host "Windows Update dlls renamed."

    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force
    Write-Host "Cleared SoftwareDistribution folder"

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
