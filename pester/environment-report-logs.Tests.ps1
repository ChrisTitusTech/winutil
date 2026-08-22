#===========================================================================
# Tests - Environment report log bundling
#===========================================================================

BeforeAll {
    . (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "functions\private\Get-WinUtilRecentLogs.ps1")
}

Describe "Get-WinUtilRecentLogs" {
    BeforeEach {
        $script:logDir = Join-Path $TestDrive "logs"
        New-Item -Path $script:logDir -ItemType Directory -Force | Out-Null

        $recentPath = Join-Path $script:logDir "winutil_2026-08-20_10-00-00.log"
        "recent session log" | Out-File -FilePath $recentPath -Encoding utf8
        (Get-Item $recentPath).LastWriteTime = (Get-Date).AddDays(-1)

        $oldPath = Join-Path $script:logDir "winutil_2026-07-01_10-00-00.log"
        "old session log" | Out-File -FilePath $oldPath -Encoding utf8
        (Get-Item $oldPath).LastWriteTime = (Get-Date).AddDays(-30)

        $unrelatedPath = Join-Path $script:logDir "notes.txt"
        "unrelated file" | Out-File -FilePath $unrelatedPath -Encoding utf8
        (Get-Item $unrelatedPath).LastWriteTime = (Get-Date).AddDays(-1)
    }

    It "includes only winutil_*.log files within the day window" {
        $result = Get-WinUtilRecentLogs -Days 7 -LogDirectory $script:logDir

        $result | Should -Match "recent session log"
        $result | Should -Not -Match "old session log"
        $result | Should -Not -Match "unrelated file"
    }

    It "prefixes each included file with a header naming it" {
        $result = Get-WinUtilRecentLogs -Days 7 -LogDirectory $script:logDir

        $result | Should -Match "=== winutil_2026-08-20_10-00-00\.log ==="
    }

    It "returns an empty string when the log directory does not exist" {
        $result = Get-WinUtilRecentLogs -Days 7 -LogDirectory (Join-Path $TestDrive "missing")

        $result | Should -BeNullOrEmpty
    }
}
