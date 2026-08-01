function Set-WinUtilMultiplaneOverlay {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Enabled", "Disabled (Compatibility)", "Fully Disabled")]
        [string]$State
    )

    $values = switch ($State) {
        "Enabled" {
            # Zero is Windows' default for both values, leaving MPO enabled.
            @{ OverlayTestMode = 0; DisableOverlays = 0 }
        }
        "Disabled (Compatibility)" {
            # OverlayTestMode=5 is the less aggressive MPO workaround used by older WinUtil versions.
            @{ OverlayTestMode = 5; DisableOverlays = 0 }
        }
        "Fully Disabled" {
            # DisableOverlays=1 adds the more aggressive driver-level overlay disable.
            @{ OverlayTestMode = 5; DisableOverlays = 1 }
        }
    }

    $overlayPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
    $graphicsDriversPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    $previousOverlayTestMode = (Get-ItemProperty -Path $overlayPath -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
    $previousDisableOverlays = (Get-ItemProperty -Path $graphicsDriversPath -Name "DisableOverlays" -ErrorAction SilentlyContinue).DisableOverlays
    $overlayTestModeExisted = $null -ne $previousOverlayTestMode
    $disableOverlaysExisted = $null -ne $previousDisableOverlays

    try {
        Set-WinUtilRegistry -Name "OverlayTestMode" -Path $overlayPath -Type "DWord" -Value $values.OverlayTestMode
        Set-WinUtilRegistry -Name "DisableOverlays" -Path $graphicsDriversPath -Type "DWord" -Value $values.DisableOverlays

        $actualOverlayTestMode = (Get-ItemProperty -Path $overlayPath -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
        $actualDisableOverlays = (Get-ItemProperty -Path $graphicsDriversPath -Name "DisableOverlays" -ErrorAction SilentlyContinue).DisableOverlays
        if ([int]$actualOverlayTestMode -ne $values.OverlayTestMode -or [int]$actualDisableOverlays -ne $values.DisableOverlays) {
            throw "The registry values did not match the requested state."
        }
    } catch {
        $applyError = $_.Exception.Message
        $overlayRollbackValue = if ($overlayTestModeExisted) { [int]$previousOverlayTestMode } else { "<RemoveEntry>" }
        $disableOverlaysRollbackValue = if ($disableOverlaysExisted) { [int]$previousDisableOverlays } else { "<RemoveEntry>" }

        Set-WinUtilRegistry -Name "OverlayTestMode" -Path $overlayPath -Type "DWord" -Value $overlayRollbackValue
        Set-WinUtilRegistry -Name "DisableOverlays" -Path $graphicsDriversPath -Type "DWord" -Value $disableOverlaysRollbackValue

        $restoredOverlayTestMode = (Get-ItemProperty -Path $overlayPath -Name "OverlayTestMode" -ErrorAction SilentlyContinue).OverlayTestMode
        $restoredDisableOverlays = (Get-ItemProperty -Path $graphicsDriversPath -Name "DisableOverlays" -ErrorAction SilentlyContinue).DisableOverlays
        $overlayRestored = if ($overlayTestModeExisted) { [int]$restoredOverlayTestMode -eq [int]$previousOverlayTestMode } else { $null -eq $restoredOverlayTestMode }
        $disableOverlaysRestored = if ($disableOverlaysExisted) { [int]$restoredDisableOverlays -eq [int]$previousDisableOverlays } else { $null -eq $restoredDisableOverlays }

        if (-not $overlayRestored -or -not $disableOverlaysRestored) {
            throw "Unable to apply Multiplane Overlay state '$State': $applyError Rollback also failed."
        }

        throw "Unable to apply Multiplane Overlay state '$State': $applyError"
    }
}
