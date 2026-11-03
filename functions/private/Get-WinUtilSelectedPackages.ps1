function Get-WinUtilSelectedPackages {

     param(
         [Parameter(Mandatory = $true)]
         [object] $PackageList,

         [Parameter(Mandatory = $true)]
         [string] $Preference,

         [ValidateSet("Install", "Uninstall")]
         [string] $Action = "Install"
     )

    # A single package has no meaningful percentage to show
    if ($PackageList.count -eq 1) {
        Step-WinUtilJob -State "Indeterminate"
    }

    $packagesWinget = [System.Collections.ArrayList]::new()
    $packagesChoco = [System.Collections.ArrayList]::new()
    $packages = @{
        Winget = $packagesWinget
        Choco = $packagesChoco
    }

    function Add-PackageId {
        param(
            [System.Collections.ArrayList]$Target,
            $PackageId
        )

        # A config field may hold several IDs separated by ";" (e.g. a dependency;the package).
        # Detection splits the same way, so install and detection agree on what gets installed.
        $ids = [string]$PackageId -split ";"
        if ($Action -eq "Uninstall") {
            # Detection identifies the last ID as the app; preceding IDs are dependencies.
            $ids = @($ids[-1])
        }
        foreach ($id in $ids) {
            $id = $id.Trim()
            if ([string]::IsNullOrWhiteSpace($id) -or $id -eq "na") {
                continue
            }

            if (-not $Target.Contains($id)) {
                $null = $Target.Add($id)
            }
        }
    }

    foreach ($package in $PackageList) {
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
