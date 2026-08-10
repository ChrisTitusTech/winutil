Function Install-WinUtilProgramNpm {
    <#
    .SYNOPSIS
        Installs or uninstalls a global npm package. Requires Node.js/npm to already be on
        PATH - packages using this installType should declare "nodejs" in their "requires".
    #>
    param (
        [ValidateSet("Install", "Uninstall")]
        [string]$Action = "Install",

        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    foreach ($package in $Packages) {
        $name = $package.content
        $npmPackage = $package.npmPackage

        if ([string]::IsNullOrWhiteSpace($npmPackage)) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "npm $($Action.ToLower()) for $name is missing npmPackage."
            continue
        }

        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "npm is not on PATH - can't $($Action.ToLower()) $name."
            continue
        }

        $npmVerb = if ($Action -eq "Uninstall") { "uninstall" } else { "install" }
        Write-WinUtilLog -Component "Package" -Message "$Action $name via npm ($npmPackage)"
        $process = Start-Process -FilePath "npm" -ArgumentList @($npmVerb, "-g", $npmPackage) -NoNewWindow -Wait -PassThru
        Write-WinUtilLog -Component "Package" -Message "$name npm $($npmVerb) completed (exit code: $($process.ExitCode))"

        # Some npm-distributed tools need a separate step to actually start running (or set up
        # their own auto-start) after the package itself is installed - e.g. Prismcast installs
        # as a dormant CLI until "prismcast service install" registers and starts it as a
        # background service.
        if ($Action -eq "Install" -and $process.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($package.postInstallCommand)) {
            Write-WinUtilLog -Component "Package" -Message "Running post-install step for $name`: $($package.postInstallCommand)"
            try {
                & ([scriptblock]::Create($package.postInstallCommand))
                Write-WinUtilLog -Component "Package" -Message "$name post-install step completed"
            } catch {
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Post-install step failed for ${name}: $_"
            }
        }
    }
}
