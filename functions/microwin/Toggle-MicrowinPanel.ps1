function Toggle-MicrowinPanel {
    <#
    .SYNOPSIS
    Toggles the visibility of the Microwin options and ISO panels in the GUI.
    .DESCRIPTION
    This function toggles the visibility of the Microwin options and ISO panels in the GUI.
    .PARAMETER MicrowinOptionsPanel
    The panel containing Microwin options.
    .PARAMETER MicrowinISOPanel
    The panel containing the Microwin ISO options.
    .EXAMPLE
    Toggle-MicrowinPanel 1
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet(1, 2)]
        [int]$PanelNumber
    )

    if ($PanelNumber -eq 1) {
        $sync.MicrowinISOPanel.Visibility = 'Visible'
        $sync.MicrowinOptionsPanel.Visibility = 'Collapsed'

    } elseif ($PanelNumber -eq 2) {
        $sync.MicrowinOptionsPanel.Visibility = 'Visible'
        $sync.MicrowinISOPanel.Visibility = 'Collapsed'
    }
}
