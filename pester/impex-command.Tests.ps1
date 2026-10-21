BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $repoRoot "functions\public\Invoke-WPFImpex.ps1")
}

Describe "Exported configuration clipboard command" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            selectedApps = @("WPFInstallGit")
            selectedTweaks = @()
            selectedToggles = @()
            selectedFeatures = @()
            selectedAppx = @()
        })
        $script:copiedCommand = $null
        Mock Set-Clipboard { $script:copiedCommand = $Value }
        # Execute only a harmless replacement that echoes the received path.
        Mock Invoke-RestMethod { 'param([string]$Config) $Config' }
    }

    AfterEach {
        Remove-Variable -Name sync, copiedCommand -Scope Script -ErrorAction SilentlyContinue
    }

    It "preserves the configuration path for <FileName> when the copied command runs" -ForEach @(
        @{ FileName = 'my settings.json' }
        @{ FileName = "O'Brien.json" }
        @{ FileName = ('O{0}Brien.json' -f [char]0x2019) }
        @{ FileName = '$HOME.json' }
        @{ FileName = 'back`tick.json' }
        @{ FileName = '$(1+2).json' }
    ) {
        $configPath = Join-Path $TestDrive $FileName
        Invoke-WPFImpex -type "export" -Config $configPath

        $script:copiedCommand | Should -Not -BeNullOrEmpty
        $result = & ([scriptblock]::Create($script:copiedCommand))

        $result | Should -Be $configPath
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://christitus.com/win'
        }
    }
}
