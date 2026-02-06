Function Invoke-WinUtilCurrentSystem {

    <#
    .SYNOPSIS
        Checks which tweaks, apps, and programs are applied and returns the toggles, respecting user changes.
    #>

    param(
        [string]$CheckBox
    )

    if (-not $sync.PSObject.Properties.Match('userToggles')) {
        $sync | Add-Member -MemberType NoteProperty -Name userToggles -Value @{}
    }

    if ($CheckBox -eq "choco") {
        $apps = (choco list --local-only | Select-String -Pattern "^\S+").Matches.Value
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object { $_ -like "WPFInstall*" }

        $sync.GetEnumerator() | Where-Object { $_.Key -in $filter } | ForEach-Object {
            $dependencies = @($sync.configs.applications.$($_.Key).choco -split ";")

            $isApplied = if ($sync.userToggles[$_.Key] -ne $null) {
                $sync.userToggles[$_.Key]
            } else {
                ($dependencies | ForEach-Object { $_ -in $apps } | Where-Object { $_ }) -ne $null
            }

            if ($isApplied) { Write-Output $_.Name }
        }
    }

    if ($CheckBox -eq "winget") {
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        $Sync.InstalledPrograms = winget list -s winget | Select-Object -Skip 3 |
            ConvertFrom-String -PropertyNames "Name", "Id", "Version", "Available" -Delimiter '\s{2,}'
        [Console]::OutputEncoding = $originalEncoding

        $installedIds = $sync.InstalledPrograms.Id | ForEach-Object { $_.Trim().ToLower() }
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object { $_ -like "WPFInstall*" }

        $sync.GetEnumerator() | Where-Object { $_.Key -in $filter } | ForEach-Object {
            $dependencies = @($sync.configs.applications.$($_.Key).winget -split ";") | ForEach-Object { $_.Trim().ToLower() }

            $isApplied = if ($sync.userToggles[$_.Key] -ne $null) {
                $sync.userToggles[$_.Key]
            } else {
                ($dependencies | ForEach-Object { $_ -in $installedIds } | Where-Object { $_ }) -ne $null
            }

            if ($isApplied) { Write-Output $_.Name }
        }
    }

    if ($CheckBox -eq "tweaks") {
        if (!(Test-Path 'HKU:\')) { New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null }
        $ScheduledTasks = Get-ScheduledTask

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {
            $Config = $_.Name
            $registryKeys = $sync.configs.tweaks.$Config.registry
            $scheduledtaskKeys = $sync.configs.tweaks.$Config.scheduledtask
            $serviceKeys = $sync.configs.tweaks.$Config.service

            if ($sync.userToggles[$Config] -ne $null) {
                $isApplied = $sync.userToggles[$Config]
            } else {
                $isApplied = $true

                foreach ($tweaks in $registryKeys) {
                    foreach ($tweak in $tweaks) {
                        if (Test-Path $tweak.Path) {
                            $actualValue = (Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue |
                                            Select-Object -ExpandProperty $($tweak.Name))
                            $expectedValue = $tweak.Value
                            if ($expectedValue -eq "<RemoveEntry>") {
                                if ($null -ne $actualValue) { $isApplied = $false }
                            } elseif ($actualValue -ne $expectedValue) {
                                $isApplied = $false
                            }
                        } else {
                            $isApplied = $false
                        }
                    }
                }

                foreach ($tweaks in $scheduledtaskKeys) {
                    foreach ($tweak in $tweaks) {
                        $task = $ScheduledTasks | Where-Object { $_.TaskName -eq $tweak.Name }
                        if ($task) {
                            if ($task.State -ne $tweak.State) { $isApplied = $false }
                        } else {
                            $isApplied = $false
                        }
                    }
                }

                foreach ($tweaks in $serviceKeys) {
                    foreach ($tweak in $tweaks) {
                        $Service = Get-Service -Name $tweak.Name -ErrorAction SilentlyContinue
                        if ($Service) {
                            if ($Service.StartType -ne $tweak.StartupType) { $isApplied = $false }
                        } else {
                            $isApplied = $false
                        }
                    }
                }
            }

            if ($isApplied) { Write-Output $Config }
        }
    }
}

Function Set-UserToggle {
    param(
        [string]$ConfigName,
        [bool]$State
    )
    $sync.userToggles[$ConfigName] = $State
}
