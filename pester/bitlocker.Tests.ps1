#===========================================================================
# Tests - BitLocker Disable Tweak InvokeScript
#===========================================================================
# Covers WPFTweaksDisableBitLocker (config/tweaks.json): the apply script must
# query Get-BitLockerVolume and skip Disable-BitLocker when VolumeStatus is
# FullyDecrypted. ProtectionStatus Off alone is not sufficient: an encrypted
# volume with suspended protection must still be disabled. Query and disable
# failures must propagate instead of being swallowed.

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:tweakName = "WPFTweaksDisableBitLocker"
    $tweaks = Get-Content -Path (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
    $script:invokeText = @($tweaks.$script:tweakName.InvokeScript) -join "`n"
    $script:invokeBlock = [scriptblock]::Create($script:invokeText)
    $script:undoText = @($tweaks.$script:tweakName.UndoScript) -join "`n"

    function Get-BitLockerVolume {
        [CmdletBinding()]
        param($MountPoint)
        throw "Get-BitLockerVolume must be mocked for $MountPoint."
    }
    function Disable-BitLocker {
        param($MountPoint)
        throw "Disable-BitLocker must be mocked for $MountPoint."
    }
}

Describe "WPFTweaksDisableBitLocker InvokeScript" {
    BeforeEach {
        Mock Get-BitLockerVolume { }
        Mock Disable-BitLocker { }
        Mock Write-Host { }
    }

    It "skips Disable-BitLocker and reports already-off when FullyDecrypted" {
        Mock Get-BitLockerVolume {
            [pscustomobject]@{
                MountPoint           = $Env:SystemDrive
                VolumeStatus         = "FullyDecrypted"
                ProtectionStatus     = "Off"
                EncryptionPercentage = 0
            }
        }

        & $script:invokeBlock

        Should -Invoke -CommandName Get-BitLockerVolume -Times 1 -Exactly -ParameterFilter {
            $MountPoint -eq $Env:SystemDrive
        }
        Should -Invoke -CommandName Disable-BitLocker -Times 0 -Exactly
        Should -Invoke -CommandName Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -match "already disabled"
        }
    }

    It "still disables an encrypted volume with ProtectionStatus Off" {
        Mock Get-BitLockerVolume {
            [pscustomobject]@{
                MountPoint           = $Env:SystemDrive
                VolumeStatus         = "FullyEncrypted"
                ProtectionStatus     = "Off"
                EncryptionPercentage = 100
            }
        }

        & $script:invokeBlock

        Should -Invoke -CommandName Disable-BitLocker -Times 1 -Exactly -ParameterFilter {
            $MountPoint -eq $Env:SystemDrive
        }
    }

    It "disables an encrypted volume with ProtectionStatus On" {
        Mock Get-BitLockerVolume {
            [pscustomobject]@{
                MountPoint           = $Env:SystemDrive
                VolumeStatus         = "FullyEncrypted"
                ProtectionStatus     = "On"
                EncryptionPercentage = 100
            }
        }

        & $script:invokeBlock

        Should -Invoke -CommandName Disable-BitLocker -Times 1 -Exactly -ParameterFilter {
            $MountPoint -eq $Env:SystemDrive
        }
    }

    It "propagates Get-BitLockerVolume failures without calling Disable-BitLocker" {
        Mock Get-BitLockerVolume { throw "simulated BitLocker query failure" }

        { & $script:invokeBlock } | Should -Throw -ExpectedMessage "*simulated BitLocker query failure*"
        Should -Invoke -CommandName Get-BitLockerVolume -Times 1 -Exactly -ParameterFilter { $ErrorAction -eq 'Stop' }
        Should -Invoke -CommandName Disable-BitLocker -Times 0 -Exactly
    }

    It "propagates Disable-BitLocker failures" {
        Mock Get-BitLockerVolume {
            [pscustomobject]@{
                MountPoint           = $Env:SystemDrive
                VolumeStatus         = "FullyEncrypted"
                ProtectionStatus     = "On"
                EncryptionPercentage = 100
            }
        }
        Mock Disable-BitLocker { throw "simulated BitLocker disable failure" }

        { & $script:invokeBlock } | Should -Throw -ExpectedMessage "*simulated BitLocker disable failure*"
    }

    It "preserves the Enable-BitLocker undo script" {
        $script:undoText | Should -Match 'Enable-BitLocker -MountPoint \$Env:SystemDrive'
    }
}
