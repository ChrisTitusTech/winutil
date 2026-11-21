BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'functions/private/Set-WinUtilClassicContextMenu.ps1')
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilScript.ps1')
    . (Join-Path $repoRoot 'functions/private/Invoke-WinUtilTweaks.ps1')
    $script:classicMenuTweaks = Get-Content (Join-Path $repoRoot 'config/tweaks.json') -Raw | ConvertFrom-Json
    $script:classicMenuTweakName = 'WPFTweaksRightClickMenu'
    $script:legacyMenuPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
    $script:workaroundMenuPath = 'HKCU:\Software\Classes\CLSID\{51668040-5e31-4023-bbe3-149163bd80f1}'
    $script:workaroundServerPath = "$script:workaroundMenuPath\InprocServer32"
    [xml]$unattend = Get-Content (Join-Path $repoRoot 'tools/autounattend.xml') -Raw
    $userOnce = $unattend.SelectSingleNode("//*[local-name()='File' and @path='C:\Windows\Setup\Scripts\UserOnce.ps1']").InnerText
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($userOnce, [ref]$null, [ref]$null)
    $blocks = @($ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ScriptBlockExpressionAst] -and
            $node.ScriptBlock.Extent.Text -match '^\{\s*reg\.exe add "HKCU\\Software\\Classes\\CLSID\\\{86ca1aa0'
    }, $true))
    if ($blocks.Count -ne 1) { throw 'Expected one unattended classic menu block.' }
    $script:unattendedClassicMenu = $blocks[0].ScriptBlock.GetScriptBlock()
    function reg.exe { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }

    function Write-WinUtilLog {
        param($Level, $Component, $Message)
        if ($Level -eq 'ERROR') {
            $global:WinUtilJobErrorCount++
        }
    }

    function New-TestRegistryKey {
        param([hashtable]$Values = @{}, [string[]]$SubKeys = @())

        $key = [pscustomobject]@{ Values = $Values; SubKeys = $SubKeys }
        $key | Add-Member ScriptProperty ValueCount { $this.Values.Count }
        $key | Add-Member ScriptProperty SubKeyCount { $this.SubKeys.Count }
        $key | Add-Member ScriptMethod GetValue { param($Name) $this.Values[$Name] }
        $key | Add-Member ScriptMethod GetValueNames { @($this.Values.Keys) }
        $key | Add-Member ScriptMethod GetSubKeyNames { $this.SubKeys }
        $key | Add-Member ScriptMethod GetValueKind { [Microsoft.Win32.RegistryValueKind]::String }
        $key
    }
}

