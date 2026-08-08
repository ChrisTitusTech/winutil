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
        Write-WinUtilJobProgress -Status "Preparing Chocolatey" -State "Indeterminate"
        Install-WinUtilChoco

        Write-WinUtilLog -Component "Install" -Message "Upgrading all Chocolatey packages."
        Write-WinUtilJobProgress -Status "Upgrading all Chocolatey packages" -State "Indeterminate"

        $result = Measure-WinUtilStep -Scope "Install" -Name "choco upgrade all" -ScriptBlock {
            Install-WinUtilProgramChoco -Action Install -Programs @("all")
        }
        Complete-WinUtilPackageRun -Action "Upgrade" -Results @($result)
        return
    }

    Write-WinUtilJobProgress -Status "Preparing WinGet" -State "Indeterminate"
    Install-WinUtilWinget

    Write-WinUtilJobProgress -Status "Looking for available updates" -State "Indeterminate"
    $upgradable = Get-WinUtilUpgradablePackage

    if (@($upgradable).Count -eq 0) {
        Write-WinUtilLog -Component "Install" -Message "No packages have an update available."
        Write-WinUtilJobProgress -Status "Everything is up to date" -Percent 100
        return
    }

    Write-WinUtilLog -Component "Install" -Message "Upgrading $(@($upgradable).Count) package(s): $($upgradable -join ', ')"

    $total = @($upgradable).Count
    $completed = 0
    $results = @()

    foreach ($package in $upgradable) {
        $position = $completed + 1
        $base = [int](($completed / $total) * 100)
        Write-WinUtilJobProgress -Status "Upgrading $package ($position/$total)" -Percent $base

        $results += Measure-WinUtilStep -Scope "Install" -Name "winget upgrade $package" -ScriptBlock {
            Install-WinUtilProgramWinget -Action Install -Programs @($package) `
                -ProgressBase $base -ProgressSpan ([int](100 / $total)) `
                -Label "$package ($position/$total)"
        }

        $completed++
        Write-WinUtilJobProgress -Status "Upgraded $package ($completed/$total)" -Percent ([int](($completed / $total) * 100))
    }

    Complete-WinUtilPackageRun -Action "Upgrade" -Results $results
}

function Get-WinUtilUpgradablePackage {
    <#
    .SYNOPSIS
        Returns the package identifiers WinGet reports as having an update available
    #>

    if (Install-WinUtilWinGetClient) {
        $packages = Invoke-WinUtilWinGetCommand -Command "Get-WinGetPackage" -Label "Checking for updates"
        return @($packages |
            Where-Object { $_.IsUpdateAvailable } |
            ForEach-Object { $_.Id } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

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
