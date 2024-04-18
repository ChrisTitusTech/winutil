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
        "WPFToggleNumLock" {Invoke-WinUtilNumLock $(Get-WinUtilToggleStatus WPFToggleNumLock)}
        "WPFToggleVerboseLogon" {Invoke-WinUtilVerboseLogon $(Get-WinUtilToggleStatus WPFToggleVerboseLogon)}
        "WPFToggleShowExt" {Invoke-WinUtilShowExt $(Get-WinUtilToggleStatus WPFToggleShowExt)}
        "WPFToggleSnapFlyout" {Invoke-WinUtilSnapFlyout $(Get-WinUtilToggleStatus WPFToggleSnapFlyout)}
        "WPFToggleMouseAcceleration" {Invoke-WinUtilMouseAcceleration $(Get-WinUtilToggleStatus WPFToggleMouseAcceleration)}
        "WPFToggleStickyKeys" {Invoke-WinUtilStickyKeys $(Get-WinUtilToggleStatus WPFToggleStickyKeys)}
        "WPFToggleTaskbarWidgets" {Invoke-WinUtilTaskbarWidgets $(Get-WinUtilToggleStatus WPFToggleTaskbarWidgets)}
    }
}
