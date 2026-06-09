function Remove-WinUtilAPPX ($Name) {
    Write-Host "Removing $Name"
    Get-AppxPackage $Name -AllUsers | Remove-AppxPackage -AllUsers
}
