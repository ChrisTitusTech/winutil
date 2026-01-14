# System Properties

```json
function Invoke-WPFControlPanel {
    <#

    .SYNOPSIS
        Opens the requested legacy panel

    .PARAMETER Panel
        The panel to open

    #>
    param($Panel)

    switch ($Panel) {
        "WPFPanelControl" {control}
        "WPFPanelComputer" {compmgmt.msc}
        "WPFPanelNetwork" {ncpa.cpl}
        "WPFPanelPower"   {powercfg.cpl}
        "WPFPanelPrinter" {Start-Process "shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}"}
        "WPFPanelRegion"  {intl.cpl}
        "WPFPanelRestore"  {rstrui.exe}
        "WPFPanelSound"   {mmsys.cpl}
        "WPFPanelSystem"  {sysdm.cpl}
        "WPFPanelTimedate" {timedate.cpl}
        "WPFPanelUser"    {control userpasswords2}
    }
}
```
