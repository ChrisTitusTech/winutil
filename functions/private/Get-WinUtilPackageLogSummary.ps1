function Get-WinUtilPackageLogSummary {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Packages,

        [Parameter(Mandatory = $true)]
        [string]$Preference
    )

    @(
        $Packages | ForEach-Object {
            $package = $_

            # applications.json normally uses "content"; Name and Description
            # remain fallback fields for legacy objects and tests.
            $packageName = @(
                $package.content,
                $package.Name,
                $package.Description,
                $package.winget,
                $package.choco,
                $package.repo,
                $package.npmPackage
            ) |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace([string]$_) -and
                    $_ -ne "na"
                } |
                Select-Object -First 1

            if ([string]::IsNullOrWhiteSpace([string]$packageName)) {
                $packageName = "Unknown package"
            }

            if ($package.installType -eq "github") {
                $repo = if (
                    -not [string]::IsNullOrWhiteSpace([string]$package.repo)
                ) {
                    $package.repo
                } else {
                    "unknown repository"
                }

                $assetPattern = if (
                    -not [string]::IsNullOrWhiteSpace([string]$package.assetPattern)
                ) {
                    $package.assetPattern
                } else {
                    "unknown asset"
                }

                "$packageName (GitHub: $repo, asset: $assetPattern)"
            }
            elseif ($package.installType -eq "npm") {
                $npmPackage = if (
                    -not [string]::IsNullOrWhiteSpace([string]$package.npmPackage)
                ) {
                    $package.npmPackage
                } else {
                    "unknown package"
                }

                "$packageName (npm: $npmPackage)"
            }
            elseif (
                $Preference -eq "Choco" -and
                -not [string]::IsNullOrWhiteSpace([string]$package.choco) -and
                $package.choco -ne "na"
            ) {
                "$packageName (choco: $($package.choco))"
            }
            elseif (
                -not [string]::IsNullOrWhiteSpace([string]$package.winget) -and
                $package.winget -ne "na"
            ) {
                "$packageName (winget: $($package.winget))"
            }
            else {
                "$packageName (no package id)"
            }
        }
    )
}
