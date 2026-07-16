function Invoke-WPFUpdatessecurity {
    <#

    .SYNOPSIS
        Sets Windows Update to recommended settings

    .DESCRIPTION
        1. Disables driver offering through Windows Update
        2. Defers feature updates for 365 days
        3. Defers quality updates for 4 days
        4. Prevents automatic restarts while a user is signed in

    #>

    Write-Host "Disabling driver offering through Windows Update..."
    Write-WinUtilLog -Component "Updates" -Message "Applying recommended Windows Update settings."
    Write-WinUtilLog -Component "Updates" -Message "Disabling driver offering through Windows Update."

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0

    $windowsUpdatePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $automaticUpdatePolicyPath = Join-Path $windowsUpdatePolicyPath "AU"

    New-Item -Path $windowsUpdatePolicyPath -Force
    Set-ItemProperty -Path $windowsUpdatePolicyPath -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1

    Write-Host "Deferring feature updates by 365 days and quality updates by 4 days..."
    Write-WinUtilLog -Component "Updates" -Message "Deferring feature updates by 365 days and quality updates by 4 days."

    Set-ItemProperty -Path $windowsUpdatePolicyPath -Name "DeferFeatureUpdates" -Type DWord -Value 1
    Set-ItemProperty -Path $windowsUpdatePolicyPath -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
    Set-ItemProperty -Path $windowsUpdatePolicyPath -Name "DeferQualityUpdates" -Type DWord -Value 1
    Set-ItemProperty -Path $windowsUpdatePolicyPath -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 4

    $legacySettingsPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    foreach ($legacyValue in @("BranchReadinessLevel", "DeferFeatureUpdatesPeriodInDays", "DeferQualityUpdatesPeriodInDays")) {
        Remove-ItemProperty -Path $legacySettingsPath -Name $legacyValue -ErrorAction SilentlyContinue
    }

    Write-Host "Preventing automatic restarts while users are signed in..."
    Write-WinUtilLog -Component "Updates" -Message "Configuring scheduled automatic updates without restarting while users are signed in."

    New-Item -Path $automaticUpdatePolicyPath -Force
    # NoAutoRebootWithLoggedOnUsers only applies when automatic updates use option 4.
    Set-ItemProperty -Path $automaticUpdatePolicyPath -Name "AUOptions" -Type DWord -Value 4
    Set-ItemProperty -Path $automaticUpdatePolicyPath -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
    Set-ItemProperty -Path $automaticUpdatePolicyPath -Name "AUPowerManagement" -Type DWord -Value 0

    Write-Host "================================="
    Write-Host "-- Updates Set to Recommended ---"
    Write-Host "================================="
    Write-WinUtilLog -Component "Updates" -Message "Recommended Windows Update settings workflow completed."
}
