function Get-OSDarkThemeState {
    <#
    .SYNOPSIS
    Checks if the dark theme is active in the Windows operating system.

    .DESCRIPTION
    This function queries the Windows registry to determine whether the dark theme is active.

    .EXAMPLE
    $darkThemeState = Get-OSDarkThemeState
    Write-Host "Dark Theme State: $darkThemeState"
    #>

    $app = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme
    $system = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').SystemUsesLightTheme

    if ($app -eq 0 -and $system -eq 0) {
        return $true
    } else {
        return $false
    }
}
