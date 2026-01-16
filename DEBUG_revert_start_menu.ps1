$FEATURE_ID = "3036241548"
$BASE_PATH = "HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides"

$NOT_CONFIGURED = 0
$DISABLED = 1
$ENABLED = 2

function setKeyValueAsTI {
    param(
        [string]$registryPath,
        $value
    )

    $COMMAND = "Set-ItemProperty -Path 'Registry::$registryPath' -Name 'EnabledState' -Value $value -Type DWord -Force -ErrorAction Stop"

    Register-ScheduledTask -TaskName "ti" -Action (New-ScheduledTaskAction -Execute "powershell" `
        -Argument "-Command `"$COMMAND`"") `
        -User 'NT SERVICE\TrustedInstaller' -Force
    
    # Let the task run until it is complete or until 10 seconds pass (fail), whichever comes first
    $TIMEOUT = 10
    $elapsed = 0
    Start-ScheduledTask -TaskName "ti"
    while((Get-ScheduledTask -TaskName "ti").state -ne "Ready" -and $elapsed -lt $TIMEOUT) {
        Start-Sleep -Milliseconds 100
        $elapsed += 0.1
    }

    Unregister-ScheduledTask -TaskName "ti" -Confirm:$false
    if ($elapsed -ge 10) {
        throw "Could not set key value for '$registryPath' as TrustedInstaller"
    }
}

# Check if the feature override exists
$configurationPriority = Get-ChildItem -Path $BASE_PATH | Where-Object {
    Test-Path -Path (Join-Path $_.PSPath $FEATURE_ID)
}

if ($configurationPriority) {
    Write-Host "Override found at: $($configurationPriority)"
    $targetPath = Join-Path $configurationPriority $FEATURE_ID

    $currentState = (Get-ItemProperty -Path "Registry::$targetPath" -Name "EnabledState" -ErrorAction Stop).EnabledState
    if (($currentState -eq $ENABLED) -or ($currentState -eq $NOT_CONFIGURED)) {
        try {
            setKeyValueAsTI -registryPath $targetPath -value $DISABLED
            "New start menu layout disabled", "Please restart your computer for the changes to apply!" | Write-Host
        } catch {
            Write-Error "Could not set key value: $_"
        }
    } elseif ($currentState -eq $DISABLED) {
        try {
            setKeyValueAsTI -registryPath $targetPath -value $ENABLED
            "New start menu layout enabled", "Please restart your computer for the changes to apply!" | Write-Host
        } catch {
            Write-Error "Could not set key value: $_"
        }
    } else {
        Write-Error "Unexpected state value"
    }

} else {
    Write-Error "Feature override not present"
}