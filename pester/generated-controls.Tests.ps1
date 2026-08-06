#===========================================================================
# Tests - Generated control lifetime
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:xamlText = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw

    # Names that exist only once a tab has been built from config
    $script:generatedNames = @(
        Get-ChildItem -Path (Join-Path $script:repoRoot "config") -Filter *.json | ForEach-Object {
            $config = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
            $config.PSObject.Properties.Name
        }
    ) | Sort-Object -Unique | Where-Object { $script:xamlText -notmatch "Name=`"$([regex]::Escape($_))`"" }
}

Describe "Generated controls" {
    # Tab content is built after first paint, so anything referencing a generated control from
    # the interface build runs while that control is still $null. That produced three silent
    # "You cannot call a method on a null-valued expression" errors.
    It "are not touched while the interface is being built" {
        $uiScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw

        $referenced = @(
            [regex]::Matches($uiScript, '\$sync(?:\["([A-Za-z_][A-Za-z0-9_]*)"\]|\.([A-Za-z_][A-Za-z0-9_]*))') |
                ForEach-Object { if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value } }
        ) | Sort-Object -Unique

        $tooEarly = @($referenced | Where-Object { $script:generatedNames -contains $_ })

        if ($tooEarly.Count -gt 0) {
            throw "Start-WinUtilUserInterface touches generated control(s) that do not exist yet: $($tooEarly -join ', '). Wire them from Initialize-WinUtilInstallTabControls or the tab that creates them."
        }
    }

    It "are wired from the tab that creates them" {
        $tabScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTabContent.ps1") -Raw
        $installScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilInstallTabControls.ps1") -Raw

        $tabScript | Should -Match 'Initialize-WinUtilInstallTabControls'
        $installScript | Should -Match '\$sync\.ChocoRadioButton'
        $installScript | Should -Match '\$sync\.WingetRadioButton'
        $installScript | Should -Match '\$PARAM_OFFLINE'
    }

    It "are guarded against still being missing" {
        $installScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilInstallTabControls.ps1") -Raw

        # Every use is behind an existence check, so a config change cannot reintroduce the crash
        $installScript | Should -Match 'if \(\$sync\.ChocoRadioButton\)'
        $installScript | Should -Match 'if \(\$sync\.WingetRadioButton\)'
        $installScript | Should -Match 'if \(\$sync\.\$name\)'
    }
}
