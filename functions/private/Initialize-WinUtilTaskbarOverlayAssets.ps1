function Initialize-WinUtilTaskbarOverlayAssets {
    param(
        [bool]$IncludeLogo = $true,
        [bool]$IncludeStatusAssets = $true
    )

    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($null -eq $sync.AssetRenderLock) {
            $sync.AssetRenderLock = [object]::new()
        }
        $assetRenderLock = $sync.AssetRenderLock
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    [System.Threading.Monitor]::Enter($assetRenderLock)
    try {
        if ($IncludeLogo -and -not $sync["logorender"]) {
            $sync["logorender"] = (Invoke-WinUtilAssets -Type "Logo" -Size 90 -Render)
        }

        if ($IncludeStatusAssets -and -not $sync["checkmarkrender"]) {
            $sync["checkmarkrender"] = (Invoke-WinUtilAssets -Type "checkmark" -Size 512 -Render)
        }

        if ($IncludeStatusAssets -and -not $sync["warningrender"]) {
            $sync["warningrender"] = (Invoke-WinUtilAssets -Type "warning" -Size 512 -Render)
        }
    } finally {
        [System.Threading.Monitor]::Exit($assetRenderLock)
    }
}