Describe 'Classic context menu apply and undo' {
    BeforeEach {
        $script:sync = @{ configs = @{ tweaks = $script:classicMenuTweaks } }
        $script:previousClassicMenuErrorCount = $global:WinUtilJobErrorCount
        $global:WinUtilJobErrorCount = 0
        $script:menuRegistry = @{}

        Mock Write-Warning {}
        Mock Stop-Process {}
        Mock Get-Process { [pscustomobject]@{ Id = 12345; SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId } }
        Mock reg.exe {}
        Mock Get-Item {
            $keyPath = [string]$LiteralPath
            if (-not $script:menuRegistry.ContainsKey($keyPath)) {
                throw [System.Management.Automation.ItemNotFoundException]::new($keyPath)
            }
            $script:menuRegistry[$keyPath]
        }
        Mock Test-Path { $script:menuRegistry.ContainsKey([string]$LiteralPath) }
        Mock New-Item {
            $keyPath = [string]$Path
            if ($keyPath -eq $script:legacyMenuPath) {
                $script:menuRegistry[$keyPath] = New-TestRegistryKey -SubKeys @('InprocServer32')
            } elseif ($keyPath -eq $script:workaroundServerPath) {
                $script:menuRegistry[$keyPath] = New-TestRegistryKey -Values @{ '' = $Value }
                $script:menuRegistry[$script:workaroundMenuPath].SubKeys = @('InprocServer32')
            } else {
                $script:menuRegistry[$keyPath] = New-TestRegistryKey
            }
            $script:menuRegistry[$keyPath]
        }
        Mock New-ItemProperty { $script:menuRegistry[[string]$LiteralPath].Values[$Name] = $Value }
        Mock Set-Item { $script:menuRegistry[[string]$LiteralPath].Values[''] = $Value }
        Mock Remove-Item {
            $keyPath = [string]$LiteralPath
            if (-not $script:menuRegistry.ContainsKey($keyPath)) {
                throw [System.Management.Automation.ItemNotFoundException]::new($keyPath)
            }
            $script:menuRegistry.Remove($keyPath)
            if ($keyPath -eq $script:workaroundMenuPath) {
                $script:menuRegistry.Remove($script:workaroundServerPath)
            }
        }
    }

    AfterEach {
        $global:WinUtilJobErrorCount = $script:previousClassicMenuErrorCount
        Remove-Variable sync -Scope Script -ErrorAction SilentlyContinue
    }

    It 'creates the newer unattended registration and preserves it on a repeated run' {
        & $script:unattendedClassicMenu
        & $script:unattendedClassicMenu
        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -BeExactly ''
        $script:menuRegistry[$script:workaroundMenuPath].Values['WinUtilClassicContextMenu'] | Should -Be 1
        Should -Invoke New-ItemProperty -Times 1 -Exactly
    }

    It 'preserves a pre-existing unattended registration' {
        $script:menuRegistry[$script:workaroundMenuPath] = New-TestRegistryKey -Values @{ Vendor = 'Custom' }
        & $script:unattendedClassicMenu
        $script:menuRegistry[$script:workaroundMenuPath].Values['Vendor'] | Should -Be 'Custom'
        Should -Invoke New-ItemProperty -Times 0 -Exactly
    }

    It 'reports an unattended marker failure without terminating user setup' {
        Mock New-ItemProperty {
            if (-not $script:allowMenuMarkerWrite) { throw 'Marker write denied' }
            $script:menuRegistry[[string]$LiteralPath].Values[$Name] = $Value
        }
        $script:allowMenuMarkerWrite = $false
        { & $script:unattendedClassicMenu } | Should -Not -Throw
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*Marker write denied*' }
        $script:menuRegistry.ContainsKey($script:workaroundMenuPath) | Should -BeFalse

        $script:allowMenuMarkerWrite = $true
        & $script:unattendedClassicMenu
        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -BeExactly ''
    }

    It 'creates the second registration once and removes both overrides on undo' {
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -BeExactly ''
        $script:menuRegistry[$script:workaroundMenuPath].Values['WinUtilClassicContextMenu'] | Should -Be 1
        Should -Invoke New-Item -Times 1 -Exactly -ParameterFilter { [string]$Path -eq $script:workaroundServerPath -and -not $Force }
        Should -Invoke New-ItemProperty -Times 1 -Exactly

        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true
        $script:menuRegistry.Count | Should -Be 0
        $global:WinUtilJobErrorCount | Should -Be 0
        Should -Invoke Stop-Process -Times 3 -Exactly -ParameterFilter { $Id -eq 12345 }
    }

    It 'leaves Explorer in other sessions running on apply and undo' {
        Mock Get-Process {
            $currentSession = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
            [pscustomobject]@{ Id = 12345; SessionId = $currentSession }
            [pscustomobject]@{ Id = 23456; SessionId = $currentSession + 1 }
        }
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true
        Should -Invoke Stop-Process -Times 2 -Exactly -ParameterFilter { $Id -eq 12345 }
        Should -Invoke Stop-Process -Times 0 -Exactly -ParameterFilter { $Id -eq 23456 -or $Name }
    }

    It 'preserves a pre-existing second registration across apply and undo' {
        $script:menuRegistry[$script:workaroundMenuPath] = New-TestRegistryKey -Values @{ Vendor = 'Custom' } -SubKeys @('InprocServer32', 'Other')
        $script:menuRegistry[$script:workaroundServerPath] = New-TestRegistryKey -Values @{ '' = 'custom.dll' }

        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true

        $script:menuRegistry[$script:workaroundMenuPath].Values['Vendor'] | Should -Be 'Custom'
        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -Be 'custom.dll'
        Should -Invoke New-ItemProperty -Times 0 -Exactly
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { [string]$LiteralPath -eq $script:workaroundMenuPath }
    }

    It 'leaves later changes to a WinUtil-owned registration intact' {
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $script:menuRegistry[$script:workaroundServerPath].Values[''] = 'custom.dll'
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true

        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -Be 'custom.dll'
        $global:WinUtilJobErrorCount | Should -Be 1
        Should -Invoke Stop-Process -Times 1 -Exactly
    }

    It 'accepts already absent keys on undo' {
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true

        $global:WinUtilJobErrorCount | Should -Be 0
        Should -Invoke Stop-Process -Times 1 -Exactly
    }

    It 'reports a denied deletion and skips the Explorer restart for the <Registration> override' -ForEach @(
        @{ Registration = 'original' }
        @{ Registration = 'newer' }
    ) {
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $script:deniedMenuPath = if ($Registration -eq 'original') { $script:legacyMenuPath } else { $script:workaroundMenuPath }
        Mock Remove-Item { throw [System.UnauthorizedAccessException]::new('Registry deletion denied') } -ParameterFilter {
            [string]$LiteralPath -eq $script:deniedMenuPath -and $ErrorAction -eq 'Stop'
        }

        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName -undo $true

        $script:menuRegistry.ContainsKey($script:deniedMenuPath) | Should -BeTrue
        $global:WinUtilJobErrorCount | Should -Be 1
        Should -Invoke Stop-Process -Times 1 -Exactly
    }

    It 'completes an empty owned server key after a partial creation failure' {
        Mock New-Item {
            $script:menuRegistry[$script:workaroundServerPath] = New-TestRegistryKey
            $script:menuRegistry[$script:workaroundMenuPath].SubKeys = @('InprocServer32')
            throw [System.UnauthorizedAccessException]::new('Default value creation denied')
        } -ParameterFilter { [string]$Path -eq $script:workaroundServerPath }

        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $global:WinUtilJobErrorCount | Should -Be 1
        $script:menuRegistry[$script:workaroundServerPath].ValueCount | Should -Be 0

        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $script:menuRegistry[$script:workaroundServerPath].Values.ContainsKey('') | Should -BeTrue
        $script:menuRegistry[$script:workaroundServerPath].Values[''] | Should -BeExactly ''
        Should -Invoke Stop-Process -Times 1 -Exactly
    }

    It 'retries a failed server creation without overwriting the owned root' {
        Mock New-Item { throw [System.UnauthorizedAccessException]::new('Registry creation denied') } -ParameterFilter {
            [string]$Path -eq $script:workaroundServerPath -and -not $script:menuCreationAllowed
        }
        $script:menuCreationAllowed = $false
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $global:WinUtilJobErrorCount | Should -Be 1
        $script:menuRegistry.ContainsKey($script:workaroundServerPath) | Should -BeFalse

        $script:menuCreationAllowed = $true
        Invoke-WinUtilTweaks -CheckBox $script:classicMenuTweakName
        $script:menuRegistry.ContainsKey($script:workaroundServerPath) | Should -BeTrue
        $global:WinUtilJobErrorCount | Should -Be 1
        Should -Invoke New-ItemProperty -Times 1 -Exactly
        Should -Invoke Stop-Process -Times 1 -Exactly
    }
}
