function Invoke-WPFControlPanel {
<#
.SYNOPSIS
    Launches legacy Windows Control Panel Views.
.DESCRIPTION
    Simple Switch for legacy Windows.
    To easier access the Control Panels.
.PARAMETER Panel
    Used to decide which WPFPanel should get opened.
#>
    param(
        [ValidateSet("WPFPanelcontrol", "WPFPanelnetwork", "WPFPanelpower", "WPFPanelsound", "WPFPanelsystem", "WPFPaneluser")]
        [string]$Panel
    )

    switch ($Panel){
        "WPFPanelcontrol" { control.exe }
        "WPFPanelnetwork" { ncpa.cpl }
        "WPFPanelpower"   { powercfg.cpl }
        "WPFPanelsound"   { mmsys.cpl }
        "WPFPanelsystem"  { sysdm.cpl }
        "WPFPaneluser"    { control.exe "userpasswords2" }
    }
}