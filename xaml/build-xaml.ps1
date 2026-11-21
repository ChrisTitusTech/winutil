<#
    Rebuilds xaml/inputXML.xaml from the fragments under xaml/src.

    The fragment layout (no numeric prefixes, grouped by folder):
      src/layout/Header.xaml         - <Window ...> and <WindowChrome>
      src/layout/MainGridOpen.xaml   - main <Grid> open and row definitions
      src/resources/manifest.txt     - ordered list of resource fragments
      src/layout/TitleBar.xaml       - title bar, nav dock, search
      src/layout/tabs/manifest.txt   - ordered list of tab fragments (includes closing </TabControl>)
      src/layout/Wizard.xaml         - WPFGuidePanel
      src/layout/ModeChooser.xaml    - WPFModeSelectionOverlay
      src/layout/Footer.xaml         - closing </Grid> and </Window>

    Run this before Compile.ps1 (Compile.ps1 also calls it).
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $PSScriptRoot 'src'
$out = Join-Path $PSScriptRoot 'inputXML.xaml'

function Read-Fragment([string]$rel) {
    $path = Join-Path $src $rel
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing XAML fragment: $rel" }
    return [IO.File]::ReadAllText($path)
}

$sb = [System.Text.StringBuilder]::new()

# Header (Window open + WindowChrome), then Window.Resources wrapper + resource fragments.
[void]$sb.Append((Read-Fragment 'layout/Header.xaml'))
[void]$sb.Append("`r`n    <Window.Resources>`r`n")
foreach ($rel in [IO.File]::ReadAllLines((Join-Path $src 'resources\manifest.txt'))) {
    if ([string]::IsNullOrWhiteSpace($rel)) { continue }
    [void]$sb.Append((Read-Fragment ('resources/' + $rel)))
}
[void]$sb.Append("    </Window.Resources>`r`n")

# Main grid, title bar, tabs, wizard, mode chooser, footer.
[void]$sb.Append((Read-Fragment 'layout/MainGridOpen.xaml'))
[void]$sb.Append((Read-Fragment 'layout/TitleBar.xaml'))
[void]$sb.Append((Read-Fragment 'layout/Tabs.xaml'))
foreach ($rel in [IO.File]::ReadAllLines((Join-Path $src 'layout\tabs\manifest.txt'))) {
    if ([string]::IsNullOrWhiteSpace($rel)) { continue }
    [void]$sb.Append((Read-Fragment ('layout/tabs/' + $rel)))
}
[void]$sb.Append((Read-Fragment 'layout/Wizard.xaml'))
[void]$sb.Append((Read-Fragment 'layout/ModeChooser.xaml'))
[void]$sb.Append((Read-Fragment 'layout/Footer.xaml'))

[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# Validate that the result is well-formed XML.
[void][xml](Get-Content -LiteralPath $out -Raw)
Write-Output "Rebuilt $out ($( $sb.Length ) chars)"
