#===========================================================================
# Tests - WinUtil Pro downloads its own release, not upstream's
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:startScript = Get-Content (Join-Path $script:repoRoot "scripts\start.ps1") -Raw
    $script:impexScript = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFImpex.ps1") -Raw
    $script:compileScript = Get-Content (Join-Path $script:repoRoot "Compile.ps1") -Raw
    $script:interfaceScript = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
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

Describe "Version stamping" {
    It "defaults the stamped version to the build date" {
        $script:compileScript | Should -Match ([regex]::Escape("[string]`$Version = (Get-Date -Format 'yy.MM.dd')"))
    }

    It "accepts only a release-tag shaped version" {
        $script:compileScript | Should -Match ([regex]::Escape("[ValidatePattern('^\d{2}\.\d{2}\.\d{2}(\.\d+)?`$')]"))
    }

    It "stamps the version parameter rather than the date directly" {
        $script:compileScript | Should -Match ([regex]::Escape("-replace '#{replaceme}', `$Version"))
        $script:compileScript | Should -Not -Match ([regex]::Escape("-replace '#{replaceme}', (Get-Date"))
    }

    It "lets a build outside CI be marked as published" {
        $script:compileScript | Should -Match ([regex]::Escape('[switch]$Release'))
        $script:compileScript | Should -Match ([regex]::Escape('$isLocalCompile = -not ($Release -or'))
    }
}

Describe "About dialog version link" {
    It "links a published build to the release it was stamped with" {
        $script:interfaceScript | Should -Match ([regex]::Escape('"https://github.com/6t9xstar/winutil-pro/releases/tag/$($sync.version)"'))
    }

    It "links a local build to the release list, having no tag of its own" {
        $script:interfaceScript | Should -Match 'if \(\$sync\.IsLocalCompile\)'
        $script:interfaceScript | Should -Match ([regex]::Escape('"https://github.com/6t9xstar/winutil-pro/releases"'))
    }

    It "shows the version through the chosen link" {
        $script:interfaceScript | Should -Match ([regex]::Escape('Version  : <a href="$versionLink">$($sync.version)</a>'))
    }
}
