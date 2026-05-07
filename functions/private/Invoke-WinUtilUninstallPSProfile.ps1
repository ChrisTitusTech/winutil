function Invoke-WinUtilUninstallPSProfile {
    Remove-Item -Path $Profile
    Write-Host "Successfully uninstalled CTT PowerShell Profile." -ForegroundColor Green
}
