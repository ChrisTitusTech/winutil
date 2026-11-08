#===========================================================================
# Tests - Elevation bootstrap fails closed without a script path
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:startSource = Get-Content -Path (Join-Path $script:repoRoot "scripts\start.ps1") -Raw
}

Describe "New-WinUtilElevationCommand bootstrap" {
    It "no longer downloads and executes the floating latest release" {
        $script:startSource | Should -Not -Match 'releases/latest/download'
    }

    It "fails closed with guidance when launched from memory" {
        $script:startSource | Should -Match 'cannot relaunch itself elevated safely'
    }
}
