function Set-WinUtilWorkingView {
    <#
        .SYNOPSIS
            Shows or hides a tab working view (spinner + live status)

        .DESCRIPTION
            While a long run is in flight the tab content is replaced with the
            centered spinning arrow and the current status beneath it, mirroring
            the Win11 Creator working page. The bottom progress bar keeps
            reporting as before.

            Areas map job names to tabs: Install covers Install/Uninstall/
            Upgrade, Tweaks covers Tweaks/Undo. Adding a new area is a new
            XAML panel plus one entry in the map below.

            A no-op without a window, so job bodies stay free of UI checks.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Install", "Tweaks")]
        [string]$Area,

        [Parameter(Mandatory)]
        [bool]$Working,

        [string]$Label
    )

    Invoke-WPFUIThread -Parameters @{ Area = $Area; Working = $Working; Label = $Label } -ScriptBlock {
        param($Area, $Working, $Label)

        # Resolved here rather than by the caller: the block is rebuilt from its
        # text on the interface thread, so only flat values travel reliably.
        if ([string]::IsNullOrEmpty($Area)) { return }
        $controls = @{
            Install = @{
                Panel   = "WPFInstallWorkingPanel"
                Content = @("WPFInstallContentGrid", "WPFSearchChips")
                Label   = "WPFInstallWorkingLabel"
            }
            Tweaks  = @{
                Panel   = "WPFTweaksWorkingPanel"
                Content = @("WPFTweaksContentScroll", "WPFTweaksActionBar")
                Label   = "WPFTweaksWorkingLabel"
            }
        }[$Area]
        if ($null -eq $controls) { return }

        $panel = $sync[$controls.Panel]
        if ($null -eq $panel) { return }

        if ($Working) {
            $labelControl = $sync[$controls.Label]
            if ($Label -and $null -ne $labelControl) { $labelControl.Text = $Label }

            foreach ($name in $controls.Content) {
                $content = $sync[$name]
                if ($null -ne $content) { $content.Visibility = "Collapsed" }
            }

            $panel.Visibility = "Visible"
        } else {
            $panel.Visibility = "Collapsed"

            foreach ($name in $controls.Content) {
                $content = $sync[$name]
                if ($null -ne $content) { $content.Visibility = "Visible" }
            }
        }
    }
}
