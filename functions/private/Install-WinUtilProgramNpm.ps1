Function Install-WinUtilProgramNpm {
    <#
    .SYNOPSIS
        Installs or uninstalls a global npm package.

    .DESCRIPTION
        Requires Node.js/npm to be available on PATH. Packages using this
        installType should declare "nodejs" in their "requires" field.

        Throws on failures so the calling WinUtil workflow can update the UI,
        taskbar state, logs, and progress correctly.
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

        if ([string]::IsNullOrWhiteSpace($name)) {
            $name = $npmPackage
        }

        if ([string]::IsNullOrWhiteSpace($npmPackage)) {
            $message = "npm $($Action.ToLower()) for $name is missing npmPackage."
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            $message = "npm is not on PATH - can't $($Action.ToLower()) $name."
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        $npmVerb = if ($Action -eq "Uninstall") {
            "uninstall"
        } else {
            "install"
        }

        Write-WinUtilLog -Component "Package" -Message "$Action $name via npm ($npmPackage)"

        $process = $null

        try {
            $process = Start-Process `
                -FilePath "npm" `
                -ArgumentList @($npmVerb, "-g", $npmPackage) `
                -NoNewWindow `
                -Wait `
                -PassThru
        } catch {
            $message = "Failed to run npm $npmVerb for ${name}: $($_.Exception.Message)"
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        if ($null -eq $process) {
            $message = "npm $npmVerb for $name returned no process information."
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        if ($process.ExitCode -ne 0) {
            $message = "npm $npmVerb failed for $name (exit code: $($process.ExitCode))."
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        Write-WinUtilLog -Component "Package" -Message "$name npm $npmVerb completed (exit code: 0)"

        # npm packages such as Prismcast can require a separate post-install
        # action, for example registering and starting a background service.
        if (
            $Action -eq "Install" -and
            -not [string]::IsNullOrWhiteSpace([string]$package.postInstallCommand)
        ) {
            Write-WinUtilLog -Component "Package" -Message "Running post-install step for $name`: $($package.postInstallCommand)"

            try {
                & ([scriptblock]::Create([string]$package.postInstallCommand))
            } catch {
                $message = "Post-install step failed for ${name}: $($_.Exception.Message)"
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
                throw $message
            }

            Write-WinUtilLog -Component "Package" -Message "$name post-install step completed"
        }
    }
}
