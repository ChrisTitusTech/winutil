#===========================================================================
# Tests - Runspace Behavior
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Close-WinUtilRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFRunspace.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFFeatureInstall.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxRemoval.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFundoall.ps1")

    function script:New-WinUtilRunspaceTestContext {
        param([hashtable]$InitialSync = @{})

        $script:sync = [Hashtable]::Synchronized($InitialSync)
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $syncVariable = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "sync", $script:sync, $null
        $initialSessionState.Variables.Add($syncVariable)
        $script:sync.runspace = [runspacefactory]::CreateRunspacePool(1, 2, $initialSessionState, $Host)
        $script:sync.runspace.Open()
    }

    function script:Clear-WinUtilRunspaceTestContext {
        if ($script:sync -and $script:sync.runspace) {
            $script:sync.runspace.Close()
            $script:sync.runspace.Dispose()
        }

        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    function script:Assert-WinUtilAsyncHandle {
        param($Handle)

        ($Handle -is [System.IAsyncResult]) | Should -BeTrue
        ($Handle -is [array]) | Should -BeFalse
        $Handle.AsyncWaitHandle.WaitOne(5000) | Should -BeTrue
    }
}

Describe "Invoke-WPFRunspace behavior" {
    BeforeEach {
        New-WinUtilRunspaceTestContext -InitialSync @{ Marker = "shared" }
    }

    AfterEach {
        Clear-WinUtilRunspaceTestContext
    }

    It "returns a single async handle with no argument list" {
        $script:sync.Result = $null

        $handle = Invoke-WPFRunspace -ScriptBlock {
            Start-Sleep -Milliseconds 100
            $sync.Result = "no-args|$($sync.Marker)"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        $script:sync.Result | Should -Be "no-args|shared"
    }

    It "passes one named parameter" {
        $script:sync.Result = $null

        $handle = Invoke-WPFRunspace -ParameterList @(,("Name", "value")) -ScriptBlock {
            param([string]$Name)

            Start-Sleep -Milliseconds 100
            $sync.Result = "Name=$Name"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        $script:sync.Result | Should -Be "Name=value"
    }

    It "passes multiple named parameters" {
        $script:sync.Result = $null

        $handle = Invoke-WPFRunspace -ParameterList @(
            ("First", "alpha"),
            ("Second", "beta")
        ) -ScriptBlock {
            param(
                [string]$First,
                [string]$Second
            )

            Start-Sleep -Milliseconds 100
            $sync.Result = "$First|$Second|$($sync.Marker)"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        $script:sync.Result | Should -Be "alpha|beta|shared"
    }

    It "keeps the shared runspace pool usable after scriptblock failures" {
        $handle = Invoke-WPFRunspace -ScriptBlock {
            Start-Sleep -Milliseconds 100
            throw "runspace failure"
        }

        Assert-WinUtilAsyncHandle -Handle $handle

        $script:sync.Result = $null
        $secondHandle = Invoke-WPFRunspace -ScriptBlock {
            $sync.Result = "after-failure"
        }

        Assert-WinUtilAsyncHandle -Handle $secondHandle
        $script:sync.Result | Should -Be "after-failure"
    }

    It "runs multiple queued invocations without shared PowerShell state" {
        $script:sync.FirstResult = $null
        $script:sync.SecondResult = $null

        $firstHandle = Invoke-WPFRunspace -ParameterList @(,("Value", "first")) -ScriptBlock {
            param([string]$Value)

            Start-Sleep -Milliseconds 150
            $sync.FirstResult = $Value
        }
        $secondHandle = Invoke-WPFRunspace -ParameterList @(,("Value", "second")) -ScriptBlock {
            param([string]$Value)

            $sync.SecondResult = $Value
        }

        Assert-WinUtilAsyncHandle -Handle $firstHandle
        Assert-WinUtilAsyncHandle -Handle $secondHandle
        $script:sync.FirstResult | Should -Be "first"
        $script:sync.SecondResult | Should -Be "second"
    }

    It "does not use script-scoped PowerShell or handle state" {
        $runspaceScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFRunspace.ps1") -Raw

        $runspaceScript | Should -Not -Match '\$script:powershell'
        $runspaceScript | Should -Not -Match '\$script:handle'
    }
}

Describe "Public runspace callers" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            selectedFeatures = [System.Collections.Generic.List[string]]::new()
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                appxHashtable = @{}
            }
        })

        Mock Invoke-WPFRunspace { [pscustomobject]@{ MockHandle = $true } }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues selected feature installation without executing the runspace body" {
        $script:sync.selectedFeatures.Add("WPFFeaturesSandbox")

        Invoke-WPFFeatureInstall

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and $null -eq $ArgumentList -and $null -eq $ParameterList
        }
    }

    It "passes selected tweaks as the runspace argument list for undo all" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFundoall

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and
                $ArgumentList.Count -eq 2 -and
                $ArgumentList[0] -eq "WPFTweaksTelemetry" -and
                $ArgumentList[1] -eq "WPFTweaksServices"
        }
    }

    It "passes selected AppX items and app metadata to the removal runspace" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable["WPFAppxExample"] = [pscustomobject]@{
            Content = "Example"
            PackageId = "Example.Package"
        }

        Invoke-WPFAppxRemoval

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and
                $ParameterList.Count -eq 2 -and
                $ParameterList[0][0] -eq "selected" -and
                $ParameterList[0][1][0] -eq "WPFAppxExample" -and
                $ParameterList[1][0] -eq "apps" -and
                $ParameterList[1][1].ContainsKey("WPFAppxExample")
        }
    }
}
