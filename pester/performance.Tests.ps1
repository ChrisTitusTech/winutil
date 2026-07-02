#===========================================================================
# Tests - Performance tracing
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
    . (Join-Path $script:repoRoot "tools\perf\Test-WinUtilPerformanceTrace.ps1")
    . (Join-Path $script:repoRoot "tools\perf\Write-WinUtilPerformanceCheckpoint.ps1")
    . (Join-Path $script:repoRoot "tools\perf\Start-WinUtilPerformanceTrace.ps1")
    . (Join-Path $script:repoRoot "tools\perf\Stop-WinUtilPerformanceTrace.ps1")
}

AfterAll {
    & (Join-Path $script:repoRoot "Compile.ps1")
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
    It "keeps performance tracing out of normal compiled output" {
        & (Join-Path $script:repoRoot "Compile.ps1")

        $compiledScript = Get-Content -Path (Join-Path $script:repoRoot "winutil.ps1") -Raw

        $compiledScript | Should -Not -Match "Test-WinUtilPerformanceTrace"
        $compiledScript | Should -Not -Match "Start-WinUtilPerformanceTrace"
        $compiledScript | Should -Not -Match "Write-WinUtilPerformanceCheckpoint"
        $compiledScript | Should -Not -Match "Stop-WinUtilPerformanceTrace"
        $compiledScript | Should -Not -Match "PerformanceTraceEnabled"
    }

    It "adds config-load checkpoints only to trace compiled output" {
        $compileScript = Get-Content -Path (Join-Path $script:repoRoot "Compile.ps1") -Raw

        $compileScript | Should -Match '\[switch\]\$Trace'
        $compileScript | Should -Match "Start-WinUtilPerformanceTrace"
        $compileScript | Should -Match "Config load start"
        $compileScript | Should -Match "Config load complete"
        $compileScript | Should -Match "Config .* loaded"

        & (Join-Path $script:repoRoot "Compile.ps1") -Trace
        $compiledScript = Get-Content -Path (Join-Path $script:repoRoot "winutil.ps1") -Raw

        $compiledScript | Should -Match "function Test-WinUtilPerformanceTrace"
        $compiledScript | Should -Match '\$sync\.PerformanceTraceEnabled = \$true'
        $compiledScript | Should -Match "Config load start"
        $compiledScript | Should -Match "Config load complete"
    }

    It "adds runtime checkpoints for startup hotspots" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $lazyTabScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTabContent.ps1") -Raw
        $runspaceScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRunspacePool.ps1") -Raw
        $overlayScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTaskbarOverlayAssets.ps1") -Raw
        $startupText = "$mainScript`n$lazyTabScript`n$runspaceScript`n$overlayScript"

        foreach ($checkpoint in @(
            "Runspace pool initialized",
            "XAML loaded",
            "Theme applied",
            "Install UI created",
            "Tweaks UI created",
            "Features UI created",
            "AppX UI created",
            "Taskbar logo asset rendered",
            "First content rendered"
        )) {
            $startupText | Should -Match ([regex]::Escape($checkpoint))
        }
    }
}
