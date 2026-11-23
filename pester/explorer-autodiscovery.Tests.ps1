# Execute the configured scripts through the real tweak orchestrator. Every registry
# cmdlet is mocked so these tests never touch the machine's Explorer view database.
BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilTweaks.ps1')
    $script:explorerTweaks = Get-Content (Join-Path $repoRoot 'config/tweaks.json') -Raw | ConvertFrom-Json
    $script:shellRoot = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell'
    $script:bagKeys = @("$script:shellRoot\Bags", "$script:shellRoot\BagMRU")
    $script:backup = "$Env:LocalAppData\winutil\FolderViews"
    function Write-WinUtilLog { param($Level, $Component, $Message) }
    function Invoke-WinUtilScript { param($Name, [scriptblock]$ScriptBlock) }
    function reg { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }
}

Describe 'Explorer automatic folder discovery apply and undo' {
    BeforeEach {
        $script:sync = @{ configs = @{ tweaks = $script:explorerTweaks } }
        $script:existingKeys = @()
        Mock Test-Path { $script:existingKeys -contains $Path }
        Mock Remove-Item { }
        Mock New-Item { }
        Mock New-ItemProperty { }
        Mock Get-ItemProperty { }
        Mock reg { $global:LASTEXITCODE = 0 }
        Mock Invoke-WinUtilScript { & $ScriptBlock }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
        Mock Write-Warning { }
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

    # Applying the tweak recreates Bags\AllFolders, so a second apply finds Bags without BagMRU.
    It 'removes Bags and skips BagMRU when only Bags exists' {
        $bags, $bagMRU = $script:bagKeys
        $script:existingKeys = @($bags)
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $Path -eq $bags -and $Recurse -and $Force }
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $Path -eq $bagMRU }
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

    It 'backs up both keys when they exist' {
        $script:existingKeys = $script:bagKeys
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        Should -Invoke reg -Times 2 -Exactly -ParameterFilter { $Arguments[0] -eq 'export' }
    }

    It 'leaves the keys alone when the backup fails' {
        $script:existingKeys = $script:bagKeys
        Mock reg { $global:LASTEXITCODE = 1 }
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        foreach ($key in $script:bagKeys) {
            Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $Path -eq $key }
        }
        Should -Invoke New-ItemProperty -Times 0 -Exactly
    }

    It 'does not back up again when the tweak is already applied' {
        $script:existingKeys = $script:bagKeys
        Mock Get-ItemProperty { [pscustomobject]@{ FolderType = 'NotSpecified' } }
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery'
        Should -Invoke reg -Times 0 -Exactly
    }

    It 'undo restores the backup and keeps it for another undo' {
        $script:existingKeys = @("$script:backup\Bags.reg", "$script:backup\BagMRU.reg")
        Invoke-WinUtilTweaks -CheckBox 'WPFTweaksDisableExplorerAutoDiscovery' -undo $true
        Should -Invoke reg -Times 2 -Exactly -ParameterFilter { $Arguments[0] -eq 'import' }
        Should -Invoke Remove-Item -Times 0 -Exactly
    }
}