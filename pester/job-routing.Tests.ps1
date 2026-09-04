#===========================================================================
# Tests - Everything that changes the system goes through the job layer

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:configRoot = Join-Path $script:repoRoot "config"
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






}
