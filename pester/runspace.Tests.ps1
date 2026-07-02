#===========================================================================
# Tests - Runspace Behavior
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
        $handle = Invoke-WPFRunspace -ScriptBlock {
            Start-Sleep -Milliseconds 100
            "no-args|$($sync.Marker)"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        @($script:powershell.EndInvoke($handle))[0] | Should -Be "no-args|shared"
    }

    It "passes one named parameter" {
        $handle = Invoke-WPFRunspace -ParameterList @(,("Name", "value")) -ScriptBlock {
            param([string]$Name)

            Start-Sleep -Milliseconds 100
            "Name=$Name"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        @($script:powershell.EndInvoke($handle))[0] | Should -Be "Name=value"
    }

    It "passes multiple named parameters" {
        $handle = Invoke-WPFRunspace -ParameterList @(
            ("First", "alpha"),
            ("Second", "beta")
        ) -ScriptBlock {
            param(
                [string]$First,
                [string]$Second
            )

            Start-Sleep -Milliseconds 100
            "$First|$Second|$($sync.Marker)"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        @($script:powershell.EndInvoke($handle))[0] | Should -Be "alpha|beta|shared"
    }

    It "surfaces scriptblock failures through the owning PowerShell instance" {
        $handle = Invoke-WPFRunspace -ScriptBlock {
            Start-Sleep -Milliseconds 100
            throw "runspace failure"
        }

        Assert-WinUtilAsyncHandle -Handle $handle
        { $script:powershell.EndInvoke($handle) } | Should -Throw -ExpectedMessage "*runspace failure*"
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
