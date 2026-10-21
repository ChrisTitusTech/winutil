BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $repoRoot "functions\public\Invoke-WPFImpex.ps1")
    . (Join-Path $repoRoot "functions\private\Update-WinUtilSelections.ps1")
}

Describe "Configuration file paths" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                applicationsHashtable = @{ WPFInstallGit = @{}; WPFInstallFirefox = @{} }
            }
            selectedApps = [System.Collections.Generic.List[string]]::new()
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            selectedToggles = [System.Collections.Generic.List[string]]::new()
            selectedFeatures = [System.Collections.Generic.List[string]]::new()
            selectedAppx = [System.Collections.Generic.List[string]]::new()
        })
        Mock Set-Clipboard { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "imports the exact file at <RelativePath> instead of its wildcard match" -ForEach @(
        @{ RelativePath = 'config[1].json'; DecoyPath = 'config1.json' }
        @{ RelativePath = '[backup]\config.json'; DecoyPath = 'b\config.json' }
    ) {
        $configPath = Join-Path $TestDrive $RelativePath
        $otherPath = Join-Path $TestDrive $DecoyPath
        [IO.Directory]::CreateDirectory((Split-Path $configPath)) | Out-Null
        [IO.Directory]::CreateDirectory((Split-Path $otherPath)) | Out-Null
        '"WPFInstallGit"' | Set-Content -LiteralPath $configPath
        '"WPFInstallFirefox"' | Set-Content -LiteralPath $otherPath

        Invoke-WPFImpex -type "import" -Config $configPath -ThrowOnError

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
    }

    It "exports to the exact file at <RelativePath> without overwriting its wildcard match" -ForEach @(
        @{ RelativePath = 'export[1].json'; DecoyPath = 'export1.json' }
        @{ RelativePath = '[export]\config.json'; DecoyPath = 'e\config.json' }
    ) {
        $configPath = Join-Path $TestDrive $RelativePath
        $otherPath = Join-Path $TestDrive $DecoyPath
        [IO.Directory]::CreateDirectory((Split-Path $configPath)) | Out-Null
        [IO.Directory]::CreateDirectory((Split-Path $otherPath)) | Out-Null
        '"WPFInstallFirefox"' | Set-Content -LiteralPath $otherPath
        $script:sync.selectedApps.Add("WPFInstallGit")

        Invoke-WPFImpex -type "export" -Config $configPath

        Test-Path -LiteralPath $configPath | Should -BeTrue
        Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json | Should -Be "WPFInstallGit"
        Get-Content -LiteralPath $otherPath -Raw | ConvertFrom-Json | Should -Be "WPFInstallFirefox"
    }
}
