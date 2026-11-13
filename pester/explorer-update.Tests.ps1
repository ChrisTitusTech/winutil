#===========================================================================
# Tests - Invoke-WinUtilExplorerUpdate restart scoping
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilExplorerUpdate.ps1")

    function taskkill.exe {
        param([Parameter(ValueFromRemainingArguments = $true)]$Arguments)
    }
}

Describe "Invoke-WinUtilExplorerUpdate restart" {
    BeforeEach {
        Mock taskkill.exe { }
        Mock Start-Process { }
    }

    It "kills only explorer processes in the current session" {
        $currentSessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        Mock Get-Process {
            @(
                [pscustomobject]@{ Id = 111; SessionId = $currentSessionId; Name = 'explorer' }
                [pscustomobject]@{ Id = 222; SessionId = 9999; Name = 'explorer' }
            )
        } -ParameterFilter { $Name -eq 'explorer' }

        Invoke-WinUtilExplorerUpdate -action restart

        Should -Invoke -CommandName taskkill.exe -Times 1 -Exactly -ParameterFilter {
            $Arguments[0] -eq '/F' -and $Arguments[1] -eq '/PID' -and $Arguments[2] -eq 111
        }
        Should -Invoke -CommandName Start-Process -Times 1 -Exactly
    }
}
