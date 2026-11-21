#===========================================================================
# Tests - XAML source fragments and automatic assembly
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:srcRoot = Join-Path $script:repoRoot "xaml\src"
    $script:buildScript = Join-Path $script:repoRoot "xaml\build-xaml.ps1"
}

Describe "XAML fragments" {
    It "keeps inputXML.xaml as an auto-generated assembly output" {
        $build = Get-Content -LiteralPath $script:buildScript -Raw
        $build | Should -Match 'inputXML\.xaml'
        $build | Should -Match 'manifest\.txt'
        $compile = Get-Content -LiteralPath (Join-Path $script:repoRoot "Compile.ps1") -Raw
        $compile | Should -Match 'build-xaml\.ps1'
    }

    It "has fragment files with descriptive names in folders, none starting with a digit" {
        $files = @(Get-ChildItem -Path $script:srcRoot -Recurse -File -Filter "*.xaml")
        $files.Count | Should -BeGreaterThan 30
        foreach ($file in $files) {
            $file.BaseName | Should -Not -Match '^\d'
            $relative = $file.FullName.Substring($script:srcRoot.Length + 1)
            $relative | Should -Match '\\'
        }
    }

    It "references every resource and tab fragment in a manifest" {
        foreach ($manifestPath in @("resources\manifest.txt", "layout\tabs\manifest.txt")) {
            $full = Join-Path $script:srcRoot $manifestPath
            Test-Path -LiteralPath $full | Should -BeTrue
            $base = Split-Path -Parent $full
            foreach ($rel in @(Get-Content -LiteralPath $full | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
                Test-Path -LiteralPath (Join-Path $base $rel) | Should -BeTrue
            }
        }
    }

    It "rebuilds a well-formed window with all named controls" {
        $originalHash = (Get-FileHash -LiteralPath (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Algorithm SHA256).Hash
        & $script:buildScript | Out-Null
        $newHash = (Get-FileHash -LiteralPath (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Algorithm SHA256).Hash
        $newHash | Should -Be $originalHash

        Add-Type -AssemblyName PresentationFramework
        [xml]$xaml = Get-Content -LiteralPath (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader($xaml)))
        foreach ($name in @("WPFMainGrid", "WPFTabNav", "WPFGuidePanel", "WPFModeSelectionOverlay", "SettingsButton")) {
            $window.FindName($name) | Should -Not -BeNull
        }
    }
}
