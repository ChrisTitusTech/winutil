
#Only here to compare as I rewrite the install tweaks function

Foreach($tweak in $tweakstorun){
    
    Write-Logs -Level INFO -Message "Running modifications for $tweak" -LogPath $sync.logfile

    #registry modification
    Foreach ($registries in $($sync.tweaks.$tweak.registry)){
        foreach($registry in $registries){
            if(!(Test-Path $registry.path)){
                Try{
                    Write-Logs -Level INFO -Message "$($registry.path) did not exist. Creating" -LogPath $sync.logfile
                    New-Item -Path $registry.path -ErrorAction stop -Force | Out-Null
                }Catch{Write-Logs -Level ERROR -Message "$($registry.path) Failed to create" -LogPath $sync.logfile}
            }
            Try{
                Write-Logs -Level INFO -Message "Setting $("$($registry.path)\$($registry.name)") to $($registry.value)" -LogPath $sync.logfile
                Set-ItemProperty -Path $registry.path -Name $registry.name -Type $registry.type -Value $registry.value
            }Catch{Write-Logs -Level ERROR -Message "$("$($registry.path)\$($registry.name)") was not set" -LogPath $sync.logfile}
        }
    }
    Write-Logs -Level INFO -Message "Finished setting registry" -LogPath $sync.logfile

    #Services modification 
    Foreach ($services in $($sync.tweaks.$tweak.service)){
        foreach($service in $services) {
            Try{
                Stop-Service "$($service.name)" -ErrorVariable serviceerror -ErrorAction stop
                Set-Service "$($service.name)" -StartupType $($service.StartupType) -ErrorVariable serviceerror -ErrorAction stop
                Write-Logs -Level INFO -Message "Service $($service.name) set to  $($service.StartupType)" -LogPath $sync.logfile
            }Catch{
                if($serviceerror -like "*Cannot find any service with service name*"){
                    Write-Logs -Level INFO -Message "Service $($service.name) not found" -LogPath $sync.logfile
                }else{Write-Logs -Level ERROR -Message "Unable to modify Service $($service.name)" -LogPath $sync.logfile}
            }
        }
    }
    Write-Logs -Level INFO -Message "Finished setting Services" -LogPath $sync.logfile

    #Scheduled Tasks Modification
    Foreach ($ScheduledTasks in $($sync.tweaks.$tweak.ScheduledTask)){
        foreach($ScheduledTask in $ScheduledTasks) {
            Try{
                if($($ScheduledTask.State) -eq "Disabled"){
                    Disable-ScheduledTask -TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                }
                if($($ScheduledTask.State) -eq "Enabled"){
                    Enable-TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                }
                Write-Logs -Level INFO -Message "Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.State)" -LogPath $sync.logfile
            }Catch{Write-Logs -Level ERROR -Message "Unable to set Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.State)" -LogPath $sync.logfile}
        }
    }
    Write-Logs -Level INFO -Message "Finished setting Scheduled Tasks" -LogPath $sync.logfile            

    #Remove Bloatware
    Foreach ($apps in $($sync.tweaks.$tweak.appx)){
        foreach($app in $apps) {
            Try{
                Get-AppxPackage -Name $app| Remove-AppxPackage -ErrorAction Stop
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -ErrorAction stop -Online
                Write-Logs -Level INFO -Message "Uninstalled $app" -LogPath $sync.logfile
            }Catch{Write-Logs -Level ERROR -Message "Failed to uninstall $app" -LogPath $sync.logfile }
        }
    }
    Write-Logs -Level INFO -Message "Finished removing bloat apps" -LogPath $sync.logfile 

    #old code that didn't work inside json file cleanly. Will investigate ways to get around this
    if ($tweak -eq "EssTweaksOO"){
        Import-Module BitsTransfer
        Start-BitsTransfer -Source "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -Destination ooshutup10.cfg
        Start-BitsTransfer -Source "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -Destination OOSU10.exe
        ./OOSU10.exe ooshutup10.cfg /quiet
    }        
    if ($tweak -eq "EssTweaksRP"){
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
    }        
    if ($tweak -eq "EssTweaksStorage"){
        Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Recurse -ErrorAction SilentlyContinue
    }
    if ($tweak -eq "EssTweaksTele"){

        Write-Host "Enabling F8 boot menu options..."
        bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null

        # Task Manager Details
        If ((get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
            Write-Host "Showing task manager details..."
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
            Do {
                Start-Sleep -Milliseconds 100
                $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
            } Until ($preferences)
            Stop-Process $taskmgr
            $preferences.Preferences[28] = 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences
        } else {Write-Host "Task Manager patch not run in builds 22557+ due to bug"}

        Write-Host "Hiding 3D Objects icon from This PC..."
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue  
        
        # Group svchost.exe processes
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force                

        Write-Host "Removing AutoLogger file and restricting directory..."
        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
            Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
        }
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
    }
    if ($tweak -eq "MiscTweaksLapNum"){
        If (!(Test-Path "HKU:")) {
            New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
        }
        Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
    }
    if ($tweak -eq "MiscTweaksNum"){
        If (!(Test-Path "HKU:")) {
            New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
        }
        Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 2
    }
    if ($tweak -eq "MiscTweaksDisplay"){
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
    }
}
Write-Logs -Level INFO -Message "Finished setting tweaks" -LogPath $sync.logfile
