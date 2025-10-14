function Invoke-WPFInstallUpgrade {
    <#

    .SYNOPSIS
        Invokes the function that upgrades all installed programs

    #>
    if ($sync.ChocoRadioButton.IsChecked) {
        Install-WinUtilChoco
        $chocoUpgradeStatus = (Start-Process "choco" -ArgumentList "upgrade all -y" -Wait -PassThru -NoNewWindow).ExitCode
        if ($chocoUpgradeStatus -eq 0) {
            Write-Host "Upgrade Successful"
        }
        else{
            Write-Host "Error Occurred. Return Code: $chocoUpgradeStatus"
        }
    }
    else{
        if((Test-WinUtilPackageManager -winget) -eq "not-installed") {
            return
        }

        if(Get-WinUtilInstallerProcess -Process $global:WinGetInstall) {
            $msg = "[Invoke-WPFInstallUpgrade] Install process is currently running. Please check for a powershell window labeled 'Winget Install'"
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        Update-WinUtilProgramWinget

        Write-Host "==========================================="
        Write-Host "--           Updates started            ---"
        Write-Host "-- You can close this window if desired ---"
        Write-Host "==========================================="
    }
}
