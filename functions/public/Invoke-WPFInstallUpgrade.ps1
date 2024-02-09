function Invoke-WPFInstallUpgrade {
    <#

    .SYNOPSIS
        Invokes the function that upgrades all installed programs using winget

    #>
    if(!(Get-Command -Name winget -ErrorAction SilentlyContinue)){
        Write-Host "==========================================="
        Write-Host "--       Winget is not installed        ---"
        Write-Host "==========================================="
        return
    }

    if(Get-WinUtilInstallerProcess -Process $global:WinGetInstall){
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