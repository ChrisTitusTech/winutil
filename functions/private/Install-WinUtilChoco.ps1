function Install-WinUtilChoco {
    <#
    .SYNOPSIS
        Installs Chocolatey if it is not already present
    #>

    if (Get-Command -Name choco -ErrorAction SilentlyContinue) {
        return
    }

    Write-WinUtilLog -Component "Package" -Message "Chocolatey is not installed, installing it now."
    Write-WinUtilJobProgress -Status "Installing Chocolatey" -State "Indeterminate"

    $installScript = Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing
    Invoke-Command -ScriptBlock ([scriptblock]::Create($installScript.Content))

    # The installer extends PATH for new processes, which this one is not
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
        throw "Chocolatey was installed but choco is still not on PATH."
    }

    Write-WinUtilLog -Component "Package" -Message "Chocolatey installed."
}
