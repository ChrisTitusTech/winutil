function Initialize-RefreshApps {
    <#
        .SYNOPSIS
            Re-scans the system for installed apps and updates the UI
    #>
    Invoke-WPFGetInstalled -CheckBox "winget"
    if ($sync.preferences.packagemanager -eq "Choco") {
        Invoke-WPFGetInstalled -CheckBox "choco"
    }
}
