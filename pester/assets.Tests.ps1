#===========================================================================
# Tests - Asset rendering

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Register-WinUtilRunspaceCleanup.ps1")
}

Describe "Taskbar overlay rendering" {
    It "loads the versioned cleanup helper beside a previous WinUtil helper type" {
        if (-not ("WinUtilRunspaceCleanup" -as [type])) {
            Add-Type @"
using System;
using System.Management.Automation;

public sealed class WinUtilRunspaceCleanupState
{
    public PowerShell PowerShell { get; set; }
    public IAsyncResult Handle { get; set; }
}

public static class WinUtilRunspaceCleanup
{
    public static readonly System.Threading.WaitOrTimerCallback Callback =
        delegate(object state, bool timedOut) { };
}
"@
        }

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $shell = [powershell]::Create()
        $shell.Runspace = $runspace
        [void]$shell.AddScript({ $null = 1 })
        $handle = $shell.BeginInvoke()

        { Register-WinUtilRunspaceCleanup -PowerShell $shell -Handle $handle -Runspace $runspace } |
            Should -Not -Throw
    }

    It "serializes speculative and fallback rendering through one shared lock" {
        $startSource = Get-Content -Path (Join-Path $script:repoRoot "scripts\start.ps1") -Raw
        $initializerSource = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTaskbarOverlayAssets.ps1") -Raw

        $startSource | Should -Match '\$sync\.AssetRenderLock = \[object\]::new\(\)'
        $startSource | Should -Match '\$sync\.RenderedAssetCache = \[Hashtable\]::Synchronized'
        $initializerSource | Should -Match '\[System\.Threading\.Monitor\]::Enter\(\$assetRenderLock\)'
        $initializerSource | Should -Match '\[System\.Threading\.Monitor\]::Exit\(\$assetRenderLock\)'
    }

    It "closes a dedicated runspace after its invocation completes" {
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $shell = [powershell]::Create()
        $shell.Runspace = $runspace
        [void]$shell.AddScript({ $null = 1 })
        $handle = $shell.BeginInvoke()

        Register-WinUtilRunspaceCleanup -PowerShell $shell -Handle $handle -Runspace $runspace

        $deadline = (Get-Date).AddSeconds(5)
        while ($runspace.RunspaceStateInfo.State -eq 'Opened' -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 25
        }

        $runspace.RunspaceStateInfo.State | Should -Not -Be 'Opened'
    }
}
