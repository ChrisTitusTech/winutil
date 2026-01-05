function Invoke-WPFFixesWinget {
    Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
    
    Install-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module "Microsoft.WinGet.Client" -Force
    Import-Module Microsoft.WinGet.Client
    Repair-WinGetPackageManager

    Write-Host "==> Finished Winget Repair"
}
