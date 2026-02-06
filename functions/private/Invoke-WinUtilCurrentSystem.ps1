Function Invoke-WinUtilCurrentSystem {
    param([string]$CheckBox)

    if ($CheckBox -eq "tweaks") {
        if (!(Test-Path 'HKU:\')) { New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null }
        $ScheduledTasks = Get-ScheduledTask

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {
            $Config = $_.Name
            $isApplied = $true

            $registryKeys = $sync.configs.tweaks.$Config.registry
            foreach ($tweaks in $registryKeys) {
                foreach ($tweak in $tweaks) {
                    if (Test-Path $tweak.Path) {
                        $currentValue = (Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue |
                                         Select-Object -ExpandProperty $tweak.Name)
                        $expectedValue = $tweak.Value
                        if (($expectedValue -eq "<RemoveEntry>" -and $currentValue -ne $null) -or
                            ($expectedValue -ne "<RemoveEntry>" -and $currentValue -ne $expectedValue)) {
                            $isApplied = $false
                        }
                    } else { $isApplied = $false }
                }
            }

            $scheduledtaskKeys = $sync.configs.tweaks.$Config.scheduledtask
            foreach ($tweaks in $scheduledtaskKeys) {
                foreach ($tweak in $tweaks) {
                    $task = $ScheduledTasks | Where-Object { $_.TaskName -eq $tweak.Name }
                    if (!$task -or $task.State -ne $tweak.State) { $isApplied = $false }
                }
            }

            $serviceKeys = $sync.configs.tweaks.$Config.service
            foreach ($tweaks in $serviceKeys) {
                foreach ($tweak in $tweaks) {
                    $Service = Get-Service -Name $tweak.Name -ErrorAction SilentlyContinue
                    if (!$Service -or $Service.StartType -ne $tweak.StartupType) { $isApplied = $false }
                }
            }

            if ($isApplied) { Write-Output $Config }
        }
    }
}
