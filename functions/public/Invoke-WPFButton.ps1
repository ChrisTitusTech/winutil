function Invoke-WPFButton {

    <#
    
        .DESCRIPTION
        Meant to make creating buttons easier. There is a section below in the gui that will assign this function to every button.
        This way you can dictate what each button does from this function. 
    
        Input will be the name of the button that is clicked. 
    #>
    
    Param ([string]$Button) 

    #Use this to get the name of the button
    #[System.Windows.MessageBox]::Show("$Button","Chris Titus Tech's Windows Utility","OK","Info")

    Switch -Wildcard ($Button){

        "WPFTab?BT" {Invoke-WPFTab $Button}
        "WPFinstall" {Invoke-WPFInstall}
        "WPFInstallUpgrade" {Invoke-WPFInstallUpgrade}
        "WPFdesktop" {Invoke-WPFPresets "Desktop"}
        "WPFlaptop" {Invoke-WPFPresets "laptop"}
        "WPFminimal" {Invoke-WPFPresets "minimal"}
        "WPFexport" {Invoke-WPFImpex -type "export"}
        "WPFimport" {Invoke-WPFImpex -type "import"}
        "WPFclear" {Invoke-WPFPresets -preset $null -imported $true}
        "WPFtweaksbutton" {Invoke-WPFtweaksbutton}
        "WPFAddUltPerf" {Invoke-WPFUltimatePerformance -State "Enabled"}
        "WPFRemoveUltPerf" {Invoke-WPFUltimatePerformance -State "Disabled"}
        "WPFToggleDarkMode" {Invoke-WPFDarkMode -DarkMoveEnabled $(Get-WinUtilDarkMode)}
        "WPFundoall" {Invoke-WPFundoall}
        "WPFFeatureInstall" {Invoke-WPFFeatureInstall}
        "WPFPanelDISM" {Invoke-WPFPanelDISM}
        "WPFPanelAutologin" {Invoke-WPFPanelAutologin}
        "WPFPanelcontrol" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelnetwork" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelpower" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelsound" {Invoke-WPFControlPanel -Panel $button}
        "WPFPanelsystem" {Invoke-WPFControlPanel -Panel $button}
        "WPFPaneluser" {Invoke-WPFControlPanel -Panel $button}
        "WPFUpdatesdefault" {Invoke-WPFUpdatesdefault}
        "WPFFixesUpdate" {Invoke-WPFFixesUpdate}
        "WPFUpdatesdisable" {Invoke-WPFUpdatesdisable}
        "WPFUpdatessecurity" {Invoke-WPFUpdatessecurity}


    }
}