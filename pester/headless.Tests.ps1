#===========================================================================
# Tests - Headless runs never need a window

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
    $script:startScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\start.ps1") -Raw
    $startAst = [System.Management.Automation.Language.Parser]::ParseInput($script:startScript, [ref]$null, [ref]$null)
    $script:fileProcessFunction = $startAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq "Test-WinUtilOwnsFileProcess"
    }, $true).Extent.Text
    $script:elevationCommandFunction = $startAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq "New-WinUtilElevationCommand"
    }, $true).Extent.Text

    . (Join-Path $script:functionRoot "private\Update-WinUtilSelections.ps1")
    . (Join-Path $script:functionRoot "public\Invoke-WPFImpex.ps1")

    # Stubs so the mocks below have something to replace; the real ones live in other files
    function Write-WinUtilLog { param($Level, $Component, $Message, [switch]$Detail) }
    function Write-WinUtilTimingSummary { param($Scope, $TotalMilliseconds) }
    function Clear-WinUtilActiveJob { param([string]$Token) $sync.ActiveJobToken = $null; $sync.ActiveJob = $null; return $true }
    # A timed out step stops its worker before the next one starts, so the run needs both of these
    function Stop-WinUtilActiveWork { param([switch]$NoWait) }
    function Test-WinUtilActiveWorkRunning { return $false }
    function Write-WinUtilErrorRecord { param($ErrorRecord, $Component, $Context) }
    function Invoke-WPFtweaksbutton { }
    function Invoke-WPFToggleSelections { }
    function Invoke-WPFFeatureInstall { }
    function Invoke-WPFInstall { }
    function Invoke-WPFAppxRemoval { }
}

