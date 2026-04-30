function Invoke-WPFInstallUpgrade {
    if ($sync.ChocoRadioButton.IsChecked) {
        Install-WinUtilChoco # Ensure Chocolatey is installed before upgrading

        Write-Host "==========================================="
        Write-Host "--           Updates started            ---"
        Write-Host "==========================================="

        Invoke-WPFRunspace -ScriptBlock {
            Start-Process -FilePath choco.exe -ArgumentList 'upgrade all -y' -Wait -NoNewWindow
        }
    } else {
        Install-WinUtilWinget # Ensure WinGet is installed before upgrading

        Write-Host "==========================================="
        Write-Host "--           Updates started            ---"
        Write-Host "==========================================="

        Invoke-WPFRunspace -ScriptBlock {
            Start-Process -FilePath winget.exe -ArgumentList 'upgrade --all --include-unknown --silent --accept-source-agreements --accept-package-agreements' -Wait -NoNewWindow
        }
    }
}
