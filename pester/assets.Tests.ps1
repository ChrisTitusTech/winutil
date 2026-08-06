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

    It "renders no taskbar overlay before first paint" {
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $beforeFirstPaint = $uiScript.Substring(0, $uiScript.IndexOf('Add_ContentRendered'))

        # Rendering an overlay costs tens of milliseconds and nothing can see it until the
        # window is up, so it belongs behind first paint.
        $beforeFirstPaint | Should -Not -Match 'Initialize-WinUtilTaskbarOverlayAssets'
        $uiScript | Should -Match '(?s)DispatcherPriority\]::Background, \[action\]\{\s+Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$true\s+Set-WinUtilTaskbaritem -overlay "logo"'
        $uiScript | Should -Not -Match '\$sync\["checkmarkrender"\] = \(Invoke-WinUtilAssets -Type "checkmark"'
        $uiScript | Should -Not -Match '\$sync\["warningrender"\] = \(Invoke-WinUtilAssets -Type "warning"'
    }

    It "lazily creates taskbar overlays before assigning them" {
        $taskbarScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Set-WinUtilTaskbarItem.ps1") -Raw

        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$false'
        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$false -IncludeStatusAssets \$true'
    }

}
