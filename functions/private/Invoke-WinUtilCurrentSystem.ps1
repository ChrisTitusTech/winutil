Function Invoke-WinUtilCurrentSystem {

    <#

    .SYNOPSIS
        Checks to see what tweaks have already been applied and what programs are installed, and checks the according boxes

    .EXAMPLE
        InvokeWinUtilCurrentSystem -Checkbox "winget"

    #>

    param(
        $CheckBox
    )
    if ($CheckBox -eq "choco") {
        $apps = (choco list | Select-String -Pattern "^\S+").Matches.Value
        foreach ($app in $sync.configs.applicationsHashtable.GetEnumerator()) {
            $packageId = ($app.Value.choco -split ";")[-1].Trim()
            if ($packageId -ne "na" -and $packageId -in $apps) {
                Write-Output $app.Key
            }
        }
    }

    if ($checkbox -eq "winget") {
        $originalEncoding = [Console]::OutputEncoding
        try {
            [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
            $installedProgramOutput = @(winget list --accept-source-agreements --disable-interactivity 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "winget list failed with exit code $LASTEXITCODE."
            }
        } finally {
            [Console]::OutputEncoding = $originalEncoding
        }
        $installedProgramText = $installedProgramOutput -join "`n"

        foreach ($app in $sync.configs.applicationsHashtable.GetEnumerator()) {
            $packageId = (($app.Value.winget -split ";")[-1] -replace "^msstore:", "").Trim()
            if ([string]::IsNullOrWhiteSpace($packageId) -or $packageId -eq "na") {
                continue
            }

            $packagePattern = "(?im)[^\S\r\n]{2,}$([regex]::Escape($packageId))(?=[^\S\r\n]{2,}|$)"
            if ($installedProgramText -match $packagePattern) {
                Write-Output $app.Key
            }
        }
    }

    if ($CheckBox -eq "tweaks") {

        if (!(Test-Path 'HKU:\')) {$null = (New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS)}

        foreach ($prop in $sync.configs.tweaks.PSObject.Properties) {
            $Config = $prop.Name
            $entry = $prop.Value
            $registryKeys = $entry.registry
            $serviceKeys = $entry.service
            $entryType = $entry.Type

            if ($registryKeys -or $serviceKeys) {
                $allMatch = $true

                if ($entryType -eq "Toggle") {
                    if (-not (Get-WinUtilToggleStatus $Config)) {
                        $allMatch = $false
                    }
                } else {
                    $registryMatchCount = 0
                    $registryTotal = 0

                    foreach ($tweaks in $registryKeys) {
                        foreach ($tweak in $tweaks) {
                            $registryTotal++
                            $regstate = $null

                            if (Test-Path $tweak.Path) {
                                $regstate = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
                            }

                            if ($null -eq $regstate) {
                                switch ($tweak.DefaultState) {
                                    "true" { $regstate = $tweak.Value }
                                    "false" { $regstate = $tweak.OriginalValue }
                                    default { $regstate = $tweak.OriginalValue }
                                }
                            }

                            if ($regstate -eq $tweak.Value) {
                                $registryMatchCount++
                            }
                        }
                    }

                    if ($registryTotal -gt 0 -and $registryMatchCount -ne $registryTotal) {
                        $allMatch = $false
                    }
                }

                foreach ($tweaks in $serviceKeys) {
                    foreach ($tweak in $tweaks) {
                        $Service = Get-Service -Name $tweak.Name -ErrorAction SilentlyContinue
                        if ($Service -and $tweak.StartupType -ne $Service.StartType) {
                            $allMatch = $false
                            break
                        }
                    }
                    if (-not $allMatch) { break }
                }

                if ($allMatch) {
                    Write-Output $Config
                }
            }
        }
    }
}
