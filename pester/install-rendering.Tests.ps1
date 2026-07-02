#===========================================================================
# Tests - Install tab rendering
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Describe "Install app rendering startup contract" {
    It "queues app entries after creating category containers" {
        $categoryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallCategoryAppList.ps1") -Raw

        $categoryScript | Should -Match '\$sync\.InstallAppRenderQueue = \[System\.Collections\.Queue\]::new\(\)'
        $categoryScript | Should -Match 'Start-WinUtilInstallAppRendering'
        $categoryScript | Should -Match 'Pre-group apps by category before creating WPF controls'
    }

    It "renders queued apps through a dispatcher timer when a form dispatcher exists" {
        $renderScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilInstallAppRendering.ps1") -Raw

        $renderScript | Should -Match 'System\.Windows\.Threading\.DispatcherTimer'
        $renderScript | Should -Match 'Initialize-InstallAppEntry'
        $renderScript | Should -Match 'Install app entries rendered'
    }

    It "keeps app-entry metadata lookup independent from the old caller scope" {
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $entryScript | Should -Match '\$app = \$sync\.configs\.applicationsHashtable\.\$appKey'
        $entryScript | Should -Not -Match '\$Apps\.\$appKey'
    }

    It "restores delayed app checkbox state from selected apps" {
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $entryScript | Should -Match '\$sync\.selectedApps -contains \$appKey'
        $entryScript | Should -Match '\$checkBox\.IsChecked = \$true'
    }
}
