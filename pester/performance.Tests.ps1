#===========================================================================
# Tests - Performance tracing
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilPerformanceTrace.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilPerformanceCheckpoint.ps1")
    . (Join-Path $script:repoRoot "functions\private\Start-WinUtilPerformanceTrace.ps1")
    . (Join-Path $script:repoRoot "functions\private\Stop-WinUtilPerformanceTrace.ps1")
}

Describe "WinUtil performance tracing helpers" {
    BeforeEach {
        $script:originalPerfEnv = $env:WINUTIL_PERF_LOG
        Remove-Item Env:\WINUTIL_PERF_LOG -ErrorAction SilentlyContinue
        $script:sync = [Hashtable]::Synchronized(@{})
    }

    AfterEach {
        if ($null -eq $script:originalPerfEnv) {
            Remove-Item Env:\WINUTIL_PERF_LOG -ErrorAction SilentlyContinue
        } else {
            $env:WINUTIL_PERF_LOG = $script:originalPerfEnv
        }

        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name originalPerfEnv -Scope Script -ErrorAction SilentlyContinue
    }

    It "is disabled by default" {
        Test-WinUtilPerformanceTrace | Should -BeFalse
    }

    It "can be enabled by environment variable" {
        $env:WINUTIL_PERF_LOG = "1"

        Test-WinUtilPerformanceTrace | Should -BeTrue
    }

    It "writes startup checkpoints through the normal WinUtil log helper" {
        $env:WINUTIL_PERF_LOG = "1"
        Mock Write-WinUtilLog { }

        Start-WinUtilPerformanceTrace
        Write-WinUtilPerformanceCheckpoint -Name "XAML loaded"
        Stop-WinUtilPerformanceTrace

        Should -Invoke -CommandName Write-WinUtilLog -Times 3 -Exactly -ParameterFilter {
            $Component -eq "StartupPerf" -and $Level -eq "DEBUG"
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -like "XAML loaded:*"
        }
    }
}

Describe "Startup performance checkpoints" {
    It "adds config-load checkpoints to compiled output" {
        $compileScript = Get-Content -Path (Join-Path $script:repoRoot "Compile.ps1") -Raw

        $compileScript | Should -Match "Start-WinUtilPerformanceTrace"
        $compileScript | Should -Match "Config load start"
        $compileScript | Should -Match "Config load complete"
        $compileScript | Should -Match "Config .* loaded"
    }

    It "adds runtime checkpoints for startup hotspots" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        foreach ($checkpoint in @(
            "Runspace pool initialized",
            "XAML loaded",
            "Theme applied",
            "Install UI created",
            "Tweaks UI created",
            "Features UI created",
            "AppX UI created",
            "Assets rendered",
            "First content rendered"
        )) {
            $mainScript | Should -Match ([regex]::Escape($checkpoint))
        }
    }
}
