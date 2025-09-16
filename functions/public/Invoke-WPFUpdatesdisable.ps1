function Invoke-WPFUpdatesdisable {
    <#

    .SYNOPSIS
        Disables Windows Update

    .NOTES
        Disabling Windows Update is not recommended. This is only for advanced users who know what they are doing.
        This function requires administrator privileges and will attempt to run as SYSTEM for certain operations.

    #>

    Write-Host "Configuring registry settings..." -ForegroundColor Yellow

    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1

    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0

    # Additional registry settings
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Type DWord -Value 4 -ErrorAction SilentlyContinue
    $failureActions = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0xd4,0x01,0x00,0x00,0x00,0x00,0x00,0xe0,0x93,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "FailureActions" -Type Binary -Value $failureActions -ErrorAction SilentlyContinue

    # Disable and stop update related services
    Write-Host "Disabling update services..." -ForegroundColor Yellow

    $services = @(
        "BITS"
        "wuauserv"
        "UsoSvc"
        "uhssvc"
        "WaaSMedicSvc"
    )

    foreach ($service in $services) {
        try {
            Write-Host "Stopping and disabling $service..."
            $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($serviceObj) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue

                # Set failure actions to nothing using sc command
                Start-Process -FilePath "sc.exe" -ArgumentList "failure `"$service`" reset= 0 actions= `"`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "Warning: Could not process service $service - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Rename critical update service DLLs (requires SYSTEM privileges)
    Write-Host "Attempting to rename critical update service DLLs..." -ForegroundColor Yellow

    $dlls = @("WaaSMedicSvc", "wuaueng")

    foreach ($dll in $dlls) {
        $dllPath = "C:\Windows\System32\$dll.dll"
        $backupPath = "C:\Windows\System32\${dll}_BAK.dll"

        if (Test-Path $dllPath) {
            try {
                # Take ownership
                Start-Process -FilePath "takeown.exe" -ArgumentList "/f `"$dllPath`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

                # Grant full control to everyone
                Start-Process -FilePath "icacls.exe" -ArgumentList "`"$dllPath`" /grant *S-1-1-0:F" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

                # Rename file
                if (!(Test-Path $backupPath)) {
                    Rename-Item -Path $dllPath -NewName "${dll}_BAK.dll" -ErrorAction SilentlyContinue
                    Write-Host "Renamed $dll.dll to ${dll}_BAK.dll"

                    # Restore ownership to TrustedInstaller
                    Start-Process -FilePath "icacls.exe" -ArgumentList "`"$backupPath`" /setowner `"NT SERVICE\TrustedInstaller`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                    Start-Process -FilePath "icacls.exe" -ArgumentList "`"$backupPath`" /remove *S-1-1-0" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
            }
            catch {
                Write-Host "Warning: Could not rename $dll.dll - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    # Delete downloaded update files
    Write-Host "Cleaning up downloaded update files..." -ForegroundColor Yellow

    try {
        $softwareDistPath = "C:\Windows\SoftwareDistribution"
        if (Test-Path $softwareDistPath) {
            Get-ChildItem -Path $softwareDistPath -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "Cleared SoftwareDistribution folder"
        }
    }
    catch {
        Write-Host "Warning: Could not fully clear SoftwareDistribution folder - $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Disable update related scheduled tasks
    Write-Host "Disabling update related scheduled tasks..." -ForegroundColor Yellow

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
                Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
                Write-Host "Disabled task: $($task.TaskName)"
            }
        }
        catch {
            Write-Host "Warning: Could not disable tasks in path $taskPath - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host "=================================" -ForegroundColor Green
    Write-Host "---   Updates ARE DISABLED    ---" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    Write-Host "Note: Some operations may require a system restart to take full effect." -ForegroundColor Yellow
}
