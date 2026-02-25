function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Applies WinUtil modifications to a mounted Windows 11 install.wim image.

    .DESCRIPTION
        Removes AppX bloatware and OneDrive, injects hardware drivers (NVMe, Precision
        Touchpad/HID, and network) exported from the running system, optionally injects
        extended Storage & Network drivers from the ChrisTitusTech/storage-lan-drivers
        repository (requires git, installed via winget if absent), applies offline registry
        tweaks (hardware bypass, privacy, OOBE, telemetry, update suppression), deletes
        CEIP/WU scheduled-task definition files, and optionally drops autounattend.xml and
        removes the support\ folder from the ISO contents directory.
        Mounting/dismounting the WIM is the caller's responsibility (e.g. Invoke-WinUtilISO).

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
        Version : 26.02.25b
    #>
    param (
        [Parameter(Mandatory)][string]$ScratchDir,
        [string]$ISOContentsDir = "",
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
    #  2. Inject hardware drivers (NVMe / Trackpad / Network)
    # ═════════════════════════════════════════════════════════════════════════
    & $Log "Exporting hardware drivers from running system (NVMe, HID/Trackpad, Network)..."

    $driverExportRoot = Join-Path $env:TEMP "WinUtil_DriverExport_$(Get-Random)"
    New-Item -Path $driverExportRoot -ItemType Directory -Force | Out-Null

    try {
        # Export every online driver to the temp folder.
        # Export-WindowsDriver creates one sub-folder per .inf package.
        Export-WindowsDriver -Online -Destination $driverExportRoot | Out-Null

        # Driver classes to inject:
        #   SCSIAdapter - NVMe / AHCI storage controllers
        #   HIDClass    - Precision Touchpad and HID devices
        #   Net         - Ethernet and Wi-Fi adapters
        $targetClasses = @('SCSIAdapter', 'HIDClass', 'Net')

        $targetInfBases = Get-WindowsDriver -Online |
            Where-Object { $_.ClassName -in $targetClasses } |
            ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.OriginalFileName) } |
            Select-Object -Unique

        $injected = 0
        foreach ($infBase in $targetInfBases) {
            $infFile = Get-ChildItem -Path $driverExportRoot -Filter "$infBase.inf" `
                           -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($infFile) {
                & dism /English "/image:$ScratchDir" /Add-Driver "/Driver:$($infFile.FullName)"
                $injected++
            } else {
                & $Log "Warning: exported .inf not found for '$infBase' — skipped."
            }
        }

        & $Log "Driver injection complete - $injected driver package(s) added."
    } catch {
        & $Log "Error during driver export/injection: $_"
    } finally {
        Remove-Item -Path $driverExportRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ── 2b. Optional: extended Storage & Network drivers from community repo ──
    $extDriverChoice = [System.Windows.MessageBox]::Show(
        "Would you like to add extended Storage and Network drivers?`n`n" +
        "This installs EVERY Storage and Networking device driver" +
        "in EXISTANCE into the image. (~1000 drivers)`n`n" +
        "No Wireless drivers only Ethernet, use for stubborn systems " +
        "with unsupported NVMe or Ethernet controllers." +,
        "Extended Drivers", "YesNo", "Question")

    if ($extDriverChoice -eq 'Yes') {
        & $Log "Extended driver injection requested."

        # Ensure git is available
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            & $Log "Git not found — installing via winget..."
            winget install --id Git.Git -e --source winget `
                --accept-package-agreements --accept-source-agreements | Out-Null
            # Refresh PATH so git is visible in this session
            $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                        [System.Environment]::GetEnvironmentVariable('PATH', 'User')
            $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        }

        if (-not $gitCmd) {
            & $Log "Warning: git could not be found after install attempt — skipping extended drivers."
        } else {
            $extRepoDir = Join-Path $env:TEMP "WinUtil_ExtDrivers_$(Get-Random)"
            try {
                & $Log "Cloning storage-lan-drivers repository..."
                & git clone --depth 1 `
                    "https://github.com/ChrisTitusTech/storage-lan-drivers" `
                    $extRepoDir 2>&1 | ForEach-Object { & $Log "  git: $_" }

                if (Test-Path $extRepoDir) {
                    & $Log "Injecting extended drivers into image (this may take several minutes)..."
                    & dism /English "/image:$ScratchDir" /Add-Driver "/Driver:$extRepoDir" /Recurse 2>&1 |
                        ForEach-Object { & $Log "  dism: $_" }
                    & $Log "Extended driver injection complete."
                } else {
                    & $Log "Warning: repository clone directory not found — skipping extended drivers."
                }
            } catch {
                & $Log "Error during extended driver injection: $_"
            } finally {
                Remove-Item -Path $extRepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        & $Log "Extended driver injection skipped."
    }

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
    #  5. Delete scheduled task definition files
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
    #  6. Remove ISO support folder (fresh-install only; not needed)
    # ═════════════════════════════════════════════════════════════════════════
    if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
        & $Log "Removing ISO support\ folder..."
        Remove-Item -Path (Join-Path $ISOContentsDir "support") -Recurse -Force -ErrorAction SilentlyContinue
        & $Log "ISO support\ folder removed."
    }
}
