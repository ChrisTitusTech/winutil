#===========================================================================
# Tests - Progress bar reflects how a run ended
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    . (Join-Path $script:repoRoot "functions\private\Step-WinUtilJob.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilWorkingView.ps1")

    function Test-WinUtilUIAlive { return $true }
    function Write-WinUtilConsoleProgress { param([string]$Status, [int]$Percent) }
    function Write-WinUtilLog { param($Message, $Level, $Component) }
    function Set-WinUtilTaskbaritem { param($state, $overlay, $value) }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock, [hashtable]$Parameters, [switch]$Async, [switch]$PassThru)
        & $ScriptBlock @Parameters
    }

    function script:New-ProgressFixture {
        $bar = New-Object System.Windows.Controls.ProgressBar
        # the brushes the job layer points the fill at, resolvable from the control itself
        $bar.Resources.Add("ProgressBarForegroundColor", [System.Windows.Media.Brushes]::LimeGreen)
        $bar.Resources.Add("ProgressBarErrorColor", [System.Windows.Media.Brushes]::Red)
        $bar.Resources.Add("ProgressBarWarningColor", [System.Windows.Media.Brushes]::Orange)

        $global:sync = [hashtable]::Synchronized(@{
            WPFTweaksProgressBar   = (New-Object System.Windows.Controls.Border)
            WPFTweaksProgressLabel = (New-Object System.Windows.Controls.TextBlock)
            WPFTweaksProgressValue = $bar
            Form = [pscustomobject]@{ TaskbarItemInfo = [pscustomobject]@{ ProgressValue = 0 } }
        })
        return $bar
    }
}

Describe "Step-WinUtilJob progress colour" {
    It "fills green while a run is going normally" {
        $bar = New-ProgressFixture

        Step-WinUtilJob -Status "working" -Percent 40 -State "Normal"

        $bar.Foreground | Should -Be ([System.Windows.Media.Brushes]::LimeGreen)
    }

    It "turns the bar red when a run failed" {
        $bar = New-ProgressFixture

        Step-WinUtilJob -Status "Tweaks failed" -Percent 100 -State "Error"

        $bar.Foreground | Should -Be ([System.Windows.Media.Brushes]::Red)
    }

    It "warns rather than reporting success when a run finished with errors" {
        $bar = New-ProgressFixture

        # this is the case that read as a clean finish: full bar, normal colour
        Step-WinUtilJob -Status "Tweaks finished with 2 error(s)" -Percent 100 -State "Paused"

        $bar.Foreground | Should -Be ([System.Windows.Media.Brushes]::Orange)
        $bar.Foreground | Should -Not -Be ([System.Windows.Media.Brushes]::LimeGreen)
    }

    It "goes back to the normal colour when the next run starts" {
        $bar = New-ProgressFixture

        Step-WinUtilJob -Status "Tweaks failed" -Percent 100 -State "Error"
        Step-WinUtilJob -Status "starting" -Percent 0 -State "Normal"

        $bar.Foreground | Should -Be ([System.Windows.Media.Brushes]::LimeGreen)
    }

    It "mirrors the status into each visible working label" {
        $null = New-ProgressFixture
        $global:sync["WPFInstallWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFInstallWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFTweaksWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFTweaksWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFInstallWorkingPanel"].Visibility = [System.Windows.Visibility]::Visible
        $global:sync["WPFTweaksWorkingPanel"].Visibility = [System.Windows.Visibility]::Visible

        Step-WinUtilJob -Status "Installing vlc (2/7)" -Percent 20

        $global:sync["WPFInstallWorkingLabel"].Text | Should -Be "Installing vlc (2/7)"
        $global:sync["WPFTweaksWorkingLabel"].Text | Should -Be "Installing vlc (2/7)"
    }

    It "leaves hidden working labels alone" {
        $null = New-ProgressFixture
        $global:sync["WPFInstallWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFInstallWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFTweaksWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFTweaksWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFInstallWorkingPanel"].Visibility = [System.Windows.Visibility]::Collapsed
        $global:sync["WPFTweaksWorkingPanel"].Visibility = [System.Windows.Visibility]::Collapsed
        $global:sync["WPFInstallWorkingLabel"].Text = "Installing..."
        $global:sync["WPFTweaksWorkingLabel"].Text = "Applying tweaks..."

        Step-WinUtilJob -Status "Installing vlc (2/7)" -Percent 20

        $global:sync["WPFInstallWorkingLabel"].Text | Should -Be "Installing..."
        $global:sync["WPFTweaksWorkingLabel"].Text | Should -Be "Applying tweaks..."
    }

    It "swaps the app list for the working view and back" {
        $null = New-ProgressFixture
        $global:sync["WPFInstallWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFInstallContentGrid"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFSearchChips"] = New-Object System.Windows.Controls.WrapPanel
        $global:sync["WPFInstallWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFInstallWorkingPanel"].Visibility = [System.Windows.Visibility]::Collapsed

        Set-WinUtilWorkingView -Area "Install" -Working $true -Label "Installing apps..."

        $global:sync["WPFInstallWorkingPanel"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
        $global:sync["WPFInstallContentGrid"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFSearchChips"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFInstallWorkingLabel"].Text | Should -Be "Installing apps..."

        Set-WinUtilWorkingView -Area "Install" -Working $false

        $global:sync["WPFInstallWorkingPanel"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFInstallContentGrid"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
        $global:sync["WPFSearchChips"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
    }

    It "swaps the tweaks list and action bar for the working view and back" {
        $null = New-ProgressFixture
        $global:sync["WPFTweaksWorkingPanel"] = New-Object System.Windows.Controls.Grid
        $global:sync["WPFTweaksContentScroll"] = New-Object System.Windows.Controls.ScrollViewer
        $global:sync["WPFTweaksActionBar"] = New-Object System.Windows.Controls.Border
        $global:sync["WPFTweaksWorkingLabel"] = New-Object System.Windows.Controls.TextBlock
        $global:sync["WPFTweaksWorkingPanel"].Visibility = [System.Windows.Visibility]::Collapsed

        Set-WinUtilWorkingView -Area "Tweaks" -Working $true -Label "Applying tweaks..."

        $global:sync["WPFTweaksWorkingPanel"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
        $global:sync["WPFTweaksContentScroll"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFTweaksActionBar"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFTweaksWorkingLabel"].Text | Should -Be "Applying tweaks..."

        Set-WinUtilWorkingView -Area "Tweaks" -Working $false

        $global:sync["WPFTweaksWorkingPanel"].Visibility | Should -Be ([System.Windows.Visibility]::Collapsed)
        $global:sync["WPFTweaksContentScroll"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
        $global:sync["WPFTweaksActionBar"].Visibility | Should -Be ([System.Windows.Visibility]::Visible)
    }
}
