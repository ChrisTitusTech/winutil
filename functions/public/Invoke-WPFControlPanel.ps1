function Invoke-WPFControlPanel {
        <#
    
        .DESCRIPTION
        Simple Switch for legacy windows
    
    #>
    param($Panel)

    switch ($Panel){
        "WPFPanelcontrol" {cmd /c control}
        "WPFPanelnetwork" {cmd /c ncpa.cpl}
        "WPFPanelpower"   {cmd /c powercfg.cpl}
        "WPFPanelregion"  {cmd /c intl.cpl}
        "WPFPanelsound"   {cmd /c mmsys.cpl}
        "WPFPanelsystem"  {cmd /c sysdm.cpl}
        "WPFPaneluser"    {cmd /c "control userpasswords2"}
    }
}