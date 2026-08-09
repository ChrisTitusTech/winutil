#===========================================================================
# Tests - UI Helpers During Headless (-Preset / -Config) Runs
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    if (-not ("Windows.Visibility" -as [type])) {
        Add-Type @"
namespace Windows
{
    public enum Visibility
    {
        Visible,
        Collapsed
    }
}
"@
    }

    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIThread.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilTweaksProgressIndicator.ps1")

    function script:New-WinUtilFakeForm {
        $dispatcher = New-Object psobject
        $dispatcher | Add-Member -MemberType NoteProperty -Name InvokeCount -Value 0
        $dispatcher | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
            param($Action)

            $null = $Action
            $this.InvokeCount++
        }

        $form = New-Object psobject
        $form | Add-Member -MemberType NoteProperty -Name Dispatcher -Value $dispatcher
        return $form
    }

    function script:New-WinUtilFakeIndicatorControlSet {
        @{
            Bar   = [pscustomobject]@{ Visibility = [Windows.Visibility]::Collapsed }
            Label = [pscustomobject]@{ Text = "" }
            Value = [pscustomobject]@{ Value = 0 }
        }
    }
}

Describe "Invoke-WPFUIThread without a window" {
    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "does nothing when the automation paths run before the form is created" {
        $script:sync = [Hashtable]::Synchronized(@{})
        $script:blockRan = $false

        { Invoke-WPFUIThread -ScriptBlock { $script:blockRan = $true } } | Should -Not -Throw
        $script:blockRan | Should -BeFalse
    }

    It "does nothing when the form exists but has no dispatcher" {
        $script:sync = [Hashtable]::Synchronized(@{ Form = [pscustomobject]@{ Dispatcher = $null } })
        $script:blockRan = $false

        { Invoke-WPFUIThread -ScriptBlock { $script:blockRan = $true } } | Should -Not -Throw
        $script:blockRan | Should -BeFalse
    }

    It "still marshals onto the dispatcher when a window exists" {
        $form = New-WinUtilFakeForm
        $script:sync = [Hashtable]::Synchronized(@{ Form = $form })

        Invoke-WPFUIThread -ScriptBlock { }

        $form.Dispatcher.InvokeCount | Should -Be 1
    }
}

Describe "Set-WinUtilTweaksProgressIndicator without a window" {
    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "returns before resolving WPF types when the form is missing" {
        $script:sync = [Hashtable]::Synchronized(@{})

        { Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Creating restore point" -Percent 0 } | Should -Not -Throw
    }

    It "still updates the indicator controls when a window exists" {
        $controls = New-WinUtilFakeIndicatorControlSet
        $script:sync = [Hashtable]::Synchronized(@{
            Form                    = New-WinUtilFakeForm
            WPFTweaksProgressBar    = $controls.Bar
            WPFTweaksProgressLabel  = $controls.Label
            WPFTweaksProgressValue  = $controls.Value
        })

        Mock Invoke-WPFUIThread { & $ScriptBlock }

        Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Applying WPFTweaksTelemetry (1/17)" -Percent 42

        $controls.Bar.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $controls.Label.Text | Should -Be "Applying WPFTweaksTelemetry (1/17)"
        $controls.Value.Value | Should -Be 42
    }
}
