function Microwin-TestKitsRootPaths {
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string]$adkKitsRootPath,
        [Parameter(Mandatory = $true, Position = 1)] [string]$adkKitsRootPath_WOW64Environ
    )

    if (Test-Path "$adkKitsRootPath") { return $true }
    if (Test-Path "$adkKitsRootPath_WOW64Environ") { return $true }

    return $false
}
