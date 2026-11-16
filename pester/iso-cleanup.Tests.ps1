BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Get-WinUtilISOCleanupTree.ps1')
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilISO.ps1')
    function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) 'Yes' }
    function Start-WinUtilJob { param($Name, $Description, $Parameters, $ScriptBlock) & $ScriptBlock @Parameters }
    function Invoke-WPFUIThread { param($ScriptBlock) }
    function Set-WinUtilISOStep { param($Step, $Label, [switch]$Reverse) }
    function Step-WinUtilJob { param($Status, $Percent, [switch]$Hide) }
    function Write-WinUtilISOLog { param($Message, $Level) }
    function Get-WindowsImage { param([switch]$Mounted) }
}

Describe 'ISO cleanup path confinement' {
    BeforeEach {
        $script:savedTemp = $env:TEMP
        $env:TEMP = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:workDir = Join-Path $env:TEMP 'WinUtil_Win11ISO_cleanup'
        $script:child = Join-Path $script:workDir 'iso_contents'
        New-Item -ItemType Directory -Path $script:child -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:child 'inside.txt') -Value 'temporary'
        $script:outside = Join-Path $env:TEMP 'outside'
        New-Item -ItemType Directory -Path $script:outside | Out-Null
        Set-Content -LiteralPath (Join-Path $script:outside 'keep.txt') -Value 'keep me'
        $script:sync = @{ Win11ISOWorkDir = $script:workDir }
    }

    AfterEach {
        foreach ($path in @((Join-Path $script:workDir 'linked'), $script:workDir)) {
            if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                [IO.Directory]::Delete($path, $false)
            }
        }
        $env:TEMP = $script:savedTemp
        Remove-Variable sync -Scope Script
    }

    It 'deletes ordinary work while preserving files outside it' {
        Invoke-WinUtilISOCleanAndReset
        Test-Path -LiteralPath $script:workDir | Should -BeFalse
        Get-Content -LiteralPath (Join-Path $script:outside 'keep.txt') | Should -Be 'keep me'
    }

    It 'rejects a root replaced by a junction after discovery' {
        Remove-Item -LiteralPath (Join-Path $script:child 'inside.txt')
        [IO.Directory]::Delete($script:child, $false)
        [IO.Directory]::Delete($script:workDir, $false)
        New-Item -ItemType Junction -Path $script:workDir -Target $script:outside | Out-Null

        { Invoke-WinUtilISOCleanAndReset } | Should -Throw '*reparse point*'
        Get-Content -LiteralPath (Join-Path $script:outside 'keep.txt') | Should -Be 'keep me'
    }

    It 'refuses a descendant junction before deleting any files' {
        New-Item -ItemType Junction -Path (Join-Path $script:workDir 'linked') -Target $script:outside | Out-Null
        { Invoke-WinUtilISOCleanAndReset } | Should -Throw '*reparse point*'
        Test-Path -LiteralPath (Join-Path $script:child 'inside.txt') | Should -BeTrue
        Get-Content -LiteralPath (Join-Path $script:outside 'keep.txt') | Should -Be 'keep me'
    }

    It 'prevents the scanned root and descendant directories from being replaced' {
        $tree = Get-WinUtilISOCleanupTree -WorkDir $script:workDir
        try {
            { Move-Item -LiteralPath $script:workDir -Destination ($script:workDir + '_moved') -ErrorAction Stop } | Should -Throw
            { Move-Item -LiteralPath $script:child -Destination ($script:child + '_moved') -ErrorAction Stop } | Should -Throw
        } finally {
            foreach ($handle in $tree.Locks.Values) { $handle.Dispose() }
        }
    }

    It 'refuses a stored path outside the WinUtil TEMP directory convention' {
        { Get-WinUtilISOCleanupTree -WorkDir $script:outside } | Should -Throw '*outside a WinUtil working directory*'
        $script:sync.Win11ISOWorkDir = $script:outside
        Mock Get-WindowsImage {}
        { Invoke-WinUtilISOCleanAndReset } | Should -Throw '*outside a WinUtil working directory*'
        Should -Invoke Get-WindowsImage -Times 0 -Exactly
        Get-Content -LiteralPath (Join-Path $script:outside 'keep.txt') | Should -Be 'keep me'
    }

    It 'accepts equivalent short and long work-directory spellings with a short TEMP path' {
        $longTemp = (New-Item -ItemType Directory -Path (Join-Path $env:TEMP 'Long TEMP directory for cleanup validation')).FullName
        $fileSystem = New-Object -ComObject Scripting.FileSystemObject
        $folder = $null
        try {
            $folder = $fileSystem.GetFolder($longTemp)
            $shortTemp = $folder.ShortPath
        } finally {
            if ($null -ne $folder) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($folder) }
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($fileSystem)
        }
        if ([string]::Equals($shortTemp, $longTemp, [StringComparison]::OrdinalIgnoreCase)) {
            Set-ItResult -Skipped -Because 'The test volume does not provide an 8.3 spelling for this directory.'
            return
        }

        $workName = 'WinUtil_Win11ISO_short_path'
        $longWorkDir = (New-Item -ItemType Directory -Path (Join-Path $longTemp $workName)).FullName
        $env:TEMP = $shortTemp
        { Assert-WinUtilISOCleanupRoot -WorkDir (Join-Path $shortTemp $workName) } | Should -Not -Throw
        { Assert-WinUtilISOCleanupRoot -WorkDir $longWorkDir } | Should -Not -Throw
    }
}
