#===========================================================================
# Tests - Lazy tab initialization
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")

    function Test-WinUtilUIAlive { $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher }


    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Invoke-WPFUIElements {
        param($configVariable, [string]$targetGridName, [int]$columncount)
    }
    function Initialize-WPFUI {
        param([string]$TargetGridName)
    }
    function Invoke-WinUtilISOCheckExistingWork { }
    function Initialize-WinUtilInstallTabControls { }
    function Reset-WPFCheckBoxes { param([bool]$doToggles) }

    . (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTabContent.ps1")
}

Describe "Initialize-WinUtilTabContent" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                appnavigation = [pscustomobject]@{}
                tweaks = [pscustomobject]@{}
                feature = [pscustomobject]@{}
                appx = [pscustomobject]@{}
            }
        })

        Mock Invoke-WPFUIElements { }
        Mock Initialize-WPFUI { }
        Mock Reset-WPFCheckBoxes { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "initializes the install tab once" {
        Initialize-WinUtilTabContent -TabName "Install"
        Initialize-WinUtilTabContent -TabName "Install"

        Should -Invoke -CommandName Invoke-WPFUIElements -Times 1 -Exactly -ParameterFilter {
            $targetGridName -eq "appscategory" -and $columncount -eq 1
        }
        Should -Invoke -CommandName Initialize-WPFUI -Times 1 -Exactly -ParameterFilter {
            $TargetGridName -eq "appscategory"
        }
        Should -Invoke -CommandName Initialize-WPFUI -Times 1 -Exactly -ParameterFilter {
            $TargetGridName -eq "appspanel"
        }
        $script:sync.InitializedTabs["Install"] | Should -BeTrue
    }

    It "initializes deferred config-backed tabs once" {
        Initialize-WinUtilTabContent -TabName "Tweaks"
        Initialize-WinUtilTabContent -TabName "Config"
        Initialize-WinUtilTabContent -TabName "AppX"
        Initialize-WinUtilTabContent -TabName "Tweaks"
        Initialize-WinUtilTabContent -TabName "Config"
        Initialize-WinUtilTabContent -TabName "AppX"

        Should -Invoke -CommandName Invoke-WPFUIElements -Times 1 -Exactly -ParameterFilter {
            $targetGridName -eq "tweakspanel" -and $columncount -eq 2
        }
        Should -Invoke -CommandName Invoke-WPFUIElements -Times 1 -Exactly -ParameterFilter {
            $targetGridName -eq "featurespanel" -and $columncount -eq 2
        }
        Should -Invoke -CommandName Invoke-WPFUIElements -Times 1 -Exactly -ParameterFilter {
            $targetGridName -eq "appxpanel" -and $columncount -eq 2
        }
    }

    It "re-applies checkbox selections after building a tab's controls" {
        # controls built just now start unchecked, so an import or a preset has to reach them
        Initialize-WinUtilTabContent -TabName "Tweaks"

        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 1 -Exactly -ParameterFilter {
            $doToggles -eq $true
        }
    }

    It "does not re-apply checkbox selections on a tab that is already built" {
        Initialize-WinUtilTabContent -TabName "Tweaks"
        Initialize-WinUtilTabContent -TabName "Tweaks"

        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 1 -Exactly
    }

    It "checks for existing Win11ISO work when the tab is initialized" {
        Add-Type -AssemblyName WindowsBase
        $dispatcher = [pscustomobject]@{}
        $dispatcher | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
            param($priority, $action)
            $action.Invoke()
        }
        $script:sync.Form = [pscustomobject]@{ Dispatcher = $dispatcher }
        Mock Invoke-WinUtilISOCheckExistingWork { }

        Initialize-WinUtilTabContent -TabName "Win11ISO"
        Initialize-WinUtilTabContent -TabName "Win11ISO"

        Should -Invoke -CommandName Invoke-WinUtilISOCheckExistingWork -Times 1 -Exactly
        $script:sync.InitializedTabs["Win11ISO"] | Should -BeTrue
    }
}

Describe "Startup lazy tab wiring" {
    It "builds no tab content before first paint" {
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $tabScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFTab.ps1") -Raw

        # Building a tab costs several hundred milliseconds. ContentRendered activates the
        # default tab, and activating a tab is what builds it.
        $uiScript | Should -Not -Match 'Initialize-WinUtilTabContent'
        $uiScript | Should -Match '(?s)Add_ContentRendered.*Invoke-WPFTab "WPFTab1BT"'
        $tabScript | Should -Match 'Initialize-WinUtilTabContent -TabName \$sync\.currentTab'
    }

    It "initializes tab content when a tab is selected" {
        $tabScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFTab.ps1") -Raw

        $tabScript | Should -Match 'Initialize-WinUtilTabContent -TabName \$sync\.currentTab'
    }

    It "binds generated button clicks when lazy panels are rendered" {
        $rendererScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $rendererScript | Should -Match '(?s)"Button"\s*\{.*\$button\.Add_Click\(\{.*Invoke-WPFButton \$Sender\.name'
        $rendererScript | Should -Match '\$sync\.Buttons\.Add\(\$button\.Name\)'
        $uiScript | Should -Match '\$sync\.Buttons\.Add\(\$entry\.Key\)'
    }

    It "binds generated documentation links when lazy panels are rendered" {
        $rendererScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $rendererScript | Should -Match '(?s)if \(\$entryInfo\.Link\).*\$textBlock\.Add_MouseUp\(\{.*Start-Process \$Sender\.ToolTip -ErrorAction Stop'
        $uiScript | Should -Not -Match '\.Name\.EndsWith\("Link"\)'
    }
}
