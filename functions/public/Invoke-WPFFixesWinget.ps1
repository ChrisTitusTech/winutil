function Invoke-WPFFixesWinget {

    <#

    .SYNOPSIS
        Fixes Winget by running choco install winget
    .DESCRIPTION
        BravoNorris for the fantastic idea of a button to reinstall winget
    #>
    # Install Choco if not already present
    try {
        Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
        Install-WinUtilChoco
        Start-Process -FilePath "choco" -ArgumentList "install winget -y --force" -NoNewWindow -Wait
    } catch {
        Write-Error "Failed to install winget: $_"
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    } finally {
        Write-Host "==> Finished Winget Repair"
        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
    }

}
