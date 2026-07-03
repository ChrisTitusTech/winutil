#===========================================================================
# Tests - Asset rendering
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Describe "Rendered asset caching" {
    It "caches rendered bitmap assets by type and size" {
        $assetScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilAssets.ps1") -Raw

        $assetScript | Should -Match 'RenderedAssetCache'
        $assetScript | Should -Match '\$cacheKey = "\$\(\(\[string\]\$type\)\.ToLowerInvariant\(\)\)\|\$Size"'
        $assetScript | Should -Match 'return \$sync\.RenderedAssetCache\[\$cacheKey\]'
        $assetScript | Should -Match '\$sync\.RenderedAssetCache\[\$cacheKey\] = \$bitmapImage'
    }

    It "renders only the logo overlay before first paint and defers status overlays" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        $mainScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$false'
        $mainScript | Should -Match 'Dispatcher\.BeginInvoke\(\[System\.Windows\.Threading\.DispatcherPriority\]::Background, \[action\]\{ Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$false -IncludeStatusAssets \$true \}'
        $mainScript | Should -Not -Match '\$sync\["checkmarkrender"\] = \(Invoke-WinUtilAssets -Type "checkmark"'
        $mainScript | Should -Not -Match '\$sync\["warningrender"\] = \(Invoke-WinUtilAssets -Type "warning"'
    }

    It "lazily creates taskbar overlays before assigning them" {
        $taskbarScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Set-WinUtilTaskbarItem.ps1") -Raw

        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$false'
        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$false -IncludeStatusAssets \$true'
    }

}
