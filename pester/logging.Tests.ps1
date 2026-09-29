#===========================================================================
# Tests - WinUtil Logging

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
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
        Remove-Variable -Name WinUtilIsJobWorker -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name WinUtilJobErrorCount -Scope Global -ErrorAction SilentlyContinue
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

    It "writes through the host when the transcript owns the active session log" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $logPath
            transcriptPath = $logPath
        })
        Mock Write-Host { }
        Mock Add-Content { }

        Write-WinUtilLog -Component "Test" -Message "transcript entry"

        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] transcript entry"
        }
        Should -Invoke Add-Content -Times 0 -Exactly
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

    It "counts only headline errors written by the active job worker" {
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        })
        $global:WinUtilIsJobWorker = $true
        $global:WinUtilJobErrorCount = 0

        Write-WinUtilLog -Level "ERROR" -Component "Test" -Message "job error"
        Write-WinUtilLog -Level "ERROR" -Detail -Component "Test" -Message "error detail"
        $global:WinUtilIsJobWorker = $false
        Write-WinUtilLog -Level "ERROR" -Component "UI" -Message "unrelated error"

        $global:WinUtilJobErrorCount | Should -Be 1
        $script:sync.LoggedErrors.Count | Should -Be 2
    }

    It "suppresses debug entries outside a local compile" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            IsLocalCompile = $false
            logPath = $logPath
        })

        Write-WinUtilLog -Level "DEBUG" -Component "UI" -Message "timing detail"

        Test-Path -Path $logPath | Should -BeFalse
    }

    It "writes debug entries from a local compile" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            IsLocalCompile = $true
            logPath = $logPath
        })

        Write-WinUtilLog -Level "DEBUG" -Component "UI" -Message "timing detail"

        Get-Content -Path $logPath -Raw | Should -Match "\[DEBUG\] \[UI\] timing detail"
    }

    It "does not record UI timing steps outside a local compile" {
        $script:sync = [hashtable]::Synchronized(@{
            IsLocalCompile = $false
            StepTimings = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        })
        Mock Write-WinUtilLog { }

        $result = Measure-WinUtilStep -Scope "UI" -Name "parse XAML" -ScriptBlock { 42 }

        $result | Should -Be 42
        $script:sync.StepTimings.Count | Should -Be 0
        Should -Invoke Write-WinUtilLog -Times 0 -Exactly
    }

    It "records local UI timing steps as debug entries" {
        $script:sync = [hashtable]::Synchronized(@{
            IsLocalCompile = $true
            StepTimings = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        })
        Mock Write-WinUtilLog { }

        Measure-WinUtilStep -Scope "UI" -Name "parse XAML" -ScriptBlock { } | Out-Null

        $script:sync.StepTimings.Count | Should -Be 1
        Should -Invoke Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "DEBUG" -and $Component -eq "UI" -and $Message -like "timing: parse XAML took*"
        }
    }

}
