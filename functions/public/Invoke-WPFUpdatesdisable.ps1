function Invoke-WPFUpdatesdisable {
    Write-Host "Note: This will prevent you from using the Microsoft Store." -ForegroundColor Yellow

    Write-Host "Disabling windows update services"

    Set-Service -Name UsoSvc -StartupType Disabled
    Set-Service -Name wuauserv -StartupType Disabled

    Write-Host "Blocking execution of windows update dlls"

    takeown /f $Env:SystemRoot\System32\usosvc.dll
    icacls $Env:SystemRoot\System32\usosvc.dll /grant Everyone:F
    Rename-Item -Path $Env:SystemRoot\System32\usosvc.dll -NewName usosvc.dlle

    takeown /f $Env:SystemRoot\System32\wuaueng.dll
    icacls $Env:SystemRoot\System32\wuaueng.dll /grant Everyone:F
    Rename-Item -Path $Env:SystemRoot\System32\wuaueng.dll -NewName wuaueng.dlle

    Write-Host "Clearing SoftwareDistribution folder"
    Remove-Item -Path $Env:SystemRoot\SoftwareDistribution\* -Recurse -Force

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
