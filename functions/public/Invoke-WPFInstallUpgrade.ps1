function Invoke-WPFInstallUpgrade {
    <#

    .SYNOPSIS
        Upgrades every package that has an update available

    .DESCRIPTION
        Runs on the worker like any other package work, so the progress bar, the taskbar item
        and the log report it the same way an install does.

    #>

    param([string]$ManagerPreference = $sync.preferences.packagemanager)

    # Queued work receives the preference selected when the user requested the upgrade.
    if ($ManagerPreference -eq "Choco") {
        Step-WinUtilJob -Status "Preparing Chocolatey" -State "Indeterminate"
        Install-WinUtilChoco

        Write-WinUtilLog -Component "Install" -Message "Upgrading all Chocolatey packages."
        Step-WinUtilJob -Status "Upgrading all Chocolatey packages" -State "Indeterminate"

        # "all" is choco's own name for every installed package, so this stays one call
        $result = Measure-WinUtilStep -Scope "Install" -Name "choco upgrade all" -ScriptBlock {
            Install-WinUtilProgramChoco -Action Upgrade -Programs @("all")
        }
        Complete-WinUtilPackageRun -Action "Upgrade" -Results @($result)
        return
    }

    Step-WinUtilJob -Status "Preparing WinGet" -State "Indeterminate"
    Install-WinUtilWinget

    Write-WinUtilLog -Component "Install" -Message "Upgrading all WinGet packages."
    Step-WinUtilJob -Status "Upgrading all WinGet packages" -State "Indeterminate"

    # Let WinGet resolve every package against its recorded source. Parsing its localized,
    # width-truncated table loses identifiers and source information.
    $result = Measure-WinUtilStep -Scope "Install" -Name "winget upgrade --all" -ScriptBlock {
        Install-WinUtilProgramWinget -Action Upgrade -Programs @("all")
    }
    Complete-WinUtilPackageRun -Action "Upgrade" -Results @($result)
}
