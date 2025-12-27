function Invoke-WPFFixesWinget {
    Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
    
    Install-PackageProvider -Name NuGet -Force
    Install-Module "Microsoft.WinGet.Client" -Force
    Repair-WinGetPackageManager

    Write-Host "==> Finished Winget Repair"
}
