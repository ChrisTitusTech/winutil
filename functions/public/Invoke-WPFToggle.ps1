function Invoke-WPFToggle {

    <#

    .SYNOPSIS
        Invokes the scriptblock for the given toggle

    .PARAMETER Button
        The name of the toggle to invoke

    #>

    Param ([string]$Button)

    # Use this to get the name of the button
    #[System.Windows.MessageBox]::Show("$Button","Chris Titus Tech's Windows Utility","OK","Info")

    Switch -Wildcard ($Button){

        "WPFToggleDarkMode" {Invoke-WinUtilDarkMode -DarkMoveEnabled $(Get-WinUtilToggleStatus WPFToggleDarkMode)}
        "WPFToggleBingSearch" {Invoke-WinUtilBingSearch $(Get-WinUtilToggleStatus WPFToggleBingSearch)}

    }
}