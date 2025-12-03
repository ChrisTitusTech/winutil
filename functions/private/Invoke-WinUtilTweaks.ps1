function Invoke-WinUtilTweaks {
    <#

    .SYNOPSIS
        Invokes the function associated with each provided checkbox

    .PARAMETER CheckBox
        The checkbox to invoke

    .PARAMETER undo
        Indicates whether to undo the operation contained in the checkbox

    .PARAMETER KeepServiceStartup
        Indicates whether to override the startup of a service with the one given from WinUtil,
        or to keep the startup of said service, if it was changed by the user, or another program, from its default value.
    #>

    param(
        $CheckBox,
        $undo = $false,
        $KeepServiceStartup = $true
    )

    Write-Debug "Tweaks: $($CheckBox)"
    if($undo) {
        $Values = @{
            Registry = "OriginalValue"
            ScheduledTask = "OriginalState"
            Service = "OriginalType"
            ScriptType = "UndoScript"
        }

    } else {
        $Values = @{
            Registry = "Value"
            ScheduledTask = "State"
            Service = "StartupType"
            OriginalService = "OriginalType"
            ScriptType = "InvokeScript"
        }
    }
    if($sync.configs.tweaks.$CheckBox.ScheduledTask) {
        $sync.configs.tweaks.$CheckBox.ScheduledTask | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.ScheduledTask))"
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.$($values.ScheduledTask)
        }
    }
    if($sync.configs.tweaks.$CheckBox.service) {
        Write-Debug "KeepServiceStartup is $KeepServiceStartup"
        $sync.configs.tweaks.$CheckBox.service | ForEach-Object {
            $changeservice = $true

        # The check for !($undo) is required, without it the script will throw an error for accessing unavailable member, which's the 'OriginalService' Property
            if($KeepServiceStartup -AND !($undo)) {
                try {
                    # Check if the service exists
                    $service = Get-Service -Name $psitem.Name -ErrorAction Stop
                    if(!($service.StartType.ToString() -eq $psitem.$($values.OriginalService))) {
                        Write-Debug "Service $($service.Name) was changed in the past to $($service.StartType.ToString()) from it's original type of $($psitem.$($values.OriginalService)), will not change it to $($psitem.$($values.service))"
                        $changeservice = $false
                    }
                } catch [System.ServiceProcess.ServiceNotFoundException] {
                    Write-Warning "Service $($psitem.Name) was not found"
                }
            }

            if($changeservice) {
                Write-Debug "$($psitem.Name) and state is $($psitem.$($values.service))"
                Set-WinUtilService -Name $psitem.Name -StartupType $psitem.$($values.Service)
            }
        }
    }
    if($sync.configs.tweaks.$CheckBox.registry) {
        $sync.configs.tweaks.$CheckBox.registry | ForEach-Object {
            Write-Debug "$($psitem.Name) and state is $($psitem.$($values.registry))"
            
            # Logic for ApplyToAllUsers feature
            if ($ApplyToAllUsers -and $psitem.Path -match "^(HKCU:|HKEY_CURRENT_USER)") {
                # Ensure HKU drive exists if needed
                if (!(Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
                    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
                }
                
                $relativePath = $psitem.Path -replace '^(HKCU:|HKEY_CURRENT_USER\\?)', ''
                $excludedSIDs = @('S-1-5-18', 'S-1-5-19', 'S-1-5-20', '.DEFAULT')
                
                Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" -ErrorAction SilentlyContinue |
                    Where-Object { $_.PSChildName -notin $excludedSIDs -and $_.ProfileImagePath } |
                    ForEach-Object {
                        $sid = $_.PSChildName
                        $ntUserPath = Join-Path $_.ProfileImagePath "NTUSER.DAT"
                        $needsUnload = !(Test-Path "HKU:\$sid")
                        
                        if ($needsUnload -and (Test-Path $ntUserPath)) {
                            reg load "HKU\$sid" "$ntUserPath" 2>&1 | Out-Null
                            Start-Sleep -Milliseconds 100
                        }
                        
                        try {
                            $targetPath = "HKU:\$sid\$relativePath"
                            if (!(Test-Path $targetPath)) { New-Item -Path $targetPath -Force | Out-Null }
                            Set-WinUtilRegistry -Name $psitem.Name -Path $targetPath -Type $psitem.Type -Value $psitem.$($values.registry)
                        } catch {
                            Write-Warning "Failed to set registry for SID $sid : $_"
                        }
                        
                        if ($needsUnload) {
                            [System.GC]::Collect()
                            reg unload "HKU\$sid" 2>&1 | Out-Null
                        }
                    }
            } else {
                # Standard behavior (Original Logic)
                if (($psitem.Path -imatch "hku") -and !(Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
                    $null = (New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS)
                    if (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue) {
                        Write-Debug "HKU drive created successfully"
                    } else {
                        Write-Debug "Failed to create HKU drive"
                    }
                }
                Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
            }
        }
    }
    if($sync.configs.tweaks.$CheckBox.$($values.ScriptType)) {
        $sync.configs.tweaks.$CheckBox.$($values.ScriptType) | ForEach-Object {
            Write-Debug "$($psitem) and state is $($psitem.$($values.ScriptType))"
            $Scriptblock = [scriptblock]::Create($psitem)
            Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
        }
    }

    if(!$undo) {
        if($sync.configs.tweaks.$CheckBox.appx) {
            $sync.configs.tweaks.$CheckBox.appx | ForEach-Object {
                Write-Debug "UNDO $($psitem.Name)"
                Remove-WinUtilAPPX -Name $psitem
            }
        }

    }
}
