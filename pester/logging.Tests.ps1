#===========================================================================
# Tests - WinUtil Logging

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilErrorRecord.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilJobBanner.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilConsoleProgress.ps1")
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
}

Describe "Write-WinUtilLog" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-logging-$([guid]::NewGuid())"
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        Remove-Variable -Name WinUtilLogState -Scope Script -ErrorAction SilentlyContinue
    }

    AfterEach {
        Close-WinUtilLog
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name WinUtilLogState -Scope Script -ErrorAction SilentlyContinue
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

    It "records entries from a runspace that shares the console host" {
        # Like the UI thread, which a transcript on the main thread never recorded
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $logPath
        })

        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $initialSessionState.Variables.Add(
            (New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "sync", $script:sync, $null)
        )
        $runspace = [runspacefactory]::CreateRunspace($Host, $initialSessionState)
        $runspace.ApartmentState = "STA"
        $runspace.Open()
        $shell = [powershell]::Create()
        $shell.Runspace = $runspace

        try {
            [void]$shell.AddScript((Get-Content -Path (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1") -Raw))
            [void]$shell.AddScript("Write-WinUtilLog -Component 'UI' -Message 'from the interface thread'")
            $shell.Invoke()
        } finally {
            $shell.Dispose()
            $runspace.Dispose()
        }

        Write-WinUtilLog -Component "Test" -Message "from the main thread"

        $content = Get-Content -Path $logPath
        @($content | Where-Object { $_ -match "\[UI\] from the interface thread$" }).Count | Should -Be 1
        @($content | Where-Object { $_ -match "\[Test\] from the main thread$" }).Count | Should -Be 1
    }

    It "keeps the session log readable while it is open" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $logPath
        })

        Write-WinUtilLog -Component "Test" -Message "first entry"
        Get-Content -LiteralPath $logPath -Raw | Should -Match "first entry"

        Write-WinUtilLog -Component "Test" -Message "second entry"
        Get-Content -LiteralPath $logPath -Raw | Should -Match "second entry"
    }

    It "releases the file when closed and appends to it if a later entry arrives" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $logPath
        })

        Write-WinUtilLog -Component "Test" -Message "before close"
        Close-WinUtilLog

        $exclusive = [System.IO.File]::Open($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $exclusive.Dispose()

        Write-WinUtilLog -Component "Test" -Message "after close"

        $content = Get-Content -Path $logPath -Raw
        $content | Should -Match "before close"
        $content | Should -Match "after close"
    }

    It "shows the entry on the console without emitting a Write-Host record" {
        $script:sync = [hashtable]::Synchronized(@{
            logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        })
        Mock Write-WinUtilHost { }

        # A Write-Host record here would get logged twice inside a job
        $records = @(& { Write-WinUtilLog -Component "Test" -Message "console entry" } 6>&1)

        $records.Count | Should -Be 0
        Should -Invoke Write-WinUtilHost -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] console entry"
        }
    }

    It "writes only the file when the entry is already on the console" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $logPath
        })
        Mock Write-WinUtilHost { }

        Write-WinUtilLog -Component "Test" -Message "collected output" -FileOnly

        Should -Invoke Write-WinUtilHost -Times 0 -Exactly
        Get-Content -Path $logPath -Raw | Should -Match "\[INFO\] \[Test\] collected output"
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

    It "still shows the entry when the log file cannot be opened" {
        $logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            logPath = $logPath
        })
        New-Item -Path (Split-Path -Path $logPath -Parent) -ItemType Directory -Force | Out-Null
        $locked = [System.IO.File]::Open($logPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

        Mock Write-WinUtilHost { }
        Mock Write-Warning { }

        try {
            Write-WinUtilLog -Component "Test" -Message "locked file fallback"
        } finally {
            $locked.Dispose()
        }

        Should -Invoke -CommandName Write-WinUtilHost -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] locked file fallback"
        }
        Should -Invoke -CommandName Write-Warning -Times 0 -Exactly
    }

    It "counts headline errors in the logging runspace whether or not it is a job worker" {
        $script:sync = [hashtable]::Synchronized(@{
            winutildir = $script:testRoot
            LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        })
        $global:WinUtilIsJobWorker = $true
        $global:WinUtilJobErrorCount = 0

        Write-WinUtilLog -Level "ERROR" -Component "Test" -Message "job error"
        Write-WinUtilLog -Level "ERROR" -Detail -Component "Test" -Message "error detail"
        $global:WinUtilIsJobWorker = $false
        Write-WinUtilLog -Level "ERROR" -Component "UI" -Message "toggle error"

        $global:WinUtilJobErrorCount | Should -Be 2
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

Describe "Collected runspace output" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-logging-$([guid]::NewGuid())"
        $script:logPath = Join-Path $script:testRoot "logs\winutil_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            logPath = $script:logPath
        })
    }

    AfterEach {
        Close-WinUtilLog
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name WinUtilJobErrorCount -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "logs redirected Write-Host output and puts it back on the console as it was" {
        Mock Write-WinUtilHost { }

        & { Write-Host "Set HKLM:\Software\Example\Value to 1" -ForegroundColor Green } 6>&1 | ForEach-Object {
            Write-WinUtilStreamRecord -Record $_ -Component "Tweaks"
        }

        Get-Content -Path $script:logPath -Raw | Should -Match "\[INFO\] \[Tweaks\] Set HKLM:\\Software\\Example\\Value to 1"
        Should -Invoke Write-WinUtilHost -Times 1 -Exactly -ParameterFilter {
            $Object -eq "Set HKLM:\Software\Example\Value to 1" -and $ForegroundColor -eq "Green"
        }
    }

    It "logs redirected warnings and non-terminating errors" {
        Mock Write-WinUtilHost { }

        & { Write-Warning "Service Example was not found."; Write-Error "Access denied" } 2>&1 3>&1 | ForEach-Object {
            Write-WinUtilStreamRecord -Record $_ -Component "Tweaks"
        }

        $content = Get-Content -Path $script:logPath -Raw
        $content | Should -Match "\[WARN\] \[Tweaks\] Service Example was not found\."
        $content | Should -Match "\[ERROR\] \[Tweaks\] Non-terminating error : Access denied"
    }

    It "does not show again what the host already displayed" {
        Mock Write-WinUtilHost { }

        $collected = @(& { Write-Host "toggle applied"; Write-Warning "toggle warning" } 3>&1 6>&1)
        foreach ($record in $collected) {
            Write-WinUtilStreamRecord -Record $record -Component "UI" -Shown
        }

        Should -Invoke Write-WinUtilHost -Times 0 -Exactly
        $content = Get-Content -Path $script:logPath -Raw
        $content | Should -Match "\[INFO\] \[UI\] toggle applied"
        $content | Should -Match "\[WARN\] \[UI\] toggle warning"
    }

    It "ignores ordinary output and blank lines" {
        Mock Write-WinUtilHost { }

        & { "pipeline output"; Write-Host "" } 6>&1 | ForEach-Object {
            Write-WinUtilStreamRecord -Record $_ -Component "Tweaks"
        }

        Test-Path -Path $script:logPath | Should -BeFalse
    }

    It "moves each record from a runspace that shares the console host into the log once" {
        $runspace = [runspacefactory]::CreateRunspace($Host)
        $runspace.Open()
        $shell = [powershell]::Create()
        $shell.Runspace = $runspace

        try {
            [void]$shell.AddScript({
                Write-Host "interface message"
                Write-Warning "interface warning"
                Write-Error "interface error"
            })
            $shell.Invoke() | Out-Null

            Receive-WinUtilStreamOutput -PowerShell $shell -Component "UI"
            Receive-WinUtilStreamOutput -PowerShell $shell -Component "UI"

            $shell.Streams.Information.Count | Should -Be 0
            $shell.Streams.Warning.Count | Should -Be 0
            $shell.Streams.Error.Count | Should -Be 0
        } finally {
            $shell.Dispose()
            $runspace.Dispose()
        }

        $content = Get-Content -Path $script:logPath
        @($content | Where-Object { $_ -match "\[INFO\] \[UI\] interface message$" }).Count | Should -Be 1
        @($content | Where-Object { $_ -match "\[WARN\] \[UI\] interface warning$" }).Count | Should -Be 1
        @($content | Where-Object { $_ -match "\[ERROR\] \[UI\] Non-terminating error : interface error$" }).Count | Should -Be 1
    }

    It "keeps console-only helpers out of the information stream" {
        # Anything these send through Write-Host would be logged twice inside a job
        $failure = try { throw "simulated failure" } catch { $_ }

        $records = @(& {
            Write-WinUtilLog -Component "Test" -Message "entry"
            Write-WinUtilJobBanner -Message "Installing apps"
            Write-WinUtilErrorRecord -ErrorRecord $failure -Component "Test"
            Write-WinUtilConsoleProgress -Status "Installing" -Percent 10
            Complete-WinUtilConsoleProgress
        } 6>&1 | Where-Object { $_ -is [System.Management.Automation.InformationRecord] })

        $records.Count | Should -Be 0
    }
}

Describe "Session log wiring" {
    It "does not hand the session log to a transcript" {
        # A transcript only records the runspace that starts it, so the UI thread and jobs never
        # made it into the file. The ISO post-install script runs on its own and is fine.
        $offenders = Get-ChildItem -Path (Join-Path $script:repoRoot "scripts"), (Join-Path $script:repoRoot "functions") -Filter "*.ps1" -Recurse |
            Where-Object { $_.Name -ne "Invoke-WinUtilISOScript.ps1" } |
            Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match "Start-Transcript" } |
            ForEach-Object { $_.Name }

        $offenders | Should -BeNullOrEmpty
    }

    It "logs the interface thread's output while the window is open" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        $mainScript | Should -Match 'while \(-not \$uiHandle\.AsyncWaitHandle\.WaitOne\(\d+\)\) \{\s*Receive-WinUtilStreamOutput -PowerShell \$uiShell'
        $mainScript | Should -Match 'EndInvoke\(\$uiHandle\)[\s\S]*Receive-WinUtilStreamOutput -PowerShell \$uiShell'
    }

    It "closes the session log on both exits" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        ([regex]::Matches($mainScript, 'Close-WinUtilLog')).Count | Should -Be 2
    }
}
