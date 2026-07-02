#===========================================================================
# Tests - General Sanity
#===========================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    function script:Test-WinUtilParser {
        param([string]$Path)

        $tokens = $null
        $syntaxErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$syntaxErrors) | Out-Null

        if ($syntaxErrors.Count -ne 0) {
            throw ($syntaxErrors | Out-String)
        }
    }

    function script:Invoke-WindowsPowerShellParser {
        param([string[]]$Path)

        $windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
        if (-not $windowsPowerShell) {
            Set-ItResult -Skipped -Because "powershell.exe is not available on this platform."
            return
        }

        $previousPaths = $env:WINUTIL_TEST_PARSE_PATHS
        try {
            $env:WINUTIL_TEST_PARSE_PATHS = @($Path) -join [Environment]::NewLine
            $parseScript = @'
$ErrorActionPreference = 'Stop'
$paths = $env:WINUTIL_TEST_PARSE_PATHS -split "`r?`n" | Where-Object { $_ }
$failed = @()

foreach ($path in $paths) {
    $tokens = $null
    $syntaxErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$syntaxErrors) | Out-Null

    if ($syntaxErrors.Count -ne 0) {
        $messages = $syntaxErrors | ForEach-Object { $_.Message }
        $failed += "[$path] $($messages -join '; ')"
    }
}

if ($failed.Count -gt 0) {
    $failed -join [Environment]::NewLine
    exit 1
}
'@

            $output = & $windowsPowerShell.Source -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $parseScript 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Windows PowerShell parser failed:`n$($output | Out-String)"
            }
        } finally {
            if ($null -eq $previousPaths) {
                Remove-Item Env:\WINUTIL_TEST_PARSE_PATHS -ErrorAction SilentlyContinue
            } else {
                $env:WINUTIL_TEST_PARSE_PATHS = $previousPaths
            }
        }
    }
}

Describe "PowerShell source sanity" {
    $scriptCases = @(
        "Compile.ps1",
        "windev.ps1",
        "scripts\start.ps1",
        "scripts\main.ps1"
    ) | ForEach-Object {
        @{
            Name = $_
            Path = Join-Path $repoRoot $_
        }
    }

    foreach ($scriptCase in $scriptCases) {
        It "parses $($scriptCase.Name) with the current PowerShell parser" -TestCases $scriptCase {
            param([string]$Path)

            Test-WinUtilParser -Path $Path
        }
    }

    It "parses WinUtil source files with Windows PowerShell when available" {
        $sourcePaths = @(
            Join-Path $script:repoRoot "Compile.ps1"
            Join-Path $script:repoRoot "windev.ps1"
            Join-Path $script:repoRoot "scripts\start.ps1"
            Join-Path $script:repoRoot "scripts\main.ps1"
            Get-ChildItem -Path (Join-Path $script:repoRoot "functions") -Filter *.ps1 -Recurse | Select-Object -ExpandProperty FullName
        )

        Invoke-WindowsPowerShellParser -Path $sourcePaths
    }
}

Describe "Compiled WinUtil sanity" {
    BeforeAll {
        $script:compiledPath = Join-Path $script:repoRoot "winutil.ps1"

        Push-Location $script:repoRoot
        try {
            & (Join-Path $script:repoRoot "Compile.ps1")
        } finally {
            Pop-Location
        }
    }

    It "generates winutil.ps1" {
        Test-Path -Path $script:compiledPath | Should -BeTrue
    }

    It "parses compiled winutil.ps1 with the current PowerShell parser" {
        Test-WinUtilParser -Path $script:compiledPath
    }

    It "parses compiled winutil.ps1 with Windows PowerShell when available" {
        Invoke-WindowsPowerShellParser -Path $script:compiledPath
    }

    It "contains embedded configs, XAML, autounattend XML, and runspace bootstrap" {
        $content = Get-Content -Path $script:compiledPath -Raw
        $requiredSnippets = @(
            ('$sync.configs.applications = @' + "'"),
            ('$inputXML = @' + "'"),
            ('$WinUtilAutounattendXml = @' + "'"),
            "SessionStateVariableEntry -ArgumentList 'sync'",
            "SessionStateFunctionEntry",
            "[runspacefactory]::CreateRunspacePool",
            "function Invoke-WPFRunspace"
        )

        foreach ($snippet in $requiredSnippets) {
            if (-not $content.Contains($snippet)) {
                throw "Compiled script is missing expected content: $snippet"
            }
        }
    }

    It "transforms applications config keys with WPFInstall prefixes" {
        $content = Get-Content -Path $script:compiledPath -Raw
        $configMatch = [regex]::Match(
            $content,
            "(?s)\`$sync\.configs\.applications = @'\r?\n(?<json>.*?)\r?\n'@ \| ConvertFrom-Json"
        )

        if (-not $configMatch.Success) {
            throw "Compiled script is missing embedded applications config."
        }

        $sourceApps = Get-Content -Path (Join-Path $script:repoRoot "config\applications.json") -Raw | ConvertFrom-Json
        $compiledApps = $configMatch.Groups["json"].Value | ConvertFrom-Json

        foreach ($sourceApp in $sourceApps.PSObject.Properties) {
            $compiledKey = "WPFInstall$($sourceApp.Name)"
            if ($compiledApps.PSObject.Properties.Name -notcontains $compiledKey) {
                throw "Compiled applications config is missing transformed key: $compiledKey"
            }
            if ($compiledApps.PSObject.Properties.Name -contains $sourceApp.Name) {
                throw "Compiled applications config contains untransformed source key: $($sourceApp.Name)"
            }
        }
    }

    It "preserves compile source ordering" {
        $content = Get-Content -Path $script:compiledPath -Raw
        $orderedSnippets = @(
            '$sync.version =',
            'function Add-SelectedAppsMenuItem',
            ('$sync.configs.applications = @' + "'"),
            ('$inputXML = @' + "'"),
            ('$WinUtilAutounattendXml = @' + "'"),
            '$sync.SearchBarClearButton.Add_Click({'
        )

        $lastIndex = -1
        foreach ($snippet in $orderedSnippets) {
            $index = $content.IndexOf($snippet)
            if ($index -lt 0) {
                throw "Compiled script is missing expected ordered content: $snippet"
            }
            if ($index -le $lastIndex) {
                throw "Compiled script content is out of order near: $snippet"
            }

            $lastIndex = $index
        }
    }

    It "replaces the generated build date placeholder" {
        $content = Get-Content -Path $script:compiledPath -Raw
        $expectedBuildDate = Get-Date -Format "yy.MM.dd"

        $content | Should -Not -Match ([regex]::Escape("#{replaceme}"))
        $content | Should -Match ([regex]::Escape('$sync.version = "' + $expectedBuildDate + '"'))
    }
}

Describe "Runspace sanity" {
    BeforeAll {
        . (Join-Path $script:repoRoot "functions\public\Invoke-WPFRunspace.ps1")
    }

    It "returns a single async handle and runs a scriptblock with arguments in the shared runspace pool" {
        $script:sync = [Hashtable]::Synchronized(@{ SmokeValue = "shared" })
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $syncVariable = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "sync", $script:sync, $null
        $initialSessionState.Variables.Add($syncVariable)
        $script:sync.runspace = [runspacefactory]::CreateRunspacePool(1, 2, $initialSessionState, $Host)
        $script:sync.runspace.Open()

        $ended = $false
        try {
            $handle = Invoke-WPFRunspace -ArgumentList "argument" -ParameterList @(,("NamedValue", "parameter")) -ScriptBlock {
                param($ArgumentValue, [string]$NamedValue)

                Start-Sleep -Milliseconds 200
                "$ArgumentValue|$NamedValue|$($sync.SmokeValue)"
            }

            ($handle -is [System.IAsyncResult]) | Should -BeTrue
            ($handle -is [array]) | Should -BeFalse
            $handle.AsyncWaitHandle.WaitOne(5000) | Should -BeTrue

            $result = $script:powershell.EndInvoke($handle)
            $ended = $true

            @($result)[0] | Should -Be "argument|parameter|shared"
        } finally {
            if (-not $ended -and $handle -and $handle.IsCompleted -and $script:powershell) {
                try {
                    $script:powershell.EndInvoke($handle) | Out-Null
                } catch {
                    # The assertion failure is more useful than cleanup errors here.
                }
            }

            if ($script:powershell) {
                $script:powershell.Dispose()
            }

            if ($script:sync -and $script:sync.runspace) {
                $script:sync.runspace.Close()
                $script:sync.runspace.Dispose()
            }

            Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
            Remove-Variable -Name powershell -Scope Script -ErrorAction SilentlyContinue
            Remove-Variable -Name handle -Scope Script -ErrorAction SilentlyContinue
        }
    }
}
