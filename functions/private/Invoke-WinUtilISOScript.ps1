function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Applies the standard WinUtil modifications to a mounted Windows 11 install.wim image.

    .DESCRIPTION
        Removes bloatware AppX packages, Edge, OneDrive, applies privacy/telemetry
        registry tweaks, disables sponsored-app delivery, bypasses hardware checks,
        copies autounattend.xml for local-account OOBE, and deletes unwanted
        scheduled-task definition files — all against an already-mounted WIM image.

        Mounting and dismounting the WIM is the responsibility of the caller
        (e.g. Invoke-WinUtilISOModify).

    .PARAMETER ScratchDir
        Full path to the directory where the Windows image is currently mounted
        (the "scratchdir").  Example: C:\Temp\WinUtil_Win11ISO_20260222\wim_mount

    .PARAMETER Log
        Optional ScriptBlock used for progress/status logging.
        Receives a single [string] message argument.
        Defaults to Write-Output when not supplied.

    .EXAMPLE
        Invoke-WinUtilISOScript -ScratchDir "C:\Temp\wim_mount"
        Invoke-WinUtilISOScript -ScratchDir $mountDir -Log { param($m) Write-Host $m }

    .NOTES
        Author  : Chris Titus @christitustech
        GitHub  : https://github.com/ChrisTitusTech
        Version : 26.02.22
    #>
    param (
        [Parameter(Mandatory)][string]$ScratchDir,
        [scriptblock]$Log = { param($m) Write-Output $m }
    )

    # ── Resolve admin group name (for takeown / icacls) ──────────────────────
    $adminSID   = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])

    # ── Local helpers ─────────────────────────────────────────────────────────
    function _ISOScript-SetReg {
        param ([string]$path, [string]$name, [string]$type, [string]$value)
        try {
            & reg add $path /v $name /t $type /d $value /f | Out-Null
            & $Log "Set registry value: $path\$name"
        } catch {
            & $Log "Error setting registry value: $_"
        }
    }

    function _ISOScript-DelReg {
        param ([string]$path)
        try {
            & reg delete $path /f | Out-Null
            & $Log "Removed registry key: $path"
        } catch {
            & $Log "Error removing registry key: $_"
        }
    }

    # ═════════════════════════════════════════════════════════════════════════
    #  1. Remove provisioned AppX packages
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Removing provisioned AppX packages..."

    $packages = & dism /English "/image:$ScratchDir" /Get-ProvisionedAppxPackages |
        ForEach-Object {
            if ($_ -match 'PackageName : (.*)') { $matches[1] }
        }

    $packagePrefixes = @(
        'AppUp.IntelManagementandSecurityStatus',
        'Clipchamp.Clipchamp',
        'DolbyLaboratories.DolbyAccess',
        'DolbyLaboratories.DolbyDigitalPlusDecoderOEM',
        'Microsoft.BingNews',
        'Microsoft.BingSearch',
        'Microsoft.BingWeather',
        'Microsoft.Copilot',
        'Microsoft.Windows.CrossDevice',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.MixedReality.Portal',
        'Microsoft.MSPaint',
        'Microsoft.Office.OneNote',
        'Microsoft.OfficePushNotificationUtility',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.SkypeApp',
        'Microsoft.StartExperiencesApp',
        'Microsoft.Todos',
        'Microsoft.Wallet',
        'Microsoft.Windows.DevHome',
        'Microsoft.Windows.Copilot',
        'Microsoft.Windows.Teams',
        'Microsoft.WindowsAlarms',
        'Microsoft.WindowsCamera',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.WindowsTerminal',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftCorporationII.QuickAssist',
        'MSTeams',
        'MicrosoftTeams',
        'Microsoft.549981C3F5F10'
    )

    $packagesToRemove = $packages | Where-Object {
        $pkg = $_
        $packagePrefixes | Where-Object { $pkg -like "*$_*" }
    }
    foreach ($package in $packagesToRemove) {
        & dism /English "/image:$ScratchDir" /Remove-ProvisionedAppxPackage "/PackageName:$package"
    }

    # ═════════════════════════════════════════════════════════════════════════
    #  2. Remove Edge
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Removing Edge..."
    Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\Edge"       -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\EdgeUpdate"  -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\EdgeCore"    -Recurse -Force -ErrorAction SilentlyContinue
    & takeown /f "$ScratchDir\Windows\System32\Microsoft-Edge-Webview" /r | Out-Null
    & icacls    "$ScratchDir\Windows\System32\Microsoft-Edge-Webview" /grant "$($adminGroup.Value):(F)" /T /C | Out-Null
    Remove-Item -Path "$ScratchDir\Windows\System32\Microsoft-Edge-Webview"   -Recurse -Force -ErrorAction SilentlyContinue

    # ═════════════════════════════════════════════════════════════════════════
    #  3. Remove OneDrive
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Removing OneDrive..."
    & takeown /f "$ScratchDir\Windows\System32\OneDriveSetup.exe" | Out-Null
    & icacls    "$ScratchDir\Windows\System32\OneDriveSetup.exe" /grant "$($adminGroup.Value):(F)" /T /C | Out-Null
    Remove-Item -Path "$ScratchDir\Windows\System32\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue

    # ═════════════════════════════════════════════════════════════════════════
    #  4. Registry tweaks
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Loading offline registry hives..."
    reg load HKLM\zCOMPONENTS "$ScratchDir\Windows\System32\config\COMPONENTS" | Out-Null
    reg load HKLM\zDEFAULT    "$ScratchDir\Windows\System32\config\default"    | Out-Null
    reg load HKLM\zNTUSER     "$ScratchDir\Users\Default\ntuser.dat"            | Out-Null
    reg load HKLM\zSOFTWARE   "$ScratchDir\Windows\System32\config\SOFTWARE"   | Out-Null
    reg load HKLM\zSYSTEM     "$ScratchDir\Windows\System32\config\SYSTEM"     | Out-Null

    & $Log "Bypassing system requirements..."
    _ISOScript-SetReg 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'  'SV1' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'  'SV2' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck'       'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck'       'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck'   'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck'       'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSYSTEM\Setup\MoSetup'   'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'

    & $Log "Disabling sponsored apps..."
    _ISOScript-SetReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled'  'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled'     'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled'  'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed'      'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled'    'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled'          'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled'    'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\MRT'           'DontOfferThroughWUAU' 'REG_DWORD' '1'
    _ISOScript-DelReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
    _ISOScript-DelReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent'       'REG_DWORD' '1'

    & $Log "Enabling local accounts on OOBE..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'

    $sysprepDest = "$ScratchDir\Windows\System32\Sysprep\autounattend.xml"
    Set-Content -Path $sysprepDest -Value $WinUtilAutounattendXml -Encoding UTF8 -Force
    & $Log "Written autounattend.xml to Sysprep directory."

    & $Log "Disabling reserved storage..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'

    & $Log "Disabling BitLocker device encryption..."
    _ISOScript-SetReg 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'

    & $Log "Disabling Chat icon..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    _ISOScript-SetReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'

    & $Log "Removing Edge registry entries..."
    _ISOScript-DelReg 'HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
    _ISOScript-DelReg 'HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update'

    & $Log "Disabling OneDrive folder backup..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 'REG_DWORD' '1'

    & $Log "Disabling telemetry..."
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection'  'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'

    & $Log "Preventing installation of DevHome and Outlook..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate'      'workCompleted' 'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate'      'workCompleted' 'REG_DWORD' '1'
    _ISOScript-DelReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
    _ISOScript-DelReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

    & $Log "Disabling Copilot..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot'    'REG_DWORD' '1'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Edge'                   'HubsSidebarEnabled'        'REG_DWORD' '0'
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer'       'DisableSearchBoxSuggestions' 'REG_DWORD' '1'

    & $Log "Preventing installation of Teams..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'

    & $Log "Preventing installation of new Outlook..."
    _ISOScript-SetReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'

    & $Log "Unloading offline registry hives..."
    reg unload HKLM\zCOMPONENTS | Out-Null
    reg unload HKLM\zDEFAULT    | Out-Null
    reg unload HKLM\zNTUSER     | Out-Null
    reg unload HKLM\zSOFTWARE   | Out-Null
    reg unload HKLM\zSYSTEM     | Out-Null

    # ═════════════════════════════════════════════════════════════════════════
    #  5. Delete scheduled task definition files
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Deleting scheduled task definition files..."
    $tasksPath = "$ScratchDir\Windows\System32\Tasks"

    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program"                  -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater"               -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Chkdsk\Proxy"                                            -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting"                  -Force -ErrorAction SilentlyContinue

    & $Log "Scheduled task files deleted."
}

