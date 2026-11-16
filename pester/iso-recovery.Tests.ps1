BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilISO.ps1')
    function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) }
    function Set-WinUtilISOStep { param($Step) }
    function Write-WinUtilISOLog { param($Message, $Level) }
}

Describe 'ISO work-directory adoption' {
    BeforeEach {
        $script:savedTemp = $env:TEMP
        $env:TEMP = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $env:TEMP | Out-Null
        $script:sync = @{}
        $script:workDir = Join-Path $env:TEMP 'WinUtil_Win11ISO_recovery'
        New-Item -ItemType Directory -Path (Join-Path $script:workDir 'iso_contents') -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $script:workDir '.winutil-created') | Out-Null
        Mock Set-WinUtilISOStep {}
        Mock Write-WinUtilISOLog {}
        Mock Show-WinUtilMessage { 'No' }
    }

    AfterEach {
        $env:TEMP = $script:savedTemp
        Remove-Variable sync -Scope Script
    }

    It 'does not adopt marked work when the user declines' {
        Invoke-WinUtilISOCheckExistingWork
        $script:sync.Win11ISOContentsDir | Should -BeNullOrEmpty
        Should -Invoke Set-WinUtilISOStep -Times 0 -Exactly
        Should -Invoke Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter { $Button -eq 'YesNo' -and $Message -like '*marker alone cannot verify*' }
    }

    It 'restores the output step only after consent' {
        Mock Show-WinUtilMessage { 'Yes' }
        Invoke-WinUtilISOCheckExistingWork
        $script:sync.Win11ISOWorkDir | Should -Be $script:workDir
        Should -Invoke Set-WinUtilISOStep -Times 1 -Exactly -ParameterFilter { $Step -eq 'Output' }
    }
}
