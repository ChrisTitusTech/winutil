function Invoke-WPFUpdatesdisable {

    takeown /f $Env:SystemRoot\System32\usosvc.dll | Out-Null
    icacls $Env:SystemRoot\System32\usosvc.dll /grant Everyone:F | Out-Null
    Rename-Item -Path $Env:SystemRoot\System32\usosvc.dll -NewName usosvc.dlle

    takeown /f $Env:SystemRoot\System32\wuaueng.dll | Out-Null
    icacls $Env:SystemRoot\System32\wuaueng.dll /grant Everyone:F | Out-Null
    Rename-Item -Path $Env:SystemRoot\System32\wuaueng.dll -NewName wuaueng.dlle

    Remove-Item -Path $Env:SystemRootSoftwareDistribution\* -Recurse -Force

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates Are Disabled    ---" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    Write-Host "Note: You must restart your system in order for all changes to take effect." -ForegroundColor Yellow
}
