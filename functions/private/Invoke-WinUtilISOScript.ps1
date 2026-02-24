function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Applies WinUtil modifications to a mounted Windows 11 install.wim image.

    .DESCRIPTION
        Performs the following operations against an already-mounted WIM image:

        1. Removes provisioned AppX bloatware packages via DISM.
        2. Removes OneDriveSetup.exe from the system image.
        3. Loads offline registry hives (COMPONENTS, DEFAULT, NTUSER, SOFTWARE, SYSTEM)
           and applies the following tweaks:
             - Bypasses hardware requirement checks (CPU, RAM, SecureBoot, Storage, TPM).
             - Disables sponsored-app delivery and ContentDeliveryManager features.
             - Enables local-account OOBE path (BypassNRO).
             - Writes autounattend.xml to the Sysprep directory inside the WIM and,
               optionally, to the ISO/USB root so Windows Setup picks it up at boot.
             - Disables reserved storage.
             - Disables BitLocker device encryption.
             - Hides the Chat (Teams) taskbar icon.
             - Disables OneDrive folder backup (KFM).
             - Disables telemetry, advertising ID, and input personalization.
             - Blocks post-install delivery of DevHome, Outlook, and Teams.
             - Disables Windows Copilot.
             - Disables Windows Update during OOBE.
        4. Deletes unwanted scheduled-task XML definition files (CEIP, Appraiser, etc.).
        5. Removes the support\ folder from the ISO contents directory (if supplied).

        Mounting and dismounting the WIM is the responsibility of the caller
        (e.g. Invoke-WinUtilISO).

    .PARAMETER ScratchDir
        Mandatory. Full path to the directory where the Windows image is currently mounted.
        Example: C:\Users\USERNAME\AppData\Local\Temp\WinUtil_Win11ISO_20260222\wim_mount

    .PARAMETER ISOContentsDir
        Optional. Root directory of the extracted ISO contents.
        When supplied, autounattend.xml is also written here so Windows Setup picks it
        up automatically at boot, and the support\ folder is deleted from that location.

    .PARAMETER AutoUnattendXml
        Optional. Full XML content for autounattend.xml.
        In compiled winutil.ps1 this is the embedded $WinUtilAutounattendXml here-string;
        in dev mode it is read from tools\autounattend.xml.
        If empty, the OOBE bypass file is skipped and a warning is logged.

    .PARAMETER Log
        Optional ScriptBlock used for progress/status logging.
        Receives a single [string] message argument.
        Defaults to { param($m) Write-Output $m } when not supplied.

    .EXAMPLE
        Invoke-WinUtilISOScript -ScratchDir "C:\Temp\wim_mount"

    .EXAMPLE
        Invoke-WinUtilISOScript `
            -ScratchDir      $mountDir `
            -ISOContentsDir  $isoRoot `
            -AutoUnattendXml (Get-Content .\tools\autounattend.xml -Raw) `
            -Log             { param($m) Write-Host $m }

    .NOTES
        Author  : Chris Titus @christitustech
        GitHub  : https://github.com/ChrisTitusTech
        Version : 26.02.22
    #>
    param (
        [Parameter(Mandatory)][string]$ScratchDir,
        # Root directory of the extracted ISO contents. When supplied, autounattend.xml
        # is written here so Windows Setup picks it up automatically at boot.
        [string]$ISOContentsDir = "",
        # Autounattend XML content. In compiled winutil.ps1 this comes from the embedded
        # $WinUtilAutounattendXml here-string; in dev mode it is read from tools\autounattend.xml.
        [string]$AutoUnattendXml = "",
        [scriptblock]$Log = { param($m) Write-Output $m }
    )

    # ── Resolve admin group name (for takeown / icacls) ──────────────────────
    $adminSID   = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])

    # ── Local helpers ─────────────────────────────────────────────────────────
    function Set-ISOScriptReg {
        param ([string]$path, [string]$name, [string]$type, [string]$value)
        try {
            & reg add $path /v $name /t $type /d $value /f
            & $Log "Set registry value: $path\$name"
        } catch {
            & $Log "Error setting registry value: $_"
        }
    }

    function Remove-ISOScriptReg {
        param ([string]$path)
        try {
            & reg delete $path /f
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
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftCorporationII.QuickAssist',
        'MSTeams',
        'MicrosoftTeams'
    )

    $packagesToRemove = $packages | Where-Object {
        $pkg = $_
        $packagePrefixes | Where-Object { $pkg -like "*$_*" }
    }
    foreach ($package in $packagesToRemove) {
        & dism /English "/image:$ScratchDir" /Remove-ProvisionedAppxPackage "/PackageName:$package"
    }

    # ═════════════════════════════════════════════════════════════════════════
    #  2. Remove OneDrive
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Removing OneDrive..."
    & takeown /f "$ScratchDir\Windows\System32\OneDriveSetup.exe" | Out-Null
    & icacls    "$ScratchDir\Windows\System32\OneDriveSetup.exe" /grant "$($adminGroup.Value):(F)" /T /C | Out-Null
    Remove-Item -Path "$ScratchDir\Windows\System32\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue

    # ═════════════════════════════════════════════════════════════════════════
    #  3. Registry tweaks
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Loading offline registry hives..."
    reg load HKLM\zCOMPONENTS "$ScratchDir\Windows\System32\config\COMPONENTS"
    reg load HKLM\zDEFAULT    "$ScratchDir\Windows\System32\config\default"
    reg load HKLM\zNTUSER     "$ScratchDir\Users\Default\ntuser.dat"
    reg load HKLM\zSOFTWARE   "$ScratchDir\Windows\System32\config\SOFTWARE"
    reg load HKLM\zSYSTEM     "$ScratchDir\Windows\System32\config\SYSTEM"

    & $Log "Bypassing system requirements..."
    Set-ISOScriptReg 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'  'SV1' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'  'SV2' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck'       'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck'       'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck'   'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck'       'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSYSTEM\Setup\MoSetup'   'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'

    & $Log "Disabling sponsored apps..."
    Set-ISOScriptReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled'  'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled'     'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled'  'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed'      'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled'    'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled'          'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled'    'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\MRT'           'DontOfferThroughWUAU' 'REG_DWORD' '1'
    Remove-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
    Remove-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent'       'REG_DWORD' '1'

    & $Log "Enabling local accounts on OOBE..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'

    if ($AutoUnattendXml) {
        # ── Place autounattend.xml inside the WIM (Sysprep) ──────────────────
        $sysprepDest = "$ScratchDir\Windows\System32\Sysprep\autounattend.xml"
        Set-Content -Path $sysprepDest -Value $AutoUnattendXml -Encoding UTF8 -Force
        & $Log "Written autounattend.xml to Sysprep directory."

        # ── Place autounattend.xml at the ISO / USB root ──────────────────────
        # Windows Setup reads this file first (before booting into the OS),
        # which is what drives the local-account / OOBE bypass at install time.
        if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
            $isoDest = Join-Path $ISOContentsDir "autounattend.xml"
            Set-Content -Path $isoDest -Value $AutoUnattendXml -Encoding UTF8 -Force
            & $Log "Written autounattend.xml to ISO root ($isoDest)."
        }
    } else {
        & $Log "Warning: autounattend.xml content is empty — skipping OOBE bypass file."
    }

    & $Log "Disabling reserved storage..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'

    & $Log "Disabling BitLocker device encryption..."
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'

    & $Log "Disabling Chat icon..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    Set-ISOScriptReg 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'

    & $Log "Disabling OneDrive folder backup..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 'REG_DWORD' '1'

    & $Log "Disabling telemetry..."
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection'  'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'

    & $Log "Preventing installation of DevHome and Outlook..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate'      'workCompleted' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate'      'workCompleted' 'REG_DWORD' '1'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

    & $Log "Disabling Copilot..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot'    'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Edge'                   'HubsSidebarEnabled'        'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer'       'DisableSearchBoxSuggestions' 'REG_DWORD' '1'

    & $Log "Disabling Windows Update during OOBE (re-enabled on first logon via FirstLogon.ps1)..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate'              'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions'                 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer'               'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'    'DisableWindowsUpdateAccess' 'REG_DWORD' '1'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'    'WUServer'                  'REG_SZ'    'http://localhost:8080'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'    'WUStatusServer'            'REG_SZ'    'http://localhost:8080'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' 'workCompleted' 'REG_DWORD' '1'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate'
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 'REG_DWORD' '0'
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Services\BITS'         'Start' 'REG_DWORD' '4'
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv'     'Start' 'REG_DWORD' '4'
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc'       'Start' 'REG_DWORD' '4'
    Set-ISOScriptReg 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSvc' 'Start' 'REG_DWORD' '4'

    & $Log "Preventing installation of Teams..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'

    & $Log "Preventing installation of new Outlook..."
    Set-ISOScriptReg 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'

    & $Log "Unloading offline registry hives..."
    reg unload HKLM\zCOMPONENTS
    reg unload HKLM\zDEFAULT
    reg unload HKLM\zNTUSER
    reg unload HKLM\zSOFTWARE
    reg unload HKLM\zSYSTEM

    # ═════════════════════════════════════════════════════════════════════════
    #  4. Delete scheduled task definition files
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Deleting scheduled task definition files..."
    $tasksPath = "$ScratchDir\Windows\System32\Tasks"

    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program"                  -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater"               -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Chkdsk\Proxy"                                            -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting"                  -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\InstallService"                                          -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\UpdateOrchestrator"                                      -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\UpdateAssistant"                                         -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\WaaSMedic"                                               -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\Windows\WindowsUpdate"                                           -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tasksPath\Microsoft\WindowsUpdate"                                                   -Recurse -Force -ErrorAction SilentlyContinue

    & $Log "Scheduled task files deleted."

    # ═════════════════════════════════════════════════════════════════════════
    #  5. Remove ISO support folder (fresh-install only; not needed)
    # ═════════════════════════════════════════════════════════════════════════
    if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
        & $Log "Removing ISO support\ folder..."
        Remove-Item -Path (Join-Path $ISOContentsDir "support") -Recurse -Force -ErrorAction SilentlyContinue
        & $Log "ISO support\ folder removed."
    }
}
