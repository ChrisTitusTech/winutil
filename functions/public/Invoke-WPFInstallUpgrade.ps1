function Invoke-WPFInstallUpgrade {
    <#

    .SYNOPSIS
        Upgrades every installed package, in a window of its own so the user can close WinUtil

    #>

    if ($sync.ChocoRadioButton.IsChecked) {
        Write-WinUtilJobProgress -Status "Preparing Chocolatey" -State "Indeterminate"
        Install-WinUtilChoco # Ensure Chocolatey is installed before upgrading

        Write-WinUtilLog -Component "Install" -Message "Starting a Chocolatey upgrade of all packages in a separate window."
        Start-Process -FilePath powershell.exe -ArgumentList 'choco upgrade all -y'
    } else {
        Write-WinUtilJobProgress -Status "Preparing WinGet" -State "Indeterminate"
        Install-WinUtilWinget # Ensure WinGet is installed before upgrading

        Write-WinUtilLog -Component "Install" -Message "Starting a WinGet upgrade of all packages in a separate window."
        Start-Process -FilePath powershell.exe -ArgumentList '-NoExit winget upgrade --all --include-unknown --silent --accept-source-agreements --accept-package-agreements'
    }

    Write-Host "The upgrade runs in its own window. You can close WinUtil while it works."
}
