function Get-WinUtilMultiplaneOverlayState {
    $overlayPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
    $graphicsDriversPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

    $overlayTestMode = (Get-ItemProperty -Path $overlayPath -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
    $disableOverlays = (Get-ItemProperty -Path $graphicsDriversPath -Name "DisableOverlays" -ErrorAction SilentlyContinue).DisableOverlays
    $overlayTestMode = if ($null -eq $overlayTestMode) { 0 } else { [int]$overlayTestMode }
    $disableOverlays = if ($null -eq $disableOverlays) { 0 } else { [int]$disableOverlays }

    # Only these exact pairs are supported; other combinations are custom states that need user action.
    switch ("$overlayTestMode,$disableOverlays") {
        "0,0" { return "Enabled" }
        "5,0" { return "Disabled (Compatibility)" }
        "5,1" { return "Fully Disabled" }
        default {
            throw "Unexpected Multiplane Overlay registry state: OverlayTestMode=$overlayTestMode, DisableOverlays=$disableOverlays."
        }
    }
}
