BeforeAll {
    $tweaks = Get-Content (Join-Path $PSScriptRoot '..\config\tweaks.json') -Raw | ConvertFrom-Json
    $invokeText = $tweaks.WPFTweaksRemoveOneDrive.InvokeScript -join "`n"
    # Intercept the persistent environment write; filesystem fixtures stay in TestDrive.
    $invokeText = $invokeText.Replace("[Environment]::SetEnvironmentVariable('OneDrive', `$null, 'User')", 'Clear-TestOneDriveEnvironment')
    $script:removeOneDrive = [scriptblock]::Create($invokeText)
    function icacls {
        param($Target, $Operation, $Principal)
        throw "icacls must be mocked: $Target $Operation $Principal"
    }
    function Clear-TestOneDriveEnvironment {
        throw 'The persistent environment write must be mocked.'
    }
}

Describe 'OneDrive removal' {
    BeforeEach {
        $script:savedOneDrive = $Env:OneDrive
        $script:savedLocalAppData = $Env:LocalAppData
        $script:savedProgramData = $Env:ProgramData
        $script:savedExitCode = $global:LASTEXITCODE
        $script:fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:oneDrivePath = Join-Path $script:fixtureRoot 'OneDrive'
        $Env:OneDrive = $script:oneDrivePath
        $Env:LocalAppData = Join-Path $script:fixtureRoot 'LocalAppData'
        $Env:ProgramData = Join-Path $script:fixtureRoot 'ProgramData'
        $script:aclOperations = [System.Collections.Generic.List[string]]::new()
        $script:originalAcl = [System.Security.AccessControl.DirectorySecurity]::new()
        Mock Get-Acl { $script:originalAcl }
        Mock Set-Acl { $script:aclOperations.Add('restore') }
        Mock icacls {
            $script:aclOperations.Add($Operation)
            $global:LASTEXITCODE = 0
        }
        Mock Start-Process { }
        Mock Get-Process { }
        Mock Stop-Process { }
        Mock Set-Service { }
        Mock Remove-Item { }
        Mock Clear-TestOneDriveEnvironment { }
        Mock Write-Host { }
    }

    AfterEach {
        $Env:OneDrive = $script:savedOneDrive
        $Env:LocalAppData = $script:savedLocalAppData
        $Env:ProgramData = $script:savedProgramData
        $global:LASTEXITCODE = $script:savedExitCode
    }

    It 'skips an empty or absent folder path but still uninstalls' -TestCases @(
        @{ EmptyPath = $true }, @{ EmptyPath = $false }
    ) {
        param($EmptyPath)
        if ($EmptyPath) { $Env:OneDrive = '' }
        & $script:removeOneDrive
        Should -Invoke icacls -Times 0 -Exactly
        Should -Invoke Get-Acl -Times 0 -Exactly
        Should -Invoke Set-Acl -Times 0 -Exactly
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
        Should -Invoke Remove-Item -Times 0 -Exactly
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $ArgumentList -eq '/uninstall' -and $Wait }
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'OneSyncSvc' -and $StartupType -eq 'Disabled' }
        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $Name -eq 'Explorer' }
    }

    It 'protects an existing folder during uninstall and deletes it only when empty' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock Start-Process { $script:aclOperations.ToArray() | Should -Be @('/deny') }
        & $script:removeOneDrive
        $script:aclOperations.ToArray() | Should -Be @('/deny', 'restore')
        Should -Invoke Set-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:oneDrivePath -and $AclObject -eq $script:originalAcl }
        Test-Path -LiteralPath $script:oneDrivePath | Should -BeFalse
        Should -Invoke Clear-TestOneDriveEnvironment -Times 1 -Exactly
    }

    It 'preserves a OneDrive folder containing only hidden files' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        $hiddenFile = New-Item -ItemType File -Path (Join-Path $script:oneDrivePath 'notes.txt')
        $hiddenFile.Attributes = $hiddenFile.Attributes -bor [System.IO.FileAttributes]::Hidden
        & $script:removeOneDrive
        Test-Path -LiteralPath $hiddenFile.FullName | Should -BeTrue
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }

    It 'refuses to delete files added after the emptiness check' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock Get-ChildItem {
            New-Item -ItemType File -Path (Join-Path $script:oneDrivePath 'new-file.txt') | Out-Null
        } -ParameterFilter { $LiteralPath -eq $script:oneDrivePath }
        { & $script:removeOneDrive } | Should -Throw
        Test-Path -LiteralPath (Join-Path $script:oneDrivePath 'new-file.txt') | Should -BeTrue
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }

    It 'stops only a running FileCoAuth process and still stops Explorer' {
        $script:fileCoAuth = [System.Diagnostics.Process]::new()
        $script:fileCoAuth | Add-Member -MemberType NoteProperty -Name ProcessName -Value 'FileCoAuth' -Force
        Mock Get-Process { $script:fileCoAuth }
        & $script:removeOneDrive
        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $InputObject -eq $script:fileCoAuth }
        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $Name -eq 'Explorer' }
    }

    It 'cleans up only optional directories that exist' {
        $leftoverPath = Join-Path $Env:LocalAppData 'Microsoft\OneDrive'
        New-Item -ItemType Directory -Path $leftoverPath -Force | Out-Null
        & $script:removeOneDrive
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $leftoverPath -and $Recurse -and $Force }
    }

    It 'restores permissions and reports a failed uninstall' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock Start-Process { throw 'Uninstaller failed' }
        { & $script:removeOneDrive } | Should -Throw '*Uninstaller failed*'
        $script:aclOperations.ToArray() | Should -Be @('/deny', 'restore')
        Test-Path -LiteralPath $script:oneDrivePath | Should -BeTrue
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }

    It 'restores permissions and reports a leftover cleanup error' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Env:LocalAppData 'Microsoft\OneDrive') -Force | Out-Null
        Mock Remove-Item { throw 'Cleanup access denied' }
        { & $script:removeOneDrive } | Should -Throw '*Cleanup access denied*'
        $script:aclOperations.ToArray() | Should -Be @('/deny', 'restore')
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }

    It 'reports an ACL failure before attempting uninstall' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock icacls { $global:LASTEXITCODE = 5 }
        { & $script:removeOneDrive } | Should -Throw '*Unable to protect*'
        Should -Invoke Set-Acl -Times 1 -Exactly
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'reports a permission restoration failure and keeps the folder' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock Set-Acl { throw 'ACL restoration failed' }
        { & $script:removeOneDrive } | Should -Throw '*ACL restoration failed*'
        Test-Path -LiteralPath $script:oneDrivePath | Should -BeTrue
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }

    It 'does not interpret a failed folder enumeration as an empty folder' {
        New-Item -ItemType Directory -Path $script:oneDrivePath -Force | Out-Null
        Mock Get-ChildItem { throw 'Enumeration access denied' } -ParameterFilter { $LiteralPath -eq $script:oneDrivePath }
        { & $script:removeOneDrive } | Should -Throw '*Enumeration access denied*'
        Test-Path -LiteralPath $script:oneDrivePath | Should -BeTrue
        Should -Invoke Clear-TestOneDriveEnvironment -Times 0 -Exactly
    }
}
