function Get-WinUtilPowerShell7Path {
    $command = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    foreach ($candidate in @(
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe")) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    return $null
}

function Invoke-WinUtilInstallPSProfile {
    <#
    .SYNOPSIS
        Installs the CTT PowerShell profile

    .DESCRIPTION
        The profile targets PowerShell 7, so its setup script has to run under pwsh rather than
        the runspace this job is on. It runs as a child process with its output captured, so the
        job log records what happened instead of it scrolling past in a terminal nobody kept.
    #>

    $pwshPath = Get-WinUtilPowerShell7Path
    if (-not $pwshPath) {
        Step-WinUtilJob -Status "Installing PowerShell 7" -State "Indeterminate"
        Write-WinUtilLog -Component "Feature" -Message "PowerShell 7 not found, installing it first."

        Install-WinUtilWinget
        Install-WinUtilProgramWinget -Action Install -Programs @("Microsoft.PowerShell") | Out-Null

        # WinGet updates the persisted PATH, not this already-running process. Resolve the
        # standard install locations as well as the current PATH before deciding it failed.
        $pwshPath = Get-WinUtilPowerShell7Path
        if (-not $pwshPath) {
            throw "PowerShell 7 could not be installed, so the profile cannot be set up."
        }
    }

    Step-WinUtilJob -Status "Running the profile setup" -State "Indeterminate"

    $setupUrl = "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1"
    # Stop in the child, so a setup failure is a nonzero exit rather than a logged error and a
    # exit code of zero
    $output = & $pwshPath -NoProfile -NonInteractive -Command "`$ErrorActionPreference = 'Stop'; irm '$setupUrl' | iex" 2>&1
    $exitCode = $LASTEXITCODE

    $failures = 0
    foreach ($line in @($output)) {
        if ($line -is [System.Management.Automation.ErrorRecord]) {
            $failures++
            Write-WinUtilErrorRecord -ErrorRecord $line -Component "Feature" -Context "PowerShell profile setup"
        } elseif (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-WinUtilLog -Component "Feature" -Message ([string]$line).Trim()
        }
    }

    if ($exitCode -ne 0) {
        throw "The profile setup script exited with code $exitCode."
    }

    if ($failures -gt 0) {
        throw "The profile setup script reported $failures error(s); see the log."
    }

    Write-WinUtilLog -Component "Feature" -Message "CTT PowerShell profile installed. Open a new PowerShell 7 session to use it."
}
