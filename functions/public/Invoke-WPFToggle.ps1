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

    $ToggleStatus = (Get-WinUtilToggleStatus $Button)

    Switch -Wildcard ($Button) {

        "WPFToggleDarkMode" {Invoke-WinUtilDarkMode $ToggleStatus}
        "WPFToggleBingSearch" {Invoke-WinUtilBingSearch $ToggleStatus}
        "WPFToggleNumLock" {Invoke-WinUtilNumLock $ToggleStatus}
        "WPFToggleVerboseLogon" {Invoke-WinUtilVerboseLogon $ToggleStatus}
        "WPFToggleShowExt" {Invoke-WinUtilShowExt $ToggleStatus}
        "WPFToggleSnapWindow" {Invoke-WinUtilSnapWindow $ToggleStatus}
        "WPFToggleSnapFlyout" {Invoke-WinUtilSnapFlyout $ToggleStatus}
        "WPFToggleSnapSuggestion" {Invoke-WinUtilSnapSuggestion $ToggleStatus}
        "WPFToggleMouseAcceleration" {Invoke-WinUtilMouseAcceleration $ToggleStatus}
        "WPFToggleStickyKeys" {Invoke-WinUtilStickyKeys $ToggleStatus}
        "WPFToggleTaskbarWidgets" {Invoke-WinUtilTaskbarWidgets $ToggleStatus}
        "WPFToggleTaskbarSearch" {Invoke-WinUtilTaskbarSearch $ToggleStatus}
        "WPFToggleTaskView" {Invoke-WinUtilTaskView $ToggleStatus}
        "WPFToggleHiddenFiles" {Invoke-WinUtilHiddenFiles $ToggleStatus}
        "WPFToggleTaskbarAlignment" {Invoke-WinUtilTaskbarAlignment $ToggleStatus}
        "WPFToggleDetailedBSoD" {Invoke-WinUtilDetailedBSoD $ToggleStatus}
    }
}
