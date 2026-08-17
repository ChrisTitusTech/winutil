function Invoke-WinUtilInstallPSProfile {
    <#
    .SYNOPSIS
        Installs the CTT PowerShell profile

    .DESCRIPTION
        The profile targets PowerShell 7, so its setup script has to run under pwsh rather than
        the runspace this job is on. It runs as a child process with its output captured, so the
        job log records what happened instead of it scrolling past in a terminal nobody kept.
    #>

    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Step-WinUtilJob -Status "Installing PowerShell 7" -State "Indeterminate"
        Write-WinUtilLog -Component "Feature" -Message "PowerShell 7 not found, installing it first."

        Install-WinUtilWinget
        Install-WinUtilProgramWinget -Action Install -Programs @("Microsoft.PowerShell") | Out-Null

        if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            throw "PowerShell 7 could not be installed, so the profile cannot be set up."
        }
    }

    Step-WinUtilJob -Status "Running the profile setup" -State "Indeterminate"

    $setupUrl = "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1"
    $output = & pwsh -NoProfile -NonInteractive -Command "irm '$setupUrl' | iex" 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in @($output)) {
        if ($line -is [System.Management.Automation.ErrorRecord]) {
            Write-WinUtilErrorRecord -ErrorRecord $line -Component "Feature" -Context "PowerShell profile setup"
        } elseif (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-WinUtilLog -Component "Feature" -Message ([string]$line).Trim()
        }
    }

    if ($exitCode -ne 0) {
        throw "The profile setup script exited with code $exitCode."
    }

    Write-WinUtilLog -Component "Feature" -Message "CTT PowerShell profile installed. Open a new PowerShell 7 session to use it."
}
