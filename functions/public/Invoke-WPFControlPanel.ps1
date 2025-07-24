function Invoke-WPFControlPanel {
    <#

    .SYNOPSIS
        Opens the requested legacy panel

    .PARAMETER Panel
        The panel to open

    #>
    param($Panel)

    switch ($Panel) {
        "WPFPanelcontrol" {control}
        "WPFPanelcomputer" {compmgmt.msc}
        "WPFPanelnetwork" {ncpa.cpl}
        "WPFPanelpower"   {powercfg.cpl}
        "WPFPanelregion"  {intl.cpl}
        "WPFPanelsound"   {mmsys.cpl}
        "WPFPanelprinter" {Start-Process "shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}"}
        "WPFPanelsystem"  {sysdm.cpl}
        "WPFPaneluser"    {control userpasswords2}
        "WPFPanelGodMode" {Start-Process "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}"}
    }
}
