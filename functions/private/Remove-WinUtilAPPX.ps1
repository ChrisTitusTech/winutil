function Remove-WinUtilAPPX ($Name) {
    Write-Host "Removing $Name"
    Get-AppxPackage -Package $Name -AllUsers | Remove-AppxPackage -AllUsers
}
