Function Invoke-WinUtilCurrentSystem {

    <#
    .SYNOPSIS
        Checks which tweaks, apps, and programs are currently applied on the system and sets toggles accordingly.

    .EXAMPLE
        Invoke-WinUtilCurrentSystem -CheckBox "tweaks"
        Returns all tweak toggles that are currently applied on the system.

    .EXAMPLE
        Invoke-WinUtilCurrentSystem -CheckBox "choco"
        Returns all Choco package toggles that are currently installed.

    .EXAMPLE
        Invoke-WinUtilCurrentSystem -CheckBox "winget"
        Returns all Winget package toggles that are currently installed.
    #>

    param([string]$CheckBox)

    if ($CheckBox -eq "choco") {
        $apps = (choco list --local-only | Select-String -Pattern "^\S+").Matches.Value
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object { $_ -like "WPFInstall*" }

        $sync.GetEnumerator() | Where-Object { $_.Key -in $filter } | ForEach-Object {
            $dependencies = @($sync.configs.applications.$($_.Key).choco -split ";")
            if ($dependencies | ForEach-Object { $_ -in $apps } | Where-Object { $_ }) { Write-Output $_.Name }
        }
    }

    if ($CheckBox -eq "winget") {
        $orig = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        $Sync.InstalledPrograms = winget list -s winget | Select-Object -Skip 3 |
            ConvertFrom-String -PropertyNames "Name","Id","Version","Available" -Delimiter '\s{2,}'
        [Console]::OutputEncoding = $orig

        $installedIds = $sync.InstalledPrograms.Id | ForEach-Object { $_.Trim().ToLower() }
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object { $_ -like "WPFInstall*" }

        $sync.GetEnumerator() | Where-Object { $_.Key -in $filter } | ForEach-Object {
            $dependencies = @($sync.configs.applications.$($_.Key).winget -split ";") | ForEach-Object { $_.Trim().ToLower() }
            if ($dependencies | ForEach-Object { $_ -in $installedIds } | Where-Object { $_ }) { Write-Output $_.Name }
        }
    }

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
