Function Invoke-WinUtilCurrentSystemTweak {

    <#

    .SYNOPSIS
        Checks to see tweaks have already been applied 

    .EXAMPLE
        Get-WinUtilCheckBoxesTweak "WPFToogleDarkTheme"

    #>

    param(
        $tweaktocheck,
        $ScheduledTasks = @()
    )

    $Config = $tweaktocheck.Name
    #WPFEssTweaksTele
    $registryKeys = $sync.configs.tweaks.$Config.registry
    $scheduledtaskKeys = $sync.configs.tweaks.$Config.scheduledtask
    $serviceKeys = $sync.configs.tweaks.$Config.service

    if($registryKeys -or $scheduledtaskKeys -or $serviceKeys){

        Foreach ($tweaks in $registryKeys){
            Foreach($tweak in $tweaks){

                if(test-path $tweak.Path){
                    $actualValue = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
                    $expectedValue = $tweak.Value
                    if ($expectedValue -notlike $actualValue){
                        return $False
                    }
                }
            }
        }

        Foreach ($tweaks in $scheduledtaskKeys){
            Foreach($tweak in $tweaks){
                $task = $ScheduledTasks | Where-Object {$($tweaktocheck.TaskPath + $tweaktocheck.TaskName) -like "\$($tweak.name)"}

                if($task){
                    $actualValue = $task.State
                    $expectedValue = $tweak.State
                    if ($expectedValue -ne $actualValue){
                        return $False
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
                        return $False
                    }
                }
            }
        }

        return $True
    }
}

