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

    function script:New-WinUtilFakeForm {
        $dispatcher = New-Object psobject
        $dispatcher | Add-Member -MemberType NoteProperty -Name InvokeCount -Value 0
        $dispatcher | Add-Member -MemberType NoteProperty -Name HasShutdownStarted -Value $false
        $dispatcher | Add-Member -MemberType ScriptMethod -Name CheckAccess -Value { return $false }
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
