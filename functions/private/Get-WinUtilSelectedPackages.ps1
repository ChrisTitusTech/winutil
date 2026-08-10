function Get-WinUtilSelectedPackages {

    param(
        [Parameter(Mandatory = $true)]
        [object] $PackageList,

        [Parameter(Mandatory = $true)]
        [string] $Preference
    )

    if ($PackageList.count -eq 1) {
        Invoke-WPFUIThread -ScriptBlock {
            Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo"
        }
    } else {
        Invoke-WPFUIThread -ScriptBlock {
            Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo"
        }
    }

    $packagesWinget = [System.Collections.ArrayList]::new()
    $packagesChoco = [System.Collections.ArrayList]::new()
    $packagesGithub = [System.Collections.ArrayList]::new()
    $packagesNpm = [System.Collections.ArrayList]::new()

    $packages = @{
        Winget = $packagesWinget
        Choco  = $packagesChoco
        Github = $packagesGithub
        Npm    = $packagesNpm
    }

    function Add-PackageId {
        param(
            [System.Collections.ArrayList]$Target,
            $PackageId
        )

        if ([string]::IsNullOrWhiteSpace([string]$PackageId) -or $PackageId -eq "na") {
            return
        }

        if (-not $Target.Contains($PackageId)) {
            $null = $Target.Add($PackageId)
        }
    }

    foreach ($package in $PackageList) {

        # GitHub installers need the entire object, not a Winget/Choco ID.
        if ($package.installType -eq "github") {
            $null = $packagesGithub.Add($package)
            continue
        }

        if ($package.installType -eq "npm") {
            $null = $packagesNpm.Add($package)
            continue
        }

        switch ($Preference) {
            "Choco" {
                if ([string]::IsNullOrWhiteSpace([string]$package.choco) -or $package.choco -eq "na") {
                    Add-PackageId -Target $packagesWinget -PackageId $package.winget
                } else {
                    Add-PackageId -Target $packagesChoco -PackageId $package.choco
                }
            }

            "Winget" {
                Add-PackageId -Target $packagesWinget -PackageId $package.winget
            }
        }
    }

    return $packages
}
