function Test-WinUtilPackageManager {
    <#

    .SYNOPSIS
        Checks if WinGet and/or Choco are installed

    .PARAMETER winget
        Check if WinGet is installed

    .PARAMETER choco
        Check if Chocolatey is installed

    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    if ($winget) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-WinUtilJobBanner -Message "WinGet is installed"
            $status = "installed"
        } else {
            Write-WinUtilJobBanner -Message "WinGet is not installed" -Level "ERROR"
            $status = "not-installed"
        }
    }

    if ($choco) {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-WinUtilJobBanner -Message "Chocolatey is installed"
            $status = "installed"
        } else {
            Write-WinUtilJobBanner -Message "Chocolatey is not installed" -Level "ERROR"
            $status = "not-installed"
        }
    }

    return $status
}
