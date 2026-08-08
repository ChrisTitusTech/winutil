#===========================================================================
# Tests - Everything that changes the system goes through the job layer
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:configRoot = Join-Path $script:repoRoot "config"

    function script:Get-WinUtilFunctionFile {
        param([string]$Name)
        Get-ChildItem -Path $script:functionRoot -Filter "$Name.ps1" -Recurse | Select-Object -First 1
    }
}

Describe "Work routing" {
    It "never hands work to a console window of its own" {
        # A separate console takes the work outside the job layer, so it gets no progress bar,
        # no taskbar state and no log lines, and the window outlives WinUtil
        $offenders = @()
        foreach ($file in (Get-ChildItem -Path $script:functionRoot -Filter *.ps1 -Recurse)) {
            $text = Get-Content -Path $file.FullName -Raw
            foreach ($line in ($text -split "`r?`n")) {
                if ($line -match '^\s*#') { continue }
                if ($line -match 'wt\s+new-tab') { $offenders += "$($file.Name): $($line.Trim())" }
                if ($line -match 'Start-Process\s+.*(powershell|pwsh)\.exe' -and $line -notmatch '-NoNewWindow') {
                    $offenders += "$($file.Name): $($line.Trim())"
                }
            }
        }

        if ($offenders.Count -gt 0) { throw ($offenders -join "`n") }
    }

    It "upgrades packages one at a time so the run reports progress" {
        $upgrade = Get-Content -Path (Get-WinUtilFunctionFile -Name "Invoke-WPFInstallUpgrade").FullName -Raw

        $upgrade | Should -Match 'Get-WinUtilUpgradablePackage'
        $upgrade | Should -Match 'foreach \(\$package in \$upgradable\)'
        $upgrade | Should -Match 'Install-WinUtilProgramWinget -Action Install'
        $upgrade | Should -Match 'Complete-WinUtilPackageRun'
        $upgrade | Should -Not -Match 'Start-Process'
    }

    It "resolves the PowerShell 7 profile from pwsh rather than the worker's own" {
        $uninstall = Get-Content -Path (Get-WinUtilFunctionFile -Name "Invoke-WinUtilUninstallPSProfile").FullName -Raw

        # $PROFILE inside a worker is Windows PowerShell's, which is not the file the install wrote
        $uninstall | Should -Match 'pwsh -NoProfile -NonInteractive -Command'
        $uninstall | Should -Match 'Test-Path \$profilePath'
    }

    It "probes for optional commands without throwing when they are absent" {
        $offenders = @()
        foreach ($file in (Get-ChildItem -Path $script:functionRoot -Filter *.ps1 -Recurse)) {
            $text = Get-Content -Path $file.FullName -Raw
            foreach ($line in ($text -split "`r?`n")) {
                if ($line -match 'if\s*\(\s*-not\s*\(Get-Command\s+[^\)]+\)\s*\)' -and $line -notmatch 'ErrorAction') {
                    $offenders += "$($file.Name): $($line.Trim())"
                }
            }
        }

        if ($offenders.Count -gt 0) { throw ($offenders -join "`n") }
    }

    It "routes every feature.json entry that is not a Windows applet through a job" {
        $buttonScript = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFButton.ps1") -Raw

        $buttonScript | Should -Match '\$isConfigWork = \$sync\.configs\.feature\.\$Button -and \$Button -notlike "WPFPanel\*"'
        $buttonScript | Should -Match 'Start-WinUtilJob -Name \(Get-WinUtilButtonLabel -Button \$Button\)'
    }

    It "keeps every package workflow inside a job" {
        $workflows = @(
            "Invoke-WPFInstall", "Invoke-WPFUnInstall", "Invoke-WPFtweaksbutton",
            "Invoke-WPFundoall", "Invoke-WPFGetInstalled", "Invoke-WPFAppxInstall",
            "Invoke-WPFAppxRemoval", "Invoke-WPFFeatureInstall"
        )

        foreach ($workflow in $workflows) {
            $file = Get-WinUtilFunctionFile -Name $workflow
            $file | Should -Not -BeNullOrEmpty -Because "$workflow should exist"
            (Get-Content -Path $file.FullName -Raw) | Should -Match 'Start-WinUtilJob' -Because "$workflow changes the system"
        }
    }

    It "never leaves the runspace handle in the pipeline" {
        # Invoke-WPFRunspace returns an IAsyncResult. An unassigned call prints it to the
        # console, or folds it into whatever the calling workflow returns.
        $offenders = @()
        foreach ($file in (Get-ChildItem -Path $script:functionRoot -Filter *.ps1 -Recurse)) {
            if ($file.Name -eq "Invoke-WPFRunspace.ps1") { continue }
            foreach ($line in ((Get-Content -Path $file.FullName -Raw) -split "`r?`n")) {
                if ($line -match '^\s*Invoke-WPFRunspace\b') { $offenders += "$($file.Name): $($line.Trim())" }
            }
        }

        if ($offenders.Count -gt 0) { throw ($offenders -join "`n") }
    }

    It "never blocks on a message box that nobody can answer" {
        # Showing a modal with no window never returns and takes the worker with it, which is
        # worse than the exception it replaced
        $dialogScript = Get-Content -Path (Join-Path $script:functionRoot "private\Show-WinUtilMessage.ps1") -Raw

        $noWindowBranch = ($dialogScript -split 'return Invoke-WPFUIThread')[0]
        $noWindowBranch | Should -Not -Match 'MessageBox\]::Show'
        $noWindowBranch | Should -Match '"OK"'
    }

    It "requires an explicit yes before removing software" {
        # "not No" also matches a prompt that was dismissed or never shown
        $uninstall = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFUnInstall.ps1") -Raw

        $uninstall | Should -Match '\$confirm -ne "Yes"'
        $uninstall | Should -Not -Match '\$confirm -eq "No"'
    }

    It "runs workers on the shared pool rather than a runspace per call" {
        $runspaceScript = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFRunspace.ps1") -Raw

        $runspaceScript | Should -Match '\$powershell\.RunspacePool = \$sync\.runspace'
        $runspaceScript | Should -Not -Match '\[runspacefactory\]::CreateRunspace\('
    }
}
