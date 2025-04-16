function Set-PackageManagerPreference {
    <#
    .SYNOPSIS
        Sets the currently selected package manager to global "ManagerPreference" in sync.
        Also persists preference across Winutil restarts via preference.ini.

        Reads from preference.ini if no argument sent.

    .PARAMETER preferedPackageManager
        The PackageManager that was selected.
    #>
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [PackageManagers]$preferedPackageManager
    )

    $preferencePath = "$env:LOCALAPPDATA\winutil\preferences.ini"
    $oldChocoPath = "$env:LOCALAPPDATA\winutil\preferChocolatey.ini"

    #Try loading from file if no argument given.
    if ($null -eq $preferedPackageManager) {
        # Backwards compat for preferChocolatey.ini
        if (Test-Path -Path $oldChocoPath) {
            $preferedPackageManager = [PackageManagers]::Choco
            Remove-Item -Path $oldChocoPath
        }
        elseif (Test-Path -Path $preferencePath) {
            $potential = Get-Content -Path $preferencePath -TotalCount 1
            $preferedPackageManager = [PackageManagers]$potential
        }
        else {
            Write-Debug "Creating new preference file, defaulting to winget."
            $preferedPackageManager = [PackageManagers]::Winget
        }
    }

    $sync["ManagerPreference"] = [PackageManagers]::$preferedPackageManager
    Write-Debug "Manager Preference changed to '$($sync["ManagerPreference"])'"


    # Write preference to file to persist across restarts.
    Out-File -FilePath $preferencePath -InputObject $sync["ManagerPreference"]
}
