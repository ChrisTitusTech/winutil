# Execute the configured scripts through the real tweak orchestrator. Every registry
# cmdlet is mocked so these tests never touch the machine's Explorer view database.
BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilTweaks.ps1')
    $script:explorerTweaks = Get-Content (Join-Path $repoRoot 'config/tweaks.json') -Raw | ConvertFrom-Json
    $script:shellRoot = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell'
    $script:bagKeys = @("$script:shellRoot\Bags", "$script:shellRoot\BagMRU")
    function Write-WinUtilLog { param($Level, $Component, $Message) }
    function Invoke-WinUtilScript { param($Name, [scriptblock]$ScriptBlock) }
}

Describe 'Explorer automatic folder discovery apply and undo' {
    BeforeEach {
        $script:sync = @{ configs = @{ tweaks = $script:explorerTweaks } }
        $script:existingKeys = @()
        Mock Test-Path { $script:existingKeys -contains $Path }
        Mock Remove-Item { }
        Mock New-Item { }
        Mock New-ItemProperty { }
        Mock Invoke-WinUtilScript { & $ScriptBlock }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable sync -Scope Script -ErrorAction SilentlyContinue
    }

    It 'flushes both view database keys when they exist' {
        $script:existingKeys = $script:bagKeys
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        foreach ($key in $script:bagKeys) {
            Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $Path -eq $key -and $Recurse -and $Force }
        }
    }

    It 'skips the removal when Explorer has not created the keys yet' {
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        Should -Invoke Remove-Item -Times 0 -Exactly
    }

    It 'still creates AllFolders and sets the generic view when the keys are missing' {
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        Should -Invoke New-Item -Times 1 -Exactly -ParameterFilter { $Path -eq "$script:shellRoot\Bags\AllFolders\Shell" }
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'FolderType' -and $Value -eq 'NotSpecified' }
    }

    It 'undo flushes both keys when they exist and skips them when they are missing' {
        $script:existingKeys = $script:bagKeys
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery' -undo $true
        Should -Invoke Remove-Item -Times 2 -Exactly

        $script:existingKeys = @()
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery' -undo $true
        Should -Invoke Remove-Item -Times 2 -Exactly
    }
}
