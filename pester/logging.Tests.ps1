#===========================================================================
# Tests - WinUtil Logging

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
}

Describe "Write-WinUtilLog" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-logging-$([guid]::NewGuid())"
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        Remove-Variable -Name WinUtilLogPath -Scope Script -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name WinUtilLogPath -Scope Script -ErrorAction SilentlyContinue
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "writes to the active timestamped session log under logs" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            logPath = $logPath
        })

        Write-WinUtilLog -Component "Test" -Message "same session log"

        Test-Path -Path $logPath | Should -BeTrue
        Test-Path -Path (Join-Path $script:testRoot "winutil.log") | Should -BeFalse
        Get-Content -Path $logPath -Raw | Should -Match "\[INFO\] \[Test\] same session log"
    }

    It "writes entries produced concurrently by several threads" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            logPath = $logPath
        })

        $logFunction = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1") -Raw
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $initialSessionState.Variables.Add(
            (New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "sync", $script:sync, $null)
        )
        $pool = [runspacefactory]::CreateRunspacePool(1, 4, $initialSessionState, $Host)
        $pool.Open()

        try {
            $handles = foreach ($index in 1..12) {
                $shell = [powershell]::Create()
                $shell.RunspacePool = $pool
                [void]$shell.AddScript($logFunction)
                [void]$shell.AddScript("Write-WinUtilLog -Component 'Test' -Message 'entry $index'")
                [pscustomobject]@{ Shell = $shell; Handle = $shell.BeginInvoke() }
            }

            foreach ($item in $handles) {
                $item.Shell.EndInvoke($item.Handle)
                $item.Shell.Dispose()
            }
        } finally {
            $pool.Close()
            $pool.Dispose()
        }

        $content = Get-Content -Path $logPath
        foreach ($index in 1..12) {
            @($content | Where-Object { $_ -match "\[Test\] entry $index$" }).Count | Should -Be 1
        }
    }

    It "creates one fallback log under logs when only winutildir is available" {
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
        })

        Write-WinUtilLog -Component "Test" -Message "first fallback entry"
        Write-WinUtilLog -Component "Test" -Message "second fallback entry"

        $logFiles = @(Get-ChildItem -Path (Join-Path $script:testRoot "logs") -Filter "winutil_*.log")
        $logFiles.Count | Should -Be 1
        Test-Path -Path (Join-Path $script:testRoot "winutil.log") | Should -BeFalse

        $content = Get-Content -Path $logFiles[0].FullName -Raw
        $content | Should -Match "first fallback entry"
        $content | Should -Match "second fallback entry"
    }

    It "falls back to host output when the log file cannot be opened" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            logPath = $logPath
        })

        Mock Add-Content { throw [System.IO.IOException]::new("file is locked") } -ParameterFilter {
            $Path -eq $logPath -and $ErrorAction -eq "Stop"
        }
        Mock Write-Host { }
        Mock Write-Warning { }

        Write-WinUtilLog -Component "Test" -Message "locked file fallback"

        Should -Invoke -CommandName Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] locked file fallback"
        }
        Should -Invoke -CommandName Write-Warning -Times 0 -Exactly
    }

}

