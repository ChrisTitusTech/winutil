#===========================================================================
# Tests - New-WinUtilDiskpartScriptFile
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\New-WinUtilDiskpartScriptFile.ps1")
}

Describe "New-WinUtilDiskpartScriptFile" {
    It "writes the commands to a unique temporary file" {
        $path = New-WinUtilDiskpartScriptFile -Content "select disk 1`nclean`nexit"

        try {
            Test-Path -LiteralPath $path | Should -BeTrue
            [System.IO.File]::ReadAllText($path) | Should -Be "select disk 1`nclean`nexit"
        } finally {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }

    It "creates a new file on every call" {
        $first = New-WinUtilDiskpartScriptFile -Content "exit"
        try {
            $second = New-WinUtilDiskpartScriptFile -Content "exit"
            try {
                $first | Should -Not -Be $second
            } finally {
                Remove-Item -LiteralPath $second -Force -ErrorAction SilentlyContinue
            }
        } finally {
            Remove-Item -LiteralPath $first -Force -ErrorAction SilentlyContinue
        }
    }
}
