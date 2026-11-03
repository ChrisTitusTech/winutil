BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $tweaks = Get-Content (Join-Path $repoRoot "config/tweaks.json") -Raw | ConvertFrom-Json
    $script:applySplitting = [scriptblock]::Create($tweaks.WPFTweaksSvcHostSplitting.InvokeScript -join "`n")
    $script:undoSplitting = [scriptblock]::Create($tweaks.WPFTweaksSvcHostSplitting.UndoScript -join "`n")

    function Get-CimInstance {
        param($ClassName)
    }
    function Set-ItemProperty {
        param($Path, $Name, $Value, $Type, [switch]$Force)
    }
}

Describe "Service-host splitting registry scripts" {
    BeforeEach {
        Mock Get-CimInstance {
            [pscustomobject]@{ Capacity = 8GB }
            [pscustomobject]@{ Capacity = 8GB }
        }
        Mock Set-ItemProperty { }
    }

    It "writes the summed physical memory in KB with an explicit DWORD type" {
        & $script:applySplitting

        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $ClassName -eq 'Win32_PhysicalMemory'
        }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control' -and
            $Name -eq 'SvcHostSplitThresholdInKB' -and
            $Value -eq 16777216 -and $Type -eq 'DWord'
        }
    }

    It "undoes directly to the Windows client DWORD default without querying memory" {
        & $script:undoSplitting

        Should -Invoke Get-CimInstance -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control' -and
            $Name -eq 'SvcHostSplitThresholdInKB' -and
            $Value -eq 3670016 -and $Type -eq 'DWord' -and $Force
        }
    }
}
