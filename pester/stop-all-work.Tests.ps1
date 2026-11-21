#===========================================================================
# Tests - Stop running and queued work with confirmation
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:source = Get-Content (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilCloseRequest.ps1") -Raw
}

Describe "Stop all work" {
    It "defines Stop-WinUtilAllWork reusing the close confirmation dialog" {
        $script:source | Should -Match 'function Stop-WinUtilAllWork'
        $script:source | Should -Match 'Show-WinUtilJobCloseMessage'
        $script:source | Should -Match 'Stop-WinUtilQueuedWork'
    }

    It "wires the cancel button in the install working panel" {
        $ui = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $ui | Should -Match 'WPFInstallWorkingCancel.*Stop-WinUtilAllWork'
        $tab = Get-Content (Join-Path $script:repoRoot "xaml\src\layout\tabs\WPFTab1.xaml") -Raw
        $tab | Should -Match 'Name="WPFInstallWorkingCancel"'
        $tab | Should -Match 's_cancel_operations'
    }

    It "has the cancel label in every locale" {
        $en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
        $en.PSObject.Properties['s_cancel_operations'].Value | Should -Not -BeNullOrEmpty
        foreach ($file in Get-ChildItem (Join-Path $script:repoRoot "config\locales") -Filter "*.json" -File) {
            $loc = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $loc.PSObject.Properties['s_cancel_operations'].Value | Should -Not -BeNullOrEmpty
        }
    }
}
