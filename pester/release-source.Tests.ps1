#===========================================================================
# Tests - WinUtil Pro downloads its own release, not upstream's
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:startScript = Get-Content (Join-Path $script:repoRoot "scripts\start.ps1") -Raw
    $script:impexScript = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFImpex.ps1") -Raw
}

Describe "Release source" {
    It "relaunches elevated from the WinUtil Pro release when run from the web" {
        $script:startScript | Should -Match ([regex]::Escape("https://github.com/6t9xstar/winutil-pro/releases/latest/download/winutil.ps1"))
        $script:startScript | Should -Not -Match ([regex]::Escape("ChrisTitusTech/winutil/releases"))
    }

    It "copies an export command that runs WinUtil Pro" {
        $script:impexScript | Should -Match ([regex]::Escape("Invoke-RestMethod 'https://6t9xstar.github.io/win'"))
        $script:impexScript | Should -Not -Match ([regex]::Escape("christitus.com/win"))
    }
}