Describe "Headless entry point" {
    It "handles preset and config through one path" {
        $script:mainScript | Should -Match 'if \(\$Preset -or \$Config\) \{'
    }

    It "returns an outcome without exiting an in-memory caller" {
        $script:mainScript | Should -Match 'if \(\$env:WINUTIL_HEADLESS_CHILD -eq "1" -or \$script:WinUtilIsFileProcess\) \{[\s\S]*exit \$headlessCode[\s\S]*\$global:LASTEXITCODE = \$headlessCode[\s\S]*return \$headlessCode'
        $script:mainScript | Should -Match 'Write-WinUtilAutoRunSummary'
    }

    It "exits with the outcome when headless mode owns a file-backed process" {
        $script:startScript | Should -Match '\$script:WinUtilIsFileProcess = Test-WinUtilOwnsFileProcess'
        $script:mainScript | Should -Match '-or \$script:WinUtilIsFileProcess\) \{[\s\S]*exit \$headlessCode'
    }

    It "recognizes explicit and positional direct file targets as process-owning" {
        . ([scriptblock]::Create($script:fileProcessFunction))
        $winUtilPath = Join-Path $script:repoRoot "winutil.ps1"
        $wrapperPath = Join-Path $TestDrive "wrapper.ps1"

        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-File", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-f", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-EP", "Bypass", "-File", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("powershell.exe", "-Version", "5.1", "-File", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("powershell.exe", "-PSConsoleFile", "profile.psc1", "-File", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-config", "profile.pssc", "-File", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-W", "Hidden", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-WorkingD", "C:\", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-Execu", "Bypass", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-i", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-NoProfile", $winUtilPath) | Should -BeTrue
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-NoExit", $winUtilPath) | Should -BeFalse
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-noe", $winUtilPath) | Should -BeFalse
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-File", $wrapperPath) | Should -BeFalse
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", $wrapperPath, "-HarnessPath", $winUtilPath) | Should -BeFalse
        Test-WinUtilOwnsFileProcess -ScriptPath $winUtilPath -CommandLineArgs @("pwsh.dll", "-Command", "& '$winUtilPath'") | Should -BeFalse
    }

    It "fails process-owning restricted-language launches without terminating in-memory callers" {
        $script:startScript | Should -Match 'LanguageMode -ne ''FullLanguage''[\s\S]*\$global:LASTEXITCODE = 1[\s\S]*if \(\$env:WINUTIL_HEADLESS_CHILD -eq "1" -or \$script:WinUtilIsFileProcess\) \{ exit 1 \}[\s\S]*return 1'
    }

    It "passes hostile elevation parameter values as data instead of executable code" {
        . ([scriptblock]::Create($script:elevationCommandFunction))
        $targetDirectory = Join-Path $TestDrive "O'Brien"
        $targetScript = Join-Path $targetDirectory "target.ps1"
        $markerPath = Join-Path $TestDrive "injected.txt"
        New-Item -ItemType Directory -Path $targetDirectory | Out-Null
        'param([string]$Config) Write-Output $Config' | Set-Content -LiteralPath $targetScript
        $hostileConfig = "'; Set-Content -LiteralPath '$markerPath' -Value injected; #"

        $encodedCommand = New-WinUtilElevationCommand -ScriptPath $targetScript -Parameters @{ Config = $hostileConfig } -Headless
        $bootstrap = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encodedCommand))
        $previousChildFlag = $env:WINUTIL_HEADLESS_CHILD
        try {
            $output = & ([scriptblock]::Create($bootstrap))
        } finally {
            $env:WINUTIL_HEADLESS_CHILD = $previousChildFlag
        }

        $bootstrap | Should -Not -Match ([regex]::Escape($hostileConfig))
        $output | Should -Be $hostileConfig
        Test-Path -LiteralPath $markerPath | Should -BeFalse
    }

    It "propagates direct -File codes without terminating a file-backed wrapper" {
        $harnessPath = Join-Path $TestDrive "headless-exit-harness.ps1"
        $wrapperPath = Join-Path $TestDrive "headless-exit-wrapper.ps1"
        @"
param([int]`$Code)
$($script:fileProcessFunction)
`$ownsProcess = Test-WinUtilOwnsFileProcess -ScriptPath `$PSCommandPath -CommandLineArgs ([Environment]::GetCommandLineArgs())
if (`$ownsProcess) { exit `$Code }
return `$Code
"@ | Set-Content -LiteralPath $harnessPath
        @'
param([string]$HarnessPath)
& $HarnessPath -Code 7 | Out-Null
exit 23
'@ | Set-Content -LiteralPath $wrapperPath

        $powerShellHosts = @(Get-Command pwsh.exe, powershell.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -Unique)
        $powerShellHosts.Count | Should -BeGreaterThan 0
        foreach ($powerShellHost in $powerShellHosts) {
            & $powerShellHost -ExecutionPolicy Bypass -NoProfile -File $harnessPath -Code 0 | Out-Null
            $LASTEXITCODE | Should -Be 0 -Because "$powerShellHost should propagate success"

            & $powerShellHost -ExecutionPolicy Bypass -NoProfile -File $harnessPath -Code 7 | Out-Null
            $LASTEXITCODE | Should -Be 7 -Because "$powerShellHost should propagate failure"

            & $powerShellHost -ExecutionPolicy Bypass -NoProfile -f $harnessPath -Code 7 | Out-Null
            $LASTEXITCODE | Should -Be 7 -Because "$powerShellHost should support the -f alias"

            if ((Split-Path -Leaf $powerShellHost) -like "pwsh*") {
                & $powerShellHost -NoProfile $harnessPath -Code 7 | Out-Null
                $LASTEXITCODE | Should -Be 7 -Because "$powerShellHost should support a positional file target"
            }

            & $powerShellHost -ExecutionPolicy Bypass -NoProfile -File $wrapperPath -HarnessPath $harnessPath | Out-Null
            $LASTEXITCODE | Should -Be 23 -Because "$powerShellHost should let the wrapper continue"
        }
    }

    It "propagates a compiled WinUtil headless failure without terminating its wrapper" {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
        if (-not $isAdmin) {
            Set-ItResult -Skipped -Because "the compiled WinUtil process would open a UAC prompt"
            return
        }

        & (Join-Path $script:repoRoot "Compile.ps1")
        $compiledPath = Join-Path $script:repoRoot "winutil.ps1"
        $missingConfig = Join-Path $TestDrive "missing-config.json"
        $wrapperPath = Join-Path $TestDrive "compiled-winutil-wrapper.ps1"
        @'
param([string]$WinUtilPath, [string]$MissingConfig)
$source = Get-Content -LiteralPath $WinUtilPath -Raw
& ([scriptblock]::Create($source)) -Config $MissingConfig | Out-Null
Write-Output "wrapper-continued"
exit 23
'@ | Set-Content -LiteralPath $wrapperPath

        $powerShellHosts = @(Get-Command pwsh.exe, powershell.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -Unique)
        foreach ($powerShellHost in $powerShellHosts) {
            & $powerShellHost -ExecutionPolicy Bypass -NoProfile -File $compiledPath -Config $missingConfig | Out-Null
            $LASTEXITCODE | Should -Be 1 -Because "$powerShellHost should propagate WinUtil's failed config import"

            $wrapperOutput = @(& $powerShellHost -ExecutionPolicy Bypass -NoProfile -File $wrapperPath -WinUtilPath $compiledPath -MissingConfig $missingConfig)
            $LASTEXITCODE | Should -Be 23 -Because "$powerShellHost should let the file-backed wrapper continue"
            $wrapperOutput | Should -Contain "wrapper-continued"
        }
    }

    It "cleans up even when the run throws" {
        # Without a finally a failed run leaves the worker pool open and the transcript running
        $script:mainScript | Should -Match '\} finally \{[\s\S]*Close-WinUtilRunspacePool[\s\S]*Stop-Transcript'
    }

    It "names the presets that exist when given one that does not" {
        $script:mainScript | Should -Match "There is no preset called"
    }

    It "waits for the elevated run and passes its code back" {
        # Start-Process without -Wait returns immediately, so the caller would see success
        # regardless of what the run did
        $script:startScript | Should -Match '\$elevated = Start-Process[^\r\n]*-Wait -PassThru'
        $script:startScript | Should -Match '\$env:WINUTIL_HEADLESS_CHILD = ''1'''
        $script:startScript | Should -Match '\$global:LASTEXITCODE = \$elevated\.ExitCode[\s\S]*return \$elevated\.ExitCode'
        $script:startScript | Should -Match 'if \(\$script:WinUtilIsFileProcess\) \{ exit \$elevated\.ExitCode \}'
    }
}

