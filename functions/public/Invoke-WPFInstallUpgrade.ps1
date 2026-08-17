function Invoke-WPFInstallUpgrade {
    <#

    .SYNOPSIS
        Upgrades every package that has an update available

    .DESCRIPTION
        Runs on the worker like any other package work, so the progress bar, the taskbar item
        and the log report it the same way an install does. Each package is a step of the run
        rather than the whole thing being one opaque wait.

    #>

    if ($sync.ChocoRadioButton.IsChecked) {
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

    Step-WinUtilJob -Status "Looking for available updates" -State "Indeterminate"
    $upgradable = Get-WinUtilUpgradablePackage

    if (@($upgradable).Count -eq 0) {
        Write-WinUtilLog -Component "Install" -Message "No packages have an update available."
        Step-WinUtilJob -Status "Everything is up to date" -Percent 100
        return
    }

    Write-WinUtilLog -Component "Install" -Message "Upgrading $(@($upgradable).Count) package(s): $($upgradable -join ', ')"

    $total = @($upgradable).Count
    $completed = 0
    $results = @()

    foreach ($package in $upgradable) {
        $position = $completed + 1
        Step-WinUtilJob -Status "Upgrading $package ($position/$total)" -Percent ([int](($completed / $total) * 100))

        $results += Measure-WinUtilStep -Scope "Install" -Name "winget upgrade $package" -ScriptBlock {
            Install-WinUtilProgramWinget -Action Upgrade -Programs @($package)
        }

        $completed++
        Step-WinUtilJob -Status "Upgraded $package ($completed/$total)" -Percent ([int](($completed / $total) * 100))
    }

    Complete-WinUtilPackageRun -Action "Upgrade" -Results $results
}

function Get-WinUtilUpgradablePackage {
    <#
    .SYNOPSIS
        Returns the package identifiers WinGet reports as having an update available
    #>

    # The command line prints a table, and its own header and separator rows are not packages
    $output = & winget upgrade --include-unknown --accept-source-agreements 2>&1 | Out-String
    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($output -split "`r?`n")) {
        if ($line -match '^\s*\S.*?\s{2,}(?<id>[\w\.\-\+]+)\s{2,}\S+\s{2,}\S+') {
            $id = $Matches['id']
            if ($id -notin @("Id", "----")) {
                $ids.Add($id)
            }
        }
    }
    return @($ids)
}
