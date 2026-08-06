function Install-WinUtilProgramChoco {
    <#

    .SYNOPSIS
        Installs or uninstalls packages with Chocolatey and reports the outcome

    .DESCRIPTION
        Chocolatey takes the whole package list in one call, so the result covers the batch
        rather than an entry per package.

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        $arguments = "install $Programs -y"
    } else {
        $arguments = "uninstall $Programs -y"
    }

    Write-WinUtilLog -Component "Package" -Message "$Action choco package(s): $($Programs -join ', ')"
    $process = Start-Process -FilePath choco -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode

    # 1641 and 3010 mean the work succeeded and Windows wants a reboot
    if ($exitCode -in @(0, 1641, 3010)) {
        $outcome = "Succeeded"
    } else {
        $outcome = "Failed"
    }

    $level = if ($outcome -eq "Failed") { "ERROR" } else { "INFO" }
    Write-WinUtilLog -Level $level -Component "Package" -Message "$Action choco package(s) $($outcome.ToLowerInvariant()): $($Programs -join ', ') (exit code: $exitCode)"

    [pscustomobject]@{
        Package = ($Programs -join ', ')
        Manager = "choco"
        Action = $Action
        ExitCode = $exitCode
        Outcome = $outcome
        Detail = "exit code $exitCode"
    }
}