Describe "Headless config import" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
    }

    It "throws when a requested config cannot be loaded" {
        $missingConfig = Join-Path $TestDrive "missing.json"

        { Invoke-WPFImpex -type "import" -Config $missingConfig -ThrowOnError } | Should -Throw
    }
}

Describe "Invoke-WinUtilAutoRun" {
    BeforeAll {
        . (Join-Path $script:functionRoot "public\Invoke-WinUtilAutoRun.ps1")
    }

    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
        $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
        $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
        $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
        $sync.selectedAppx = [System.Collections.Generic.List[string]]::new()
        $sync.LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        $sync.ActiveJob = $null

        Mock Write-WinUtilLog { }
        Mock Write-WinUtilTimingSummary { }
        Mock Write-WinUtilErrorRecord { }
    }

    It "does nothing and says so when nothing is selected" {
        $summary = Invoke-WinUtilAutoRun

        @($summary.Steps).Count | Should -Be 0
        Should -Invoke -CommandName Write-WinUtilLog -ParameterFilter { $Level -eq "WARN" -and $Message -like "*nothing to do*" }
    }

    It "applies toggles, which nothing outside the window ever did" {
        $sync.selectedToggles.Add("WPFToggleDarkMode")
        Mock Invoke-WPFToggleSelections { }

        $summary = Invoke-WinUtilAutoRun

        Should -Invoke -CommandName Invoke-WPFToggleSelections -Times 1 -Exactly
        @($summary.Steps | Where-Object { $_.Name -eq "Toggles" }).Count | Should -Be 1
    }

    It "runs only the steps that have something selected" {
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFInstall { }
        Mock Invoke-WPFtweaksbutton { }

        $summary = Invoke-WinUtilAutoRun

        @($summary.Steps).Count | Should -Be 1
        $summary.Steps[0].Name | Should -Be "Applications"
        Should -Invoke -CommandName Invoke-WPFtweaksbutton -Times 0 -Exactly
    }

    It "gives up on a step that never finishes instead of hanging for good" {
        $sync.selectedApps.Add("WPFInstall7zip")
        # a job that sets the flag and never clears it
        Mock Invoke-WPFInstall { $sync.ActiveJob = "Install" }

        $summary = Invoke-WinUtilAutoRun -StepTimeoutSeconds 1

        $summary.TimedOut | Should -Be 1
        # and the flag must be released, or every later step would be refused
        $sync.ActiveJob | Should -BeNullOrEmpty
    }

    It "abandons the remaining steps when a timed out worker will not stop" {
        $sync.selectedTweaks.Add("WPFTweaksAH")
        $sync.selectedApps.Add("WPFInstall7zip")
        # the first step times out, and its worker is still running afterwards
        Mock Invoke-WPFtweaksbutton { $sync.ActiveJob = "Tweaks" }
        Mock Invoke-WPFInstall { }
        Mock Stop-WinUtilActiveWork { }
        Mock Test-WinUtilActiveWorkRunning { return $true }

        $summary = Invoke-WinUtilAutoRun -StepTimeoutSeconds 1 -StopTimeoutSeconds 1

        $summary.TimedOut | Should -Be 1
        # the later step must not run beside work that is still changing the machine
        Should -Invoke -CommandName Invoke-WPFInstall -Times 0 -Exactly
        Should -Invoke -CommandName Stop-WinUtilActiveWork -Times 1 -Exactly
    }

    It "counts a step's errors against the run" {
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFInstall { $null = $sync.LoggedErrors.Add("boom") }

        $summary = Invoke-WinUtilAutoRun

        $summary.Failed | Should -Be 1
        $summary.Errors | Should -Be 1
    }

    It "reports warnings produced by a completed job" {
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFInstall {
            $sync.LastJobResult = [pscustomobject]@{ Errors = 0; Warnings = 1 }
        }

        $summary = Invoke-WinUtilAutoRun

        $summary.Failed | Should -Be 0
        $summary.Warnings | Should -Be 1
        $summary.Steps[0].Warnings | Should -Be 1
    }

    It "keeps going after a step throws rather than abandoning the run" {
        $sync.selectedTweaks.Add("WPFTweaksDiskCleanup")
        $sync.selectedApps.Add("WPFInstall7zip")
        Mock Invoke-WPFtweaksbutton { throw "tweaks blew up" }
        Mock Invoke-WPFInstall { }

        $summary = Invoke-WinUtilAutoRun

        Should -Invoke -CommandName Invoke-WPFInstall -Times 1 -Exactly
        @($summary.Steps).Count | Should -Be 2
    }
}

