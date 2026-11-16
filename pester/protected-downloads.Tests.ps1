BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $script:downloadTestName = 'WinUtilDownloadTest_' + [guid]::NewGuid().ToString('N')
    $script:downloadTestRoot = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) $script:downloadTestName
    $source = Get-Content (Join-Path $repoRoot 'functions/private/Get-WinUtilProtectedDownloadPath.ps1') -Raw
    # Keep the real Windows ACL APIs and trusted parent, but isolate every test from the cache.
    . ([scriptblock]::Create($source.Replace("'WinUtilDownloads'", "'$script:downloadTestName'")))
}

Describe 'Protected executable storage' {
    AfterEach {
        foreach ($name in 'ooshutup10.exe', 'autologin.exe') {
            $path = Join-Path $script:downloadTestRoot $name
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
        if (Test-Path -LiteralPath $script:downloadTestRoot) { [IO.Directory]::Delete($script:downloadTestRoot, $false) }
    }

    It 'creates an administrator-owned file and reuses it without truncating it' {
        $path = Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe
        [IO.File]::WriteAllText($path, 'cached executable')
        Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe | Should -Be $path
        [IO.File]::ReadAllText($path) | Should -Be 'cached executable'
        foreach ($protectedPath in $path, $script:downloadTestRoot) {
            $acl = Get-Acl -LiteralPath $protectedPath
            $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
            $acl.AreAccessRulesProtected | Should -BeTrue
            $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
            $rules.Count | Should -Be 2
            $rules.IdentityReference.Value | Should -Contain 'S-1-5-18'
            $rules.IdentityReference.Value | Should -Contain 'S-1-5-32-544'
        }
    }

    It 'refuses a pre-existing unprotected cache directory' {
        New-Item -ItemType Directory -Path $script:downloadTestRoot | Out-Null
        { Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe } | Should -Throw '*unprotected executable storage*'
    }

    It 'refuses an executable that grants ordinary users write access' {
        $path = Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe
        $acl = Get-Acl -LiteralPath $path
        $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'), 'Write', 'Allow'))
        Set-Acl -LiteralPath $path -AclObject $acl
        { Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe } | Should -Throw '*unprotected executable storage*'
    }

    It 'refuses a symbolic link without changing its target' {
        Get-WinUtilProtectedDownloadPath -Name autologin.exe | Out-Null
        $outside = Join-Path $TestDrive 'outside.exe'
        [IO.File]::WriteAllText($outside, 'keep me')
        New-Item -ItemType SymbolicLink -Path (Join-Path $script:downloadTestRoot 'ooshutup10.exe') -Target $outside | Out-Null
        { Get-WinUtilProtectedDownloadPath -Name ooshutup10.exe } | Should -Throw '*unprotected executable storage*'
        [IO.File]::ReadAllText($outside) | Should -Be 'keep me'
    }
}
