function Set-Preferences {
    if ($sync.preferences.packagemanager -eq "Choco") {
        $sync.preferences.packagemanager = [PackageManagers]::Choco
    } elseif ($sync.preferences.packagemanager -eq "Winget") {
        $sync.preferences.packagemanager = [PackageManagers]::Winget
    }
}
