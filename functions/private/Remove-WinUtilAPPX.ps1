function Get-WinUtilProvisionedPackages {
    if (-not $sync.AppxProvisionedCache) {
        $sync.AppxProvisionedCache = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)
    }
    return $sync.AppxProvisionedCache
}

function Remove-WinUtilAPPX {
    <#

    .SYNOPSIS
        Removes all APPX packages that match the given name

    .PARAMETER Name
        The name of the APPX package to remove

    .EXAMPLE
        Remove-WinUtilAPPX -Name "Microsoft.Microsoft3DViewer"

    #>
    param (
        $Name
    )

    $appxPackages = @(Get-AppxPackage $Name -AllUsers -ErrorAction SilentlyContinue)
    $provisionedPackages = @(Get-WinUtilProvisionedPackages | Where-Object DisplayName -like $Name)

    if ($appxPackages.Count -eq 0 -and $provisionedPackages.Count -eq 0) {
        Write-Host "Skip $Name - no Appx packages found."
        return
    }

    Write-Host "Removing $Name"

    $removedAny = $false

    foreach ($package in $appxPackages) {
        try {
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
            $removedAny = $true
        } catch {
            Write-Warning "Failed to remove Appx package '$($package.PackageFullName)': $($_.Exception.Message)"
        }
    }

    foreach ($package in $provisionedPackages) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
            $removedAny = $true
        } catch {
            Write-Warning "Failed to remove provisioned Appx package '$($package.PackageName)': $($_.Exception.Message)"
        }
    }

    if ($removedAny) {
        $sync.AppxProvisionedCache = $null
    }
}
