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

    Switch -Wildcard ($Button){

        "WPFTab?BT" {Invoke-WPFTab $Button}
        "WPFFeatureInstall" {Invoke-WPFFeatureInstall}
        "WPFGetIso" {Invoke-WPFGetIso}
        "WPFMicrowin" {Invoke-WPFMicrowin}
        "WPFCloseButton" {Invoke-WPFCloseButton}
        "MicrowinScratchDirBT" {Invoke-ScratchDialog}
        "WPFTweak*" {Invoke-WinUtilTweaks $Button -undo $false -tabname $sync.configs.tweaks}
        "WPFPanel*" {Invoke-WinUtilTweaks $Button -undo $false -tabname $sync.configs.feature}
        "WPFFixes*" {Invoke-WinUtilTweaks $Button -undo $false -tabname $sync.configs.feature}
        "WPFUpdates*" {Invoke-WinUtilTweaks $Button -undo $false -tabname $sync.configs.updates}
        "*_Buttons_*" {Invoke-WinUtilTweaks $($Button -replace ".*_Buttons_","") -undo $false -tabname $sync.configs.tabs.$($Button -replace '_Buttons.*','').Buttons}
        }
}