Describe "Write-WinUtilAutoRunSummary" {
    BeforeAll {
        . (Join-Path $script:functionRoot "public\Invoke-WinUtilAutoRun.ps1")
    }

    BeforeEach {
        $global:sync = @{ logPath = "C:\temp\winutil.log" }
        Mock Write-Host { }
    }

    It "returns 0 when every step was clean" {
        $summary = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Tweaks"; Items = 1; Seconds = 1; Errors = 0; TimedOut = $false })
            Failed = 0; TimedOut = 0; Errors = 0
        }

        Write-WinUtilAutoRunSummary -Summary $summary | Should -Be 0
    }

    It "returns 1 when a step failed or timed out" {
        $failed = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Tweaks"; Items = 1; Seconds = 1; Errors = 2; TimedOut = $false })
            Failed = 1; TimedOut = 0; Errors = 2
        }
        Write-WinUtilAutoRunSummary -Summary $failed | Should -Be 1

        $timedOut = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Apps"; Items = 1; Seconds = 60; Errors = 0; TimedOut = $true })
            Failed = 0; TimedOut = 1; Errors = 0
        }
        Write-WinUtilAutoRunSummary -Summary $timedOut | Should -Be 1
    }

    It "returns 2 when nothing was selected, which is not the same as success" {
        $summary = [pscustomobject]@{ Steps = @(); Failed = 0; TimedOut = 0; Errors = 0 }

        Write-WinUtilAutoRunSummary -Summary $summary | Should -Be 2
    }

    It "reports warnings without turning an expected package skip into failure" {
        $summary = [pscustomobject]@{
            Steps = @([pscustomobject]@{ Name = "Applications"; Items = 1; Seconds = 1; Errors = 0; Warnings = 1; TimedOut = $false })
            Failed = 0; TimedOut = 0; Errors = 0; Warnings = 1
        }

        Write-WinUtilAutoRunSummary -Summary $summary | Should -Be 0
        Should -Invoke Write-Host -ParameterFilter { $Object -like "Completed with warnings*" }
    }
}

Describe "Update-WinUtilSelections" {
    BeforeEach {
        $global:sync = [hashtable]::Synchronized(@{})
        foreach ($list in @("selectedApps","selectedTweaks","selectedToggles","selectedFeatures","selectedAppx")) {
            $sync.$list = [System.Collections.Generic.List[string]]::new()
        }
        # The selection sorter now checks each key against the real catalogue before taking it,
        # so the fixture has to carry the configs it reads
        $sync.configs = @{
            applicationsHashtable = @{ "WPFInstall7zip" = @{} }
            appxHashtable         = @{ "WPFAppxBing" = @{} }
            tweaks                = [pscustomobject]@{ "WPFTweaksDiskCleanup" = @{}; "WPFToggleDarkMode" = @{} }
            feature               = [pscustomobject]@{ "WPFFeaturesdotnet" = @{} }
        }
        Mock Write-WinUtilLog { }
    }

    It "sorts each prefix into its own list" {
        Update-WinUtilSelections -flatJson @("WPFInstall7zip","WPFTweaksDiskCleanup","WPFToggleDarkMode","WPFFeaturesdotnet","WPFAppxBing")

        $sync.selectedApps | Should -Contain "WPFInstall7zip"
        $sync.selectedTweaks | Should -Contain "WPFTweaksDiskCleanup"
        $sync.selectedToggles | Should -Contain "WPFToggleDarkMode"
        $sync.selectedFeatures | Should -Contain "WPFFeaturesdotnet"
        $sync.selectedAppx | Should -Contain "WPFAppxBing"
    }

    It "hands back an unrecognised entry rather than throwing, which is what the headless run relies on" {
        # The headless path passes SkipUnknown so a retired entry names itself and the run goes
        # on. Without it the call is strict, which is what the window wants.
        $skipped = @(Update-WinUtilSelections -flatJson @("NotAWinUtilEntry") -SkipUnknown)

        $skipped | Should -Contain "NotAWinUtilEntry"
        { Update-WinUtilSelections -flatJson @("NotAWinUtilEntry") } | Should -Throw
    }

    It "does not select the same entry twice when a preset and a config both list it" {
        Update-WinUtilSelections -flatJson @("WPFInstall7zip")
        Update-WinUtilSelections -flatJson @("WPFInstall7zip")

        @($sync.selectedApps).Count | Should -Be 1
    }
}
