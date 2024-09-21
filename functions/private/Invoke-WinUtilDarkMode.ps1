Function Invoke-WinUtilDarkMode {
    <#

    .SYNOPSIS
        Enables/Disables Dark Mode

    .PARAMETER DarkMoveEnabled
        Indicates the current dark mode state

    #>
    Param($DarkMoveEnabled)
    try {
        if ($DarkMoveEnabled -eq $false) {
            Write-Host "Enabling Dark Mode"
            $DarkMoveValue = 0
        } else {
            Write-Host "Disabling Dark Mode"
            $DarkMoveValue = 1
        }

        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $DarkMoveValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $DarkMoveValue
        Invoke-WinUtilExplorerRefresh
        # Update Winutil Theme if the Theme Button shows the Icon for Auto
        if ($sync.ThemeButton.Content -eq [char]0xF08C) {
            Invoke-WinutilThemeChange -theme "Auto"
        }
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
