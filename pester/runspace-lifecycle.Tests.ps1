#===========================================================================
# Tests - Runspace lifecycle

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Close-WinUtilRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\Stop-WinUtilActiveWork.ps1")
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

    
}
