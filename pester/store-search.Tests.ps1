# Run the configured scripts with the real icacls against a throwaway profile folder and read
# the resulting permissions. $Env:LocalAppData points at TestDrive for every test, so nothing
# here touches the real Microsoft Store data.
BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $tweak = (Get-Content (Join-Path $repoRoot 'config/tweaks.json') -Raw | ConvertFrom-Json).WPFTweaksDisableStoreSearch
    $script:applyStoreSearch = [scriptblock]::Create($tweak.InvokeScript -join "`n")
    $script:undoStoreSearch = [scriptblock]::Create($tweak.UndoScript -join "`n")

    function Initialize-TestStoreData {
        param([string[]]$Catalog)

        New-Item -Path (Join-Path $script:localState 'JumpListIcons') -ItemType Directory -Force | Out-Null
        foreach ($name in $Catalog) {
            Set-Content -LiteralPath (Join-Path $script:localState $name) -Value 'catalog'
        }
    }

    function Get-TestDacl {
        param([string]$Path)

        # Read the rules through icacls /save: Get-Acl folds identical rules into one, which hides
        # stacked deny entries. The flags between "D:" and the first rule are dropped, because
        # icacls marks every DACL it writes as auto-inherited and that says nothing about access.
        $saved = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        icacls $Path /save $saved | Out-Null
        $sddl = @(Get-Content -LiteralPath $saved -Encoding Unicode)[-1]
        $sddl.Substring($sddl.IndexOf('('))
    }

    function Get-TestDenyRuleCount {
        param([string]$Path)

        ([regex]::Matches((Get-TestDacl -Path $Path), '\(D;')).Count
    }

    function Get-TestErrorRecord {
        param([scriptblock]$Script)

        @(& $Script 2>&1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
    }
}

Describe 'Microsoft Store search results tweak' {
    BeforeEach {
        $script:originalLocalAppData = $Env:LocalAppData
        $script:profileRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $Env:LocalAppData = $script:profileRoot
        $script:localState = Join-Path $script:profileRoot 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState'
        $script:activeCatalog = Join-Path $script:localState 'store.db'
        $script:pendingCatalog = Join-Path $script:localState 'store-0f3c2a9e-6b1d-4c57-9a43-2e8f5d7b1c60.db'
    }

    AfterEach {
        $Env:LocalAppData = $script:originalLocalAppData

        # Lift every deny rule so Pester can delete TestDrive, whatever the script under test did.
        if (Test-Path -LiteralPath $script:profileRoot) {
            icacls $script:profileRoot /remove:d '*S-1-1-0' /T /C /Q | Out-Null
        }
    }

    It 'blocks every catalog file, not only store.db' {
        Initialize-TestStoreData -Catalog 'store.db', 'store-0f3c2a9e-6b1d-4c57-9a43-2e8f5d7b1c60.db'

        & $script:applyStoreSearch | Out-Null

        { [System.IO.File]::ReadAllBytes($script:activeCatalog) } | Should -Throw
        { [System.IO.File]::ReadAllBytes($script:pendingCatalog) } | Should -Throw
    }

    It 'applies without an error when store.db was never created' {
        Initialize-TestStoreData -Catalog 'store-0f3c2a9e-6b1d-4c57-9a43-2e8f5d7b1c60.db'

        $errors = Get-TestErrorRecord -Script $script:applyStoreSearch

        $errors | Should -BeNullOrEmpty
    }

    It 'stops a new catalog file from being created' {
        Initialize-TestStoreData -Catalog 'store.db'

        & $script:applyStoreSearch | Out-Null

        { New-Item -Path (Join-Path $script:localState 'store-new.db') -ItemType File -ErrorAction Stop } | Should -Throw
    }

    It 'leaves the subfolders of the data folder writable' {
        Initialize-TestStoreData -Catalog 'store.db'

        & $script:applyStoreSearch | Out-Null

        $icon = Join-Path $script:localState 'JumpListIcons\icon.png'
        New-Item -Path $icon -ItemType File -ErrorAction Stop | Out-Null
        Test-Path -LiteralPath $icon | Should -BeTrue
    }

    It 'keeps one deny rule per target when applied twice' {
        Initialize-TestStoreData -Catalog 'store.db'

        & $script:applyStoreSearch | Out-Null
        & $script:applyStoreSearch | Out-Null

        Get-TestDenyRuleCount -Path $script:activeCatalog | Should -Be 1
        Get-TestDenyRuleCount -Path $script:localState | Should -Be 1
    }

    It 'restores the original permissions on undo' {
        Initialize-TestStoreData -Catalog 'store.db', 'store-0f3c2a9e-6b1d-4c57-9a43-2e8f5d7b1c60.db'
        $folderBefore = Get-TestDacl -Path $script:localState
        $activeBefore = Get-TestDacl -Path $script:activeCatalog
        $pendingBefore = Get-TestDacl -Path $script:pendingCatalog

        & $script:applyStoreSearch | Out-Null
        & $script:undoStoreSearch | Out-Null

        Get-TestDacl -Path $script:localState | Should -Be $folderBefore
        Get-TestDacl -Path $script:activeCatalog | Should -Be $activeBefore
        Get-TestDacl -Path $script:pendingCatalog | Should -Be $pendingBefore
    }

    It 'leaves the permissions alone when undo runs without a prior apply' {
        Initialize-TestStoreData -Catalog 'store.db'
        $folderBefore = Get-TestDacl -Path $script:localState
        $activeBefore = Get-TestDacl -Path $script:activeCatalog

        $errors = Get-TestErrorRecord -Script $script:undoStoreSearch

        $errors | Should -BeNullOrEmpty
        Get-TestDacl -Path $script:localState | Should -Be $folderBefore
        Get-TestDacl -Path $script:activeCatalog | Should -Be $activeBefore
    }

    It 'does nothing on <Action> when the Store data folder is missing' -TestCases @(
        @{ Action = 'apply' }
        @{ Action = 'undo' }
    ) {
        param([string]$Action)

        $script = if ($Action -eq 'apply') { $script:applyStoreSearch } else { $script:undoStoreSearch }

        $errors = Get-TestErrorRecord -Script $script

        $errors | Should -BeNullOrEmpty
        Test-Path -LiteralPath $script:profileRoot | Should -BeFalse
    }

    It 'fails the <Action> script when icacls reports an error' -TestCases @(
        @{ Action = 'apply' }
        @{ Action = 'undo' }
    ) {
        param([string]$Action)

        Initialize-TestStoreData -Catalog 'store.db'
        $script = if ($Action -eq 'apply') { $script:applyStoreSearch } else { $script:undoStoreSearch }
        Mock icacls { $global:LASTEXITCODE = 5 }

        { & $script } | Should -Throw '*exit code 5*'
    }
}
