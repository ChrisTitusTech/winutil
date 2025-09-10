function Invoke-WPFUpdatesdefault {
    <#

    .SYNOPSIS
        Resets Windows Update settings to default

    #>

    Write-Host "Restoring Windows Update registry settings..." -ForegroundColor Yellow

    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 3
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1

    # Reset WaaSMedicSvc registry settings to defaults
    Write-Host "Restoring WaaSMedicSvc settings..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Type DWord -Value 3 -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "FailureActions" -ErrorAction SilentlyContinue

    # Restore update services to their default state
    Write-Host "Restoring update services..." -ForegroundColor Yellow

    $services = @(
        @{Name = "BITS"; StartupType = "Manual"},
        @{Name = "wuauserv"; StartupType = "Manual"},
        @{Name = "UsoSvc"; StartupType = "Automatic"},
        @{Name = "uhssvc"; StartupType = "Disabled"},
        @{Name = "WaaSMedicSvc"; StartupType = "Manual"}
    )

    foreach ($service in $services) {
        try {
            Write-Host "Restoring $($service.Name) to $($service.StartupType)..."
            $serviceObj = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($serviceObj) {
                Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue

                # Reset failure actions to default using sc command
                Start-Process -FilePath "sc.exe" -ArgumentList "failure `"$($service.Name)`" reset= 86400 actions= restart/60000/restart/60000/restart/60000" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

                # Start the service if it should be running
                if ($service.StartupType -eq "Automatic") {
                    Start-Service -Name $service.Name -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            Write-Host "Warning: Could not restore service $($service.Name) - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Restore renamed DLLs if they exist
    Write-Host "Restoring renamed update service DLLs..." -ForegroundColor Yellow

    $dlls = @("WaaSMedicSvc", "wuaueng")

    foreach ($dll in $dlls) {
        $dllPath = "C:\Windows\System32\$dll.dll"
        $backupPath = "C:\Windows\System32\${dll}_BAK.dll"

        if ((Test-Path $backupPath) -and !(Test-Path $dllPath)) {
            try {
                # Take ownership of backup file
                Start-Process -FilePath "takeown.exe" -ArgumentList "/f `"$backupPath`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

                # Grant full control to everyone
                Start-Process -FilePath "icacls.exe" -ArgumentList "`"$backupPath`" /grant *S-1-1-0:F" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

                # Rename back to original
                Rename-Item -Path $backupPath -NewName "$dll.dll" -ErrorAction SilentlyContinue
                Write-Host "Restored ${dll}_BAK.dll to $dll.dll"

                # Restore ownership to TrustedInstaller
                Start-Process -FilePath "icacls.exe" -ArgumentList "`"$dllPath`" /setowner `"NT SERVICE\TrustedInstaller`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                Start-Process -FilePath "icacls.exe" -ArgumentList "`"$dllPath`" /remove *S-1-1-0" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Warning: Could not restore $dll.dll - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    # Enable update related scheduled tasks
    Write-Host "Enabling update related scheduled tasks..." -ForegroundColor Yellow

    $taskPaths = @(
        '\Microsoft\Windows\InstallService\*'
        '\Microsoft\Windows\UpdateOrchestrator\*'
        '\Microsoft\Windows\UpdateAssistant\*'
        '\Microsoft\Windows\WaaSMedic\*'
        '\Microsoft\Windows\WindowsUpdate\*'
        '\Microsoft\WindowsUpdate\*'
    )

    foreach ($taskPath in $taskPaths) {
        try {
            $tasks = Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue
            foreach ($task in $tasks) {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
                Write-Host "Enabled task: $($task.TaskName)"
            }
        }
        catch {
            Write-Host "Warning: Could not enable tasks in path $taskPath - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host "Enabling driver offering through Windows Update..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
    Write-Host "Enabling Windows Update automatic restart..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -ErrorAction SilentlyContinue
    Write-Host "Enabled driver offering through Windows Update"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays" -ErrorAction SilentlyContinue

    Write-Host "==================================================="
    Write-Host "---  Windows Update Settings Reset to Default   ---"
    Write-Host "==================================================="

    Start-Process -FilePath "secedit" -ArgumentList "/configure /cfg $env:windir\inf\defltbase.inf /db defltbase.sdb /verbose" -Wait
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c RD /S /Q $env:WinDir\System32\GroupPolicyUsers" -Wait
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c RD /S /Q $env:WinDir\System32\GroupPolicy" -Wait
    Start-Process -FilePath "gpupdate" -ArgumentList "/force" -Wait
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Microsoft\WindowsSelfHost" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Microsoft\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Microsoft\WindowsSelfHost" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\WOW6432Node\Microsoft\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "==================================================="
    Write-Host "---  Windows Local Policies Reset to Default   ---"
    Write-Host "==================================================="

    Write-Host "Note: A system restart may be required for all changes to take full effect." -ForegroundColor Yellow
}
