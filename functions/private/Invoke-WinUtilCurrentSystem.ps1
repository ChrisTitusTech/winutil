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
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { return }
        $apps = choco list -l -r | ForEach-Object { $_.Split('|')[0] }
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object { $psitem -like "WPFInstall*" }
        foreach ($key in $filter) {
            $chocoId = $sync.configs.applications.$key.choco
            if ($null -ne $chocoId) {
                $dependencies = $chocoId -split ";"
                $allInstalled = $true
                foreach ($dep in $dependencies) {
                    if ($dep -notin $apps) {
                        $allInstalled = $false
                        break
                    }
                }
                if ($allInstalled) {
                    Write-Output $key
                }
            }
        }
    }

    if ($checkbox -eq "winget") {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return }
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        # Using --source winget to filter to just winget repo, and -q to be quiet.
        # ConvertFrom-String with Delimiter '\s{2,}' is a bit fragile but used in the original.
        $Sync.InstalledPrograms = winget list --source winget | Select-Object -skip 3 | ConvertFrom-String -PropertyNames "Name", "Id", "Version", "Available" -Delimiter '\s{2,}'
        [Console]::OutputEncoding = $originalEncoding

        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPFInstall*"}
        foreach ($key in $filter) {
            $wingetId = $sync.configs.applications.$key.winget
            if ($null -ne $wingetId) {
                $dependencies = $wingetId -split ";"
                $allInstalled = $true
                foreach ($dep in $dependencies) {
                    if ($dep -notin $sync.InstalledPrograms.Id) {
                        $allInstalled = $false
                        break
                    }
                }
                if ($allInstalled) {
                    Write-Output $key
                }
            }
        }
    }

    if ($CheckBox -eq "tweaks") {

        if (!(Test-Path 'HKU:\')) {$null = (New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS)}

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {

            $Config = $psitem.Name
            $entry = $sync.configs.tweaks.$Config
            $registryKeys = $entry.registry
            $serviceKeys = $entry.service
            $appxKeys = $entry.appx
            $invokeScript = $entry.InvokeScript
            $entryType = $entry.Type

            if ($registryKeys -or $serviceKeys) {
                $Values = @()

                if ($entryType -eq "Toggle") {
                    if (-not (Get-WinUtilToggleStatus $Config)) {
                        $values += $False
                    }
                } else {
                    $registryMatchCount = 0
                    $registryTotal = 0

                    Foreach ($tweaks in $registryKeys) {
                        Foreach ($tweak in $tweaks) {
                            $registryTotal++
                            $regstate = $null

                            if (Test-Path $tweak.Path) {
                                $regstate = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
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
                        $Service = Get-Service -Name $tweak.Name

                        if ($Service) {
                            $actualValue = $Service.StartType
                            $expectedValue = $tweak.StartupType
                            if ($expectedValue -ne $actualValue) {
                                $values += $False
                            }
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
