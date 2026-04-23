function Invoke-WPFInstallUpgrade {
    if ($sync.ChocoRadioButton.IsChecked) {
        # Ensure Chocolatey is installed before upgrading
        Install-WinUtilChoco

        Start-Process choco -ArgumentList 'upgrade all -y' -Wait -NoNewWindow

        Write-Host "==========================================="
        Write-Host "--           Updates started            ---"
        Write-Host "==========================================="
    } else {
        # Ensure WinGet is installed before upgrading
        Install-WinUtilWinget

        Start-Process -FilePath winget.exe -ArgumentList 'upgrade --all --silent --include-unknown --accept-source-agreements --accept-package-agreements' -Wait -NoNewWindow

        Write-Host "==========================================="
        Write-Host "--           Updates started            ---"
        Write-Host "==========================================="
    }
}
