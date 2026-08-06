#===========================================================================
# Tests - Runspace lifecycle
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Close-WinUtilRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\New-WinUtilSessionState.ps1")
    . (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRunspacePool.ps1")
}

Describe "Initialize-WinUtilRunspacePool" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{})
        $script:PARAM_OFFLINE = $false
    }

    AfterEach {
        Close-WinUtilRunspacePool
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name PARAM_OFFLINE -Scope Script -ErrorAction SilentlyContinue
    }

    It "creates and reuses one open runspace pool" {
        $firstPool = Initialize-WinUtilRunspacePool
        $secondPool = Initialize-WinUtilRunspacePool

        $firstPool.RunspacePoolStateInfo.State | Should -Be ([System.Management.Automation.Runspaces.RunspacePoolState]::Opened)
        [object]::ReferenceEquals($firstPool, $secondPool) | Should -BeTrue
    }

    It "closes and removes the active runspace pool" {
        $pool = Initialize-WinUtilRunspacePool

        Close-WinUtilRunspacePool

        $pool.RunspacePoolStateInfo.State | Should -Be ([System.Management.Automation.Runspaces.RunspacePoolState]::Closed)
        $script:sync.ContainsKey("runspace") | Should -BeFalse
    }
}

Describe "Runspace startup wiring" {
    It "does not create the GUI runspace pool before automation checks" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $beforePreset = $mainScript.Substring(0, $mainScript.IndexOf('if ($Preset)'))

        $beforePreset | Should -Not -Match '\[runspacefactory\]::CreateRunspacePool'
        $beforePreset | Should -Not -Match '\$sync\.runspace\.Open\(\)'
    }

    It "initializes runspaces synchronously for automation paths and after first render for GUI" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $mainScript | Should -Match 'if \(\$Preset\) \{\s+Initialize-WinUtilRunspacePool'
        $mainScript | Should -Match 'if \(\$Config\) \{\s+Initialize-WinUtilRunspacePool'
        $uiScript | Should -Match 'Dispatcher\.BeginInvoke\(\[System\.Windows\.Threading\.DispatcherPriority\]::Background, \[action\]\{ Initialize-WinUtilRunspacePool'
        $mainScript | Should -Match 'Close-WinUtilRunspacePool'
    }

    It "runs the window on a dedicated STA runspace and waits for it from the main thread" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $mainScript | Should -Match '\$sync\.UIRunspace = \[runspacefactory\]::CreateRunspace\(\$Host, \(New-WinUtilSessionState\)\)'
        $mainScript | Should -Match '\$sync\.UIRunspace\.ApartmentState = "STA"'
        $mainScript | Should -Match '\$uiShell\.AddScript\(\{ Start-WinUtilUserInterface \}\)'
        $mainScript | Should -Match '\$uiHandle\.AsyncWaitHandle\.WaitOne\(\)'
        $mainScript | Should -Match '\$uiShell\.EndInvoke\(\$uiHandle\)'
        $mainScript | Should -Match 'foreach \(\$uiError in \$uiShell\.Streams\.Error\)'

        # ShowDialog and the window itself belong to the interface runspace, not to main.ps1
        $mainScript | Should -Not -Match 'ShowDialog'
        $uiScript | Should -Match '\$sync\["Form"\]\.ShowDialog\(\)'
        $uiScript | Should -Match '\[System\.Windows\.Threading\.Dispatcher\]::CurrentDispatcher\.InvokeShutdown\(\)'
    }

    It "builds one session state for both the interface runspace and the worker pool" {
        $sessionStateScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\New-WinUtilSessionState.ps1") -Raw
        $poolScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRunspacePool.ps1") -Raw

        foreach ($variableName in @("sync", "PARAM_OFFLINE", "inputXML", "WinUtilAutounattendXml")) {
            $sessionStateScript | Should -Match ([regex]::Escape("Name = `"$variableName`""))
        }
        # The interface runspace builds tabs and job bodies call arbitrary helpers, so every
        # WinUtil function has to be carried over, not a name-matched subset.
        $sessionStateScript | Should -Match 'foreach \(\$function in \(Get-ChildItem function:\\\)\)'
        $sessionStateScript | Should -Match '\$builtInFunctions\.Contains\(\$function\.Name\)'
        $sessionStateScript | Should -Not -Match "imatch 'winutil\|WPF'"
        $poolScript | Should -Match '\(New-WinUtilSessionState\)'
    }

    It "carries every WinUtil function into a new runspace" {
        $sync = [Hashtable]::Synchronized(@{})
        $null = $sync
        function Test-WinUtilSessionStateMarker { "marker" }
        function Get-SomethingUnprefixed { "unprefixed" }

        $runspace = [runspacefactory]::CreateRunspace((New-WinUtilSessionState))
        $runspace.Open()
        try {
            $shell = [powershell]::Create()
            $shell.Runspace = $runspace
            [void]$shell.AddScript('Test-WinUtilSessionStateMarker; Get-SomethingUnprefixed; (Get-Command mkdir).CommandType')
            $result = $shell.Invoke()
            $shell.Dispose()

            $result | Should -Contain "marker"
            $result | Should -Contain "unprefixed"
        } finally {
            $runspace.Close()
            $runspace.Dispose()
            Remove-Item Function:\Test-WinUtilSessionStateMarker -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-SomethingUnprefixed -ErrorAction SilentlyContinue
        }
    }

    It "creates runspaces on demand before queueing background work" {
        $runspaceScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFRunspace.ps1") -Raw

        $runspaceScript | Should -Match 'Initialize-WinUtilRunspacePool \| Out-Null'
    }
}
