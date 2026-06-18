function Invoke-WPFUpdatesdisable {
    Write-Host "Note: This will prevent you from using the Microsoft Store." -ForegroundColor Yellow

    takeown /f $Env:SystemRoot\System32\usosvc.dll
    icacls $Env:SystemRoot\System32\usosvc.dll /deny Everyone:F

    takeown /f $Env:SystemRoot\System32\wuaueng.dll
    icacls $Env:SystemRoot\System32\wuaueng.dll /deny Everyone:F

    Remove-Item -Path $Env:SystemRootSoftwareDistribution\* -Recurse -Force

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
