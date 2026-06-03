function Set-Preferences {

    if ($null -eq $sync.preferences.theme) {
        $sync.preferences.theme = "Auto"
    }

    if ($null -eq $sync.preferences.packagemanager) {
        $sync.preferences.packagemanager = "Winget"
    }

    if ($sync.preferences.packagemanager -eq "Choco") {
        $sync.preferences.packagemanager = [PackageManagers]::Choco
    }
    elseif ($sync.preferences.packagemanager -eq "Winget") {
        $sync.preferences.packagemanager = [PackageManagers]::Winget
    }
}