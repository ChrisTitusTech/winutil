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
            Remove-Item -LiteralPath (Split-Path -Parent $path) -Force -ErrorAction SilentlyContinue
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
                Remove-Item -LiteralPath (Split-Path -Parent $second) -Force -ErrorAction SilentlyContinue
            }
        } finally {
            Remove-Item -LiteralPath $first -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Split-Path -Parent $first) -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps the commands protected after the creation handle is closed" {
        $path = New-WinUtilDiskpartScriptFile -Content 'exit'
        try {
            (Split-Path -Parent (Split-Path -Parent $path)) | Should -Be ([Environment]::GetFolderPath('CommonApplicationData'))
            $acl = Get-Acl -LiteralPath (Split-Path -Parent $path)
            $acl.AreAccessRulesProtected | Should -BeTrue
            $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
            (Get-Acl -LiteralPath $path).GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
            $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
            $rules.Count | Should -Be 2
            foreach ($rule in $rules) {
                $rule.IdentityReference.Value | Should -BeIn @('S-1-5-32-544', 'S-1-5-18')
                $rule.AccessControlType | Should -Be 'Allow'
                $rule.FileSystemRights | Should -Be 'FullControl'
            }
            [IO.File]::ReadAllText($path) | Should -Be 'exit'
        } finally {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Split-Path -Parent $path) -Force -ErrorAction SilentlyContinue
        }
    }
}
