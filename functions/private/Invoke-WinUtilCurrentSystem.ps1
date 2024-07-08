Function Invoke-WinUtilCurrentSystem {

    <#

    .SYNOPSIS
        Checks to see what tweaks have already been applied and what programs are installed, and checks the according boxes

    .EXAMPLE
        Get-WinUtilCheckBoxes "WPFInstall"

    #>

    param(
        $CheckBox
    )

    if ($checkbox -eq "winget"){

        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        $Sync.InstalledPrograms = winget list -s winget | Select-Object -skip 3 | ConvertFrom-String -PropertyNames "Name", "Id", "Version", "Available" -Delimiter '\s{2,}'
        [Console]::OutputEncoding = $originalEncoding

        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPFInstall*"}
        $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter} | ForEach-Object {
            $dependencies = @($sync.configs.applications.$($psitem.Key).winget -split ";")

            if ($dependencies[-1] -in $sync.InstalledPrograms.Id) {
                Write-Output $psitem.name
            }
        }
    }

    if($CheckBox -eq "tweaks"){

        if(!(Test-Path 'HKU:\')){New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS}
        $ScheduledTasks = Get-ScheduledTask

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {

            $Config = $psitem.Name
            #WPFEssTweaksTele
            $registryKeys = $sync.configs.tweaks.$Config.registry
            $scheduledtaskKeys = $sync.configs.tweaks.$Config.scheduledtask
            $serviceKeys = $sync.configs.tweaks.$Config.service

            if($registryKeys -or $scheduledtaskKeys -or $serviceKeys){
                $Values = @()


                Foreach ($tweaks in $registryKeys){
                    Foreach($tweak in $tweaks){

                        if(test-path $tweak.Path){
                            $actualValue = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
                            $expectedValue = $tweak.Value
                            if ($expectedValue -notlike $actualValue){
                                $values += $False
                            }
                        }
                        else {
                            $values += $False
                        }
                    }
                }

                Foreach ($tweaks in $scheduledtaskKeys){
                    Foreach($tweak in $tweaks){
                        $task = $ScheduledTasks | Where-Object {$($psitem.TaskPath + $psitem.TaskName) -like "\$($tweak.name)"}

                        if($task){
                            $actualValue = $task.State
                            $expectedValue = $tweak.State
                            if ($expectedValue -ne $actualValue){
                                $values += $False
                            }
                        }
                    }
                }

                Foreach ($tweaks in $serviceKeys){
                    Foreach($tweak in $tweaks){
                        $Service = Get-Service -Name $tweak.Name

                        if($Service){
                            $actualValue = $Service.StartType
                            $expectedValue = $tweak.StartupType
                            if ($expectedValue -ne $actualValue){
                                $values += $False
                            }
                        }
                    }
                }

                if($values -notcontains $false){
                    Write-Output $Config
                }
            }
        }
    }
}

