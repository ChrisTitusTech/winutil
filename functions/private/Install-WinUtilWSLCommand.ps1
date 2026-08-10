Function Install-WinUtilWSLCommand {
    <#
    .SYNOPSIS
        Runs a bash command inside a WSL distro - the install command with {{NAME}} tokens
        substituted from values collected earlier (via Resolve-WinUtilPackagePrompts, on the
        UI thread), or the uninstallCommand as-is when -Action Uninstall.

    .DESCRIPTION
        The command is written to a temp .sh file and placed into the target distro via
        its \\wsl.localhost UNC path, then executed as a script - this avoids the nested
        quoting problems of passing a command with embedded $(...) and quotes through
        `wsl -d <distro> -- bash -c "..."`.

        Written via Set-WinUtilNoBomFileContent, not Set-Content -Encoding UTF8 - see that
        function's own docstring for why: confirmed live, Set-Content's UTF8 encoding prepended
        a byte-order-mark under Windows PowerShell 5.1 (not PowerShell 7+, same command),
        corrupting the first word of the script - a "docker: command not found" error was
        actually a mangled "<BOM>docker", the literal docker install/uninstall command was
        correct, the file it ended up in wasn't.

        If the package declares requiresDockerInDistro, checks that "docker" is actually
        reachable inside the target distro BEFORE running its command, via
        Test-WinUtilDockerAvailableInWSL - Docker Desktop being installed doesn't mean WSL
        integration is enabled for this specific distro, and running the command anyway just
        fails with a generic, deep-in-the-script "command not found" that doesn't point at the
        actual cause. Only meaningful for Install - if docker was reachable when this installed,
        there's no reason to gate uninstall on it too (and doing so would only ever block a
        cleanup step the user is trying to run, for no benefit).

        Checks the wsl.exe call's real exit code rather than assuming success whenever it
        produces any output - confirmed live: a failed docker command (exit code 127, "command
        not found") was still logged as "install completed", because only the ABSENCE of output
        was treated as a problem before, not a non-zero exit code.

        Bounded to several minutes via Invoke-WinUtilWithTimeout, not the few-second default
        used elsewhere for quick DISM/registry checks - these commands can do real work (e.g.
        pulling a Docker image) that legitimately takes a while, and wsl.exe itself can hang for
        unrelated reasons (see Install-WinUtilWSLDistro.ps1 for a confirmed real case). Unlike
        that function, there's no independent way to verify an arbitrary command's success after
        a timeout, so a timeout here is logged as a real, if inconclusive, warning rather than
        silently assumed fine.
    #>
    param (
        [ValidateSet("Install", "Uninstall")]
        [string]$Action = "Install",

        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    foreach ($package in $Packages) {
        $name = $package.content
        $distro = $package.distro
        $command = if ($Action -eq "Uninstall") { $package.uninstallCommand } else { $package.command }

        if ([string]::IsNullOrWhiteSpace($distro) -or [string]::IsNullOrWhiteSpace($command)) {
            if ($Action -eq "Uninstall") {
                Write-WinUtilLog -Level "WARN" -Component "Package" -Message "$name has no uninstallCommand defined - not uninstalled. Remove it manually if needed."
            } else {
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "WSL command install for $name is missing distro/command."
            }
            continue
        }

        if ($Action -eq "Install" -and $package.requiresDockerInDistro) {
            $dockerCheck = Test-WinUtilDockerAvailableInWSL -Distro $distro
            if (-not $dockerCheck.Available) {
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Skipping $name install - $($dockerCheck.Reason)"
                continue
            }
        }

        if ($package.PromptValues) {
            foreach ($promptValue in $package.PromptValues.GetEnumerator()) {
                $command = $command.Replace("{{$($promptValue.Key)}}", $promptValue.Value)
            }
        }

        $scriptName = "cdvr-$($package.Key)-$($Action.ToLower()).sh"
        $wslTempPath = "\\wsl.localhost\$distro\tmp\$scriptName"

        Write-WinUtilLog -Component "Package" -Message "Running $name $($Action.ToLower()) inside WSL distro $distro"
        try {
            Set-WinUtilNoBomFileContent -Path $wslTempPath -Value $command

            $result = Invoke-WinUtilWithTimeout -TimeoutSeconds 300 -DefaultValue $null -ArgumentList @($distro, $scriptName) -OnWaitingIntervalSeconds 20 -OnWaiting {
                param($elapsedSeconds)
                Write-WinUtilLog -Component "Package" -Message "Still running $name $($Action.ToLower()) inside WSL ($($elapsedSeconds)s elapsed) - this can take a while."
                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Running $name $($Action.ToLower()) ($($elapsedSeconds)s elapsed)..."
            } -ScriptBlock {
                param($distro, $scriptName)
                try {
                    $scriptOutput = (& wsl -d $distro -- bash "/tmp/$scriptName" 2>&1 | Out-String).Trim()
                    return [pscustomobject]@{ Output = $scriptOutput; ExitCode = $LASTEXITCODE }
                } catch {
                    return [pscustomobject]@{ Output = $null; ExitCode = -1 }
                }
            }

            if ($null -eq $result) {
                Write-WinUtilLog -Level "WARN" -Component "Package" -Message "$name $($Action.ToLower()) did not finish within the expected time - it may still be running inside WSL, or may need interactive input this app can't provide."
                continue
            }

            Write-WinUtilLog -Component "Package" -Message $(if ($result.Output) { $result.Output } else { "(command completed with no console output)" })
            if ($result.ExitCode -eq 0) {
                Write-WinUtilLog -Component "Package" -Message "$name $($Action.ToLower()) completed."
            } else {
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "$name $($Action.ToLower()) FAILED (exit code: $($result.ExitCode)) - see the output above for the reason."
            }
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to run $($Action.ToLower()) for ${name}: $_"
        } finally {
            Remove-Item -Path $wslTempPath -Force -ErrorAction SilentlyContinue
        }
    }
}
