function Install-WinUtilChoco {
    <#
    .SYNOPSIS
        Installs Chocolatey if it is not already present
    #>

    if (Get-Command -Name choco -ErrorAction SilentlyContinue) {
        return
    }

    Write-WinUtilLog -Component "Package" -Message "Chocolatey is not installed, installing it now."
    Step-WinUtilJob -Status "Installing Chocolatey" -State "Indeterminate"

    # Windows PowerShell 5.1 can negotiate a protocol the site refuses, which the official
    # bootstrap sets explicitly for the same reason
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $installScript = Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing -TimeoutSec 60
    Invoke-Command -ScriptBlock ([scriptblock]::Create($installScript.Content))

    # The installer extends PATH for new processes, which this one is not. Appended rather than
    # replaced: overwriting drops whatever this process added earlier in the session, and a
    # later step looking for that tool would no longer find it.
    $existing = $env:PATH -split ';' | Where-Object { $_ }
    $persisted = @(
        [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        [System.Environment]::GetEnvironmentVariable("Path", "User")
    ) -join ';' -split ';' | Where-Object { $_ }

    $missing = $persisted | Where-Object { $existing -notcontains $_ }
    if ($missing) {
        $env:PATH = (@($existing) + @($missing)) -join ';'
    }

    if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
        throw "Chocolatey was installed but choco is still not on PATH."
    }

    Write-WinUtilLog -Component "Package" -Message "Chocolatey installed."
}
