function Invoke-WPFButton {

    <#

    .SYNOPSIS
        Invokes the function associated with the clicked button

    .PARAMETER Button
        The name of the button that was clicked

    #>

    Param ([string]$Button)

    # Use this to get the name of the button
    #[System.Windows.MessageBox]::Show("$Button","Chris Titus Tech's Windows Utility","OK","Info")
    if (-not $sync.ProcessRunning) {
        Set-WinUtilProgressBar  -label "" -percent 0 -hide $true
    }

    Switch -Wildcard ($Button) {
        "WPFTab?BT" {Invoke-WPFTab $Button}
        "WPFInstall" {Invoke-WPFInstall}
        "WPFUninstall" {Invoke-WPFUnInstall}
        "WPFInstallUpgrade" {Invoke-WPFInstallUpgrade}
        "WPFStandard" {Invoke-WPFPresets "Standard" -checkboxfilterpattern "WPFTweak*"}
        "WPFMinimal" {Invoke-WPFPresets "Minimal" -checkboxfilterpattern "WPFTweak*"}
        "WPFClearTweaksSelection" {Invoke-WPFPresets -imported $true -checkboxfilterpattern "WPFTweak*"}
        "WPFClearInstallSelection" {Invoke-WPFPresets -imported $true -checkboxfilterpattern "WPFInstall*"}
        "WPFtweaksbutton" {Invoke-WPFtweaksbutton}
        "WPFOOSUbutton" {Invoke-WPFOOSU}
        "WPFAddUltPerf" {Invoke-WPFUltimatePerformance -State "Enable"}
        "WPFRemoveUltPerf" {Invoke-WPFUltimatePerformance -State "Disable"}
        "WPFundoall" {Invoke-WPFundoall}
        "WPFFeatureInstall" {Invoke-WPFFeatureInstall}
        "WPFPanelDISM" {Invoke-WPFPanelDISM}
        "WPFPanelAutologin" {Invoke-WPFPanelAutologin}
        "WPFPanelcontrol" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelnetwork" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelpower" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelregion" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelsound" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelprinter" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelsystem" {Invoke-WPFControlPanel -Panel $button}
        "WPFPaneluser" {Invoke-WPFControlPanel -Panel $button}
        "WPFUpdatesdefault" {Invoke-WPFUpdatesdefault}
        "WPFFixesUpdate" {Invoke-WPFFixesUpdate}
        "WPFFixesWinget" {Invoke-WPFFixesWinget}
        "WPFRunAdobeCCCleanerTool" {Invoke-WPFRunAdobeCCCleanerTool}
        "WPFFixesNetwork" {Invoke-WPFFixesNetwork}
        "WPFUpdatesdisable" {Invoke-WPFUpdatesdisable}
        "WPFUpdatessecurity" {Invoke-WPFUpdatessecurity}
        "WPFWinUtilShortcut" {Invoke-WPFShortcut -ShortcutToAdd "WinUtil" -RunAsAdmin $true}
        "WPFGetInstalled" {Invoke-WPFGetInstalled -CheckBox "winget"}
        "WPFGetInstalledTweaks" {Invoke-WPFGetInstalled -CheckBox "tweaks"}
        "WPFGetIso" {Invoke-WPFGetIso}
        "WPFMicrowin" {Invoke-WPFMicrowin}
        "WPFCloseButton" {Invoke-WPFCloseButton}
        "MicrowinScratchDirBT" {Invoke-ScratchDialog}
        "WPFWinUtilPSProfile" {Invoke-WinUtilpsProfile}
        "WPFWinUtilSSHServer" {Invoke-WinUtilSSHServer}
    }
}
