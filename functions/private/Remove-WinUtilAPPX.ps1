function Remove-WinUtilAPPX ($Name) {
    Write-Host "Removing $Name"
    Get-AppxPackage -Name $Name -AllUsers | Remove-AppxPackage -AllUsers
}
