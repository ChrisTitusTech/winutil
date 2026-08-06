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

    It "renders the taskbar overlays away from the interface thread" {
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $assetScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilAssetRendering.ps1") -Raw

        # The interface thread never rasterises an overlay; the main thread does it while
        # waiting for the window, and Set-WinUtilTaskbaritem covers the case where the render
        # has not landed yet.
        $uiScript | Should -Not -Match 'Initialize-WinUtilTaskbarOverlayAssets'
        $mainScript | Should -Match '(?s)\$uiHandle = \$uiShell\.BeginInvoke\(\).*Start-WinUtilAssetRendering.*\$uiHandle\.AsyncWaitHandle\.WaitOne\(\)'
        $assetScript | Should -Match '\$runspace\.ApartmentState = "STA"'
        $assetScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$true'
    }

    It "lazily creates taskbar overlays before assigning them" {
        $taskbarScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Set-WinUtilTaskbarItem.ps1") -Raw

        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$true -IncludeStatusAssets \$false'
        $taskbarScript | Should -Match 'Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo \$false -IncludeStatusAssets \$true'
    }

}
