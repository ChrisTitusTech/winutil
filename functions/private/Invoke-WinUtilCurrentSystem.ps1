Function Invoke-WinUtilCurrentSystem {

    <#

    .SYNOPSIS
        Checks to see what tweaks have already been applied and what programs are installed, and checks the according boxes

    .EXAMPLE
        InvokeWinUtilCurrentSystem -Checkbox "winget"

    #>

    param(
        $CheckBox,
        [switch]$BypassToggleStatusCache,
        [switch]$StopOnReadError
    )
    if ($CheckBox -eq "choco") {
        $apps = (choco list | Select-String -Pattern "^\S+").Matches.Value
        $sync.configs.applicationsHashtable.GetEnumerator() | ForEach-Object {
            $packageId = ($_.Value.choco -split ";")[-1].Trim()
            if ($packageId -ne "na" -and $packageId -in $apps) {
                Write-Output $_.Key
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

        # winget pads each column to its widest value plus one space, so the row with the widest Name or Id
        # has only one space next to its Id. Take the Id column position from the header above the dashes.
        $idColumnStart = 0
        if ($installedProgramText -match '(?m)^(\S+[^\S\r\n]+)\S[^\r\n]*\r?\n-{3,}') {
            $idColumnStart = $Matches[1].Length
        }

        $sync.configs.applicationsHashtable.GetEnumerator() | ForEach-Object {
            $packageId = (($_.Value.winget -split ";")[-1] -replace "^msstore:", "").Trim()
            if ([string]::IsNullOrWhiteSpace($packageId) -or $packageId -eq "na") {
                return
            }

            $escapedPackageId = [regex]::Escape($packageId)
            $packagePattern = "(?im)[^\S\r\n]{2,}$escapedPackageId(?=[^\S\r\n]{2,}|$)"
            # Skip rows whose Name has combining marks or emoji: they are more characters than columns and shift the offset
            $idColumnPattern = "(?im)(?<=^[^\r\n\p{M}\p{Cs}\p{Cf}]{$($idColumnStart - 1)}[^\S\r\n])$escapedPackageId(?=[^\S\r\n]|$)"
            if ($installedProgramText -match $packagePattern -or ($idColumnStart -and $installedProgramText -match $idColumnPattern)) {
                Write-Output $_.Key
            }
        }
    }

    if ($CheckBox -eq "tweaks") {

        if (!(Test-Path 'HKU:\')) {$null = (New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS)}
        $readErrorAction = if ($StopOnReadError) { "Stop" } else { "SilentlyContinue" }

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {

            $Config = $psitem.Name
            $entry = $sync.configs.tweaks.$Config
            $registryKeys = $entry.registry
            $serviceKeys = $entry.service
            $entryType = $entry.Type

            if (($registryKeys -or $serviceKeys) -and $entryType -ne "Combobox") {
                $Values = @()

                if ($entryType -eq "Toggle") {
                    if (-not (Get-WinUtilToggleStatus $Config `
                        -BypassCache:$BypassToggleStatusCache `
                        -StopOnReadError:$StopOnReadError)) {
                        $values += $False
                    }
                } else {
                    $registryMatchCount = 0
                    $registryTotal = 0

                    Foreach ($tweaks in $registryKeys) {
                        Foreach ($tweak in $tweaks) {
                            $registryTotal++
                            $regstate = $null

                            if (Test-Path $tweak.Path -ErrorAction $readErrorAction) {
                                if ($StopOnReadError) {
                                    $regstate = (Get-ItemProperty -Path $tweak.Path -ErrorAction Stop).$($tweak.Name)
                                } else {
                                    $regstate = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
                                }
                            }

                            if ($null -eq $regstate) {
                                switch ($tweak.DefaultState) {
                                    "true" {
                                        $regstate = $tweak.Value
                                    }
                                    "false" {
                                        $regstate = $tweak.OriginalValue
                                    }
                                    default {
                                        $regstate = $tweak.OriginalValue
                                    }
                                }
                            }

                            if ($regstate -eq $tweak.Value) {
                                $registryMatchCount++
                            }
                        }
                    }

                    if ($registryTotal -gt 0 -and $registryMatchCount -ne $registryTotal) {
                        $values += $False
                    }
                }

                Foreach ($tweaks in $serviceKeys) {
                    Foreach ($tweak in $tweaks) {
                        try {
                            $Service = Get-Service -Name $tweak.Name -ErrorAction $readErrorAction
                        } catch {
                            if ($StopOnReadError -and $_.FullyQualifiedErrorId -like "NoServiceFoundForGivenName*") {
                                # A removed optional service means this tweak is not applied; it does
                                # not make the registry and service state for every other tweak unknown.
                                $values += $False
                                continue
                            }
                            throw
                        }

                        if ($Service) {
                            $actualValue = $Service.StartType
                            $expectedValue = $tweak.StartupType
                            if ($expectedValue -ne $actualValue) {
                                $values += $False
                            }
                        } elseif ($StopOnReadError) {
                            $values += $False
                        }
                    }
                }

                if ($values -notcontains $false) {
                    Write-Output $Config
                }
            }
        }
    }
}
