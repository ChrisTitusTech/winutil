BeforeAll {
    $tweaks = Get-Content (Join-Path $PSScriptRoot '..\config\tweaks.json') -Raw | ConvertFrom-Json
    $script:removeEdge = [scriptblock]::Create($tweaks.WPFTweaksRemoveEdge.InvokeScript -join "`n")
    $script:edgeDirectory = "$Env:ProgramFiles (x86)\Microsoft\Edge\Application"
    $script:installerPattern = Join-Path $script:edgeDirectory '*\Installer\setup.exe'
    $script:installerPath = Join-Path $script:edgeDirectory '123\Installer\setup.exe'
}

Describe 'Edge removal' {
    BeforeEach {
        Mock Test-Path { $true }
        Mock Resolve-Path { $script:installerPath }
        Mock New-Item { }
        Mock Start-Process { }
        Mock Write-Host { }
    }

    It 'skips an absent application directory without resolving an installer' {
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -eq $script:edgeDirectory }

        & $script:removeEdge

        Should -Invoke Resolve-Path -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Microsoft Edge is not installed' }
    }

    It 'skips a directory with no matching installer' {
        Mock Test-Path { $false } -ParameterFilter { $Path -eq $script:installerPattern }

        & $script:removeEdge

        Should -Invoke Resolve-Path -Times 0 -Exactly
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Microsoft Edge is not installed' }
    }

    It 'uses the last resolved installer with the existing uninstall arguments' {
        Mock Resolve-Path {
            'C:\earlier\setup.exe'
            $script:installerPath
        }

        & $script:removeEdge

        Should -Invoke New-Item -Times 1 -Exactly -ParameterFilter {
            $Path -eq "$Env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -and $Force
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $script:installerPath -and $Wait -and
            $ArgumentList -eq '--uninstall --system-level --force-uninstall --delete-profile'
        }
    }

    It 'keeps directory lookup errors visible' {
        Mock Test-Path { throw 'Access denied' }

        { & $script:removeEdge } | Should -Throw '*Access denied*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'keeps installer resolution failures visible' {
        Mock Resolve-Path { throw 'Installer resolution failed' }

        { & $script:removeEdge } | Should -Throw '*Installer resolution failed*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'does not report successful removal when launching the uninstaller fails' {
        Mock Start-Process { throw 'Uninstaller launch failed' }

        { & $script:removeEdge } | Should -Throw '*Uninstaller launch failed*'
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -eq 'Microsoft Edge was removed' }
    }
}
