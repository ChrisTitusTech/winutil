function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Applies WinUtil modifications to a mounted Windows 11 install.wim image.

    .DESCRIPTION
        Removes AppX bloatware and OneDrive, optionally injects all drivers exported from
        the running system into install.wim and boot.wim (controlled by the
        -InjectCurrentSystemDrivers switch), applies offline registry tweaks (hardware
        bypass, privacy, OOBE, telemetry, update suppression), deletes CEIP/WU
        scheduled-task definition files, and optionally writes autounattend.xml to the ISO
        root and removes the support\ folder from the ISO contents directory.

        All setup scripts embedded in the autounattend.xml <Extensions><File> nodes are
        written directly into the WIM at their target paths under C:\Windows\Setup\Scripts\
        to ensure they survive Windows Setup stripping unrecognised-namespace XML elements
        from the Panther copy of the answer file.

        Mounting/dismounting the WIM is the caller's responsibility (e.g. Invoke-WinUtilISO).

    .PARAMETER ScratchDir
        Mandatory. Full path to the directory where the Windows image is currently mounted.

    .PARAMETER ISOContentsDir
        Optional. Root directory of the extracted ISO contents. When supplied,
        autounattend.xml is written here and the support\ folder is removed.

    .PARAMETER AutoUnattendXml
        Optional. Full XML content for autounattend.xml. If empty, the OOBE bypass
        file is skipped and a warning is logged.

    .PARAMETER InjectCurrentSystemDrivers
        Optional. When $true, exports all drivers from the running system and injects
        them into install.wim and boot.wim index 2 (Windows Setup PE).
        Defaults to $false.

    .PARAMETER InstallEditionId
        Optional. Windows edition ID for the selected image, for example Professional
        or Core. Used to write sources\ei.cfg so setup does not fall back to an
        embedded firmware product key for a different edition.

    .PARAMETER InstallImageIndex
        Optional. Image index that setup should install from the final install.wim.
        Win11 Creator exports the selected edition to a single-image WIM, so this
        defaults to 1.

    .PARAMETER Log
        Optional ScriptBlock for progress/status logging. Receives a single [string] argument.

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
    #>
    param (
        [Parameter(Mandatory)][string]$ScratchDir,
        [string]$ISOContentsDir = "",
        [string]$AutoUnattendXml = "",
        [bool]$InjectCurrentSystemDrivers = $false,
        [string]$InstallEditionId = "",
        [int]$InstallImageIndex = 1,
        [scriptblock]$Log = { param($m) Write-Output $m }
    )
    function Set-ISOScriptReg {
        param ([string]$Path, [string]$Name, [string]$Type, [string]$Value)
        try {
            & reg add $Path /v $Name /t $Type /d $Value /f
            & $Log "Set registry value: $Path\$Name"
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

    function Add-DriversToImage {
        param ([string]$MountPath, [string]$DriverDir, [string]$Label = "image", [scriptblock]$Logger)
        & dism /English "/image:$MountPath" /Add-Driver "/Driver:$DriverDir" /Recurse |
            ForEach-Object { & $Logger "  dism[$Label]: $_" }
    }

    function Invoke-BootWimInject {
        param ([string]$BootWimPath, [string]$DriverDir, [scriptblock]$Logger)
        Set-ItemProperty -Path $BootWimPath -Name IsReadOnly -Value $false
        $mountDir = Join-Path $env:TEMP "WinUtil_BootMount_$(Get-Random)"
        New-Item -Path $mountDir -ItemType Directory -Force
        try {
            & $Logger "Mounting boot.wim (index 2) for driver injection..."
            Mount-WindowsImage -ImagePath $BootWimPath -Index 2 -Path $mountDir
            Add-DriversToImage -MountPath $mountDir -DriverDir $DriverDir -Label "boot" -Logger $Logger
            & $Logger "Saving boot.wim..."
            Dismount-WindowsImage -Path $mountDir -Save
            & $Logger "boot.wim driver injection complete."
        } catch {
            & $Logger "Warning: boot.wim driver injection failed: $_"
            try { Dismount-WindowsImage -Path $mountDir -Discard } catch { & $Logger "Warning: could not discard boot.wim mount: $_" }
        } finally {
            Remove-Item -Path $mountDir -Recurse -Force
        }
    }

    function Get-WinUtilISOScriptChildElement {
        param (
            [Parameter(Mandatory)][System.Xml.XmlElement]$Parent,
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][string]$NamespaceUri
        )

        foreach ($childNode in $Parent.ChildNodes) {
            if ($childNode.NodeType -eq [System.Xml.XmlNodeType]::Element -and
                $childNode.LocalName -eq $Name -and
                $childNode.NamespaceURI -eq $NamespaceUri) {
                return [System.Xml.XmlElement]$childNode
            }
        }

        $childElement = $Parent.OwnerDocument.CreateElement($Name, $NamespaceUri)
        [void]$Parent.AppendChild($childElement)
        return $childElement
    }

    function ConvertTo-WinUtilISOAnswerFile {
        param (
            [Parameter(Mandatory)][string]$XmlContent,
            [int]$ImageIndex = 1
        )

        if ($ImageIndex -lt 1) { $ImageIndex = 1 }

        $unattendNs = "urn:schemas-microsoft-com:unattend"
        $wcmNs = "http://schemas.microsoft.com/WMIConfig/2002/State"

        $xmlDoc = [xml]::new()
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.LoadXml($XmlContent)

        if ($xmlDoc.DocumentElement.NamespaceURI -ne $unattendNs) {
            throw "Unexpected autounattend.xml namespace: $($xmlDoc.DocumentElement.NamespaceURI)"
        }

        if (-not $xmlDoc.DocumentElement.HasAttribute("xmlns:wcm")) {
            $xmlDoc.DocumentElement.SetAttribute("wcm", "http://www.w3.org/2000/xmlns/", $wcmNs)
        }

        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $nsMgr.AddNamespace("u", $unattendNs)

        $windowsPESettings = $xmlDoc.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]', $nsMgr)
        if (-not $windowsPESettings) {
            $windowsPESettings = $xmlDoc.CreateElement("settings", $unattendNs)
            $windowsPESettings.SetAttribute("pass", "windowsPE")
            [void]$xmlDoc.DocumentElement.PrependChild($windowsPESettings)
        }

        $setupComponent = $windowsPESettings.SelectSingleNode('u:component[@name="Microsoft-Windows-Setup"]', $nsMgr)
        if (-not $setupComponent) {
            $setupComponent = $xmlDoc.CreateElement("component", $unattendNs)
            $setupComponent.SetAttribute("name", "Microsoft-Windows-Setup")
            $setupComponent.SetAttribute("processorArchitecture", "amd64")
            $setupComponent.SetAttribute("publicKeyToken", "31bf3856ad364e35")
            $setupComponent.SetAttribute("language", "neutral")
            $setupComponent.SetAttribute("versionScope", "nonSxS")
            [void]$windowsPESettings.AppendChild($setupComponent)
        }

        $productKeyNodes = @($setupComponent.SelectNodes("u:UserData/u:ProductKey", $nsMgr))
        foreach ($productKeyNode in $productKeyNodes) {
            $keyNode = $productKeyNode.SelectSingleNode("u:Key", $nsMgr)
            $keyValue = if ($keyNode) { $keyNode.InnerText.Trim() } else { "" }

            if ([string]::IsNullOrWhiteSpace($keyValue) -or $keyValue -eq "00000-00000-00000-00000-00000") {
                [void]$productKeyNode.ParentNode.RemoveChild($productKeyNode)
            }
        }

        $imageInstall = Get-WinUtilISOScriptChildElement -Parent $setupComponent -Name "ImageInstall" -NamespaceUri $unattendNs
        $osImage = Get-WinUtilISOScriptChildElement -Parent $imageInstall -Name "OSImage" -NamespaceUri $unattendNs
        $installFrom = Get-WinUtilISOScriptChildElement -Parent $osImage -Name "InstallFrom" -NamespaceUri $unattendNs

        $existingMetadataNodes = @($installFrom.SelectNodes("u:MetaData", $nsMgr))
        foreach ($metadataNode in $existingMetadataNodes) {
            [void]$installFrom.RemoveChild($metadataNode)
        }

        $metadata = $xmlDoc.CreateElement("MetaData", $unattendNs)
        $actionAttribute = $xmlDoc.CreateAttribute("wcm", "action", $wcmNs)
        $actionAttribute.Value = "add"
        [void]$metadata.Attributes.Append($actionAttribute)

        $keyElement = $xmlDoc.CreateElement("Key", $unattendNs)
        $keyElement.InnerText = "/IMAGE/INDEX"
        [void]$metadata.AppendChild($keyElement)

        $valueElement = $xmlDoc.CreateElement("Value", $unattendNs)
        $valueElement.InnerText = [string]$ImageIndex
        [void]$metadata.AppendChild($valueElement)

        [void]$installFrom.AppendChild($metadata)

        return $xmlDoc.OuterXml
    }

    function Write-WinUtilISOEditionConfig {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [string]$EditionId,
            [scriptblock]$Logger
        )

        if (-not (Test-Path $ContentRoot)) {
            return
        }

        $sourcesDir = Join-Path $ContentRoot "sources"
        New-Item -Path $sourcesDir -ItemType Directory -Force | Out-Null

        $pidPath = Join-Path $sourcesDir "PID.txt"
        if (Test-Path $pidPath) {
            Remove-Item -Path $pidPath -Force
            & $Logger "Removed sources\PID.txt so setup will not force a stale or mismatched product key."
        }

        if ([string]::IsNullOrWhiteSpace($EditionId)) {
            & $Logger "Warning: selected edition ID is unknown - skipping sources\ei.cfg fallback."
            return
        }

        $eiCfgPath = Join-Path $sourcesDir "ei.cfg"
        $eiCfg = @"
[EditionID]
$EditionId
[Channel]
Retail
[VL]
0
"@.Trim()

        Set-Content -Path $eiCfgPath -Value $eiCfg -Encoding ASCII -Force
        & $Logger "Written sources\ei.cfg for EditionID '$EditionId'."
    }

    # -- 1. Remove provisioned AppX packages ----------------------------------
    & $Log "Removing provisioned AppX packages..."

    $packages = & dism /English "/image:$ScratchDir" /Get-ProvisionedAppxPackages |
        ForEach-Object { if ($_ -match 'PackageName : (.*)') { $matches[1] } }

    $packagePrefixes = @(
        'Clipchamp.Clipchamp',
        'Microsoft.BingNews',
        'Microsoft.BingSearch',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.StartExperiencesApp',
        'Microsoft.Todos',
        'Microsoft.Windows.DevHome',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.ZuneMusic',
        'MicrosoftCorporationII.QuickAssist',
        'MSTeams'
    )

    $packages | Where-Object { $pkg = $_; $packagePrefixes | Where-Object { $pkg -like "*$_*" } } |
        ForEach-Object { & dism /English "/image:$ScratchDir" /Remove-ProvisionedAppxPackage "/PackageName:$_" }

    # -- 2. Inject current system drivers (optional) ---------------------------
    if ($InjectCurrentSystemDrivers) {
        & $Log "Exporting all drivers from running system..."
        $driverExportRoot = Join-Path $env:TEMP "WinUtil_DriverExport_$(Get-Random)"
        New-Item -Path $driverExportRoot -ItemType Directory -Force
        try {
            Export-WindowsDriver -Online -Destination $driverExportRoot

            & $Log "Injecting current system drivers into install.wim..."
            Add-DriversToImage -MountPath $ScratchDir -DriverDir $driverExportRoot -Label "install" -Logger $Log
            & $Log "install.wim driver injection complete."

            if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
                $bootWim = Join-Path $ISOContentsDir "sources\boot.wim"
                if (Test-Path $bootWim) {
                    & $Log "Injecting current system drivers into boot.wim..."
                    Invoke-BootWimInject -BootWimPath $bootWim -DriverDir $driverExportRoot -Logger $Log
                } else {
                    & $Log "Warning: boot.wim not found - skipping boot.wim driver injection."
                }
            }
        } catch {
            & $Log "Error during driver export/injection: $_"
        } finally {
            Remove-Item -Path $driverExportRoot -Recurse -Force
        }
    } else {
        & $Log "Driver injection skipped."
    }

    # -- 3. Registry tweaks ----------------------------------------------------
    & $Log "Loading offline registry hives..."
    reg load HKLM\zCOMPONENTS "$ScratchDir\Windows\System32\config\COMPONENTS"
    reg load HKLM\zDEFAULT    "$ScratchDir\Windows\System32\config\default"
    reg load HKLM\zNTUSER     "$ScratchDir\Users\Default\ntuser.dat"
    reg load HKLM\zSOFTWARE   "$ScratchDir\Windows\System32\config\SOFTWARE"
    reg load HKLM\zSYSTEM     "$ScratchDir\Windows\System32\config\SYSTEM"

    & $Log "Bypassing system requirements..."
    Set-ISOScriptReg -Path 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' -Name 'SV1' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' -Name 'SV2' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' -Name 'SV1' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' -Name 'SV2' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\LabConfig' -Name 'BypassCPUCheck' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\LabConfig' -Name 'BypassRAMCheck' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\LabConfig' -Name 'BypassSecureBootCheck' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\LabConfig' -Name 'BypassStorageCheck' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\LabConfig' -Name 'BypassTPMCheck' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\Setup\MoSetup' -Name 'AllowUpgradesWithUnsupportedTPMOrCPU' -Type 'REG_DWORD' -Value '1'

    & $Log "Disabling sponsored apps..."
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'OemPreInstalledAppsEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'ConfigureStartPins' -Type 'REG_SZ' -Value '{"pinnedList": [{}]}'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'FeatureManagementEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEverEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SoftLandingEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContentEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338393Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353694Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353696Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' -Name 'DisablePushToInstall' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' -Name 'DontOfferThroughWUAU' -Type 'REG_DWORD' -Value '1'
    Remove-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
    Remove-ISOScriptReg 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableCloudOptimizedContent' -Type 'REG_DWORD' -Value '1'

    & $Log "Enabling local accounts on OOBE..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -Name 'BypassNRO' -Type 'REG_DWORD' -Value '1'

    if ($AutoUnattendXml) {
        $preparedAutoUnattendXml = $AutoUnattendXml
        try {
            $preparedAutoUnattendXml = ConvertTo-WinUtilISOAnswerFile -XmlContent $AutoUnattendXml -ImageIndex $InstallImageIndex
            & $Log "Prepared autounattend.xml to install image index $InstallImageIndex without forcing a product key."
        } catch {
            & $Log "Warning: could not prepare autounattend.xml image selection: $_"
        }

        try {
            $xmlDoc = [xml]::new()
            $xmlDoc.LoadXml($preparedAutoUnattendXml)

            $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
            $nsMgr.AddNamespace("sg", "https://schneegans.de/windows/unattend-generator/")

            $fileNodes = $xmlDoc.SelectNodes("//sg:File", $nsMgr)
            if ($fileNodes -and $fileNodes.Count -gt 0) {
                foreach ($fileNode in $fileNodes) {
                    $absPath  = $fileNode.GetAttribute("path")
                    $relPath  = $absPath -replace '^[A-Za-z]:[/\\]', ''
                    $destPath = Join-Path $ScratchDir $relPath
                    New-Item -Path (Split-Path $destPath -Parent) -ItemType Directory -Force

                    $ext = [IO.Path]::GetExtension($destPath).ToLower()
                    $encoding = switch ($ext) {
                        { $_ -in '.ps1', '.xml' }        { [System.Text.Encoding]::UTF8 }
                        { $_ -in '.reg', '.vbs', '.js' } { [System.Text.UnicodeEncoding]::new($false, $true) }
                        default                          { [System.Text.Encoding]::Default }
                    }
                    [System.IO.File]::WriteAllBytes($destPath, ($encoding.GetPreamble() + $encoding.GetBytes($fileNode.InnerText.Trim())))
                    & $Log "Pre-staged setup script: $relPath"
                }
            } else {
                & $Log "Warning: no <Extensions><File> nodes found in autounattend.xml - setup scripts not pre-staged."
            }
        } catch {
            & $Log "Warning: could not pre-stage setup scripts from autounattend.xml: $_"
        }

        if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
            $isoDest = Join-Path $ISOContentsDir "autounattend.xml"
            Set-Content -Path $isoDest -Value $preparedAutoUnattendXml -Encoding UTF8 -Force
            & $Log "Written autounattend.xml to ISO root ($isoDest)."
        }
    } else {
        & $Log "Warning: autounattend.xml content is empty - skipping OOBE bypass file."
    }

    if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
        Write-WinUtilISOEditionConfig -ContentRoot $ISOContentsDir -EditionId $InstallEditionId -Logger $Log
    }

    & $Log "Disabling reserved storage..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' -Name 'ShippedWithReserves' -Type 'REG_DWORD' -Value '0'

    & $Log "Disabling BitLocker device encryption..."
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' -Name 'PreventDeviceEncryption' -Type 'REG_DWORD' -Value '1'

    & $Log "Disabling Chat icon..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -Type 'REG_DWORD' -Value '3'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Type 'REG_DWORD' -Value '0'

    & $Log "Disabling OneDrive folder backup..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Type 'REG_DWORD' -Value '1'

    & $Log "Disabling telemetry..."
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' -Name 'Start' -Type 'REG_DWORD' -Value '4'

    & $Log "Preventing installation of DevHome and Outlook..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Name 'workCompleted' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' -Name 'workCompleted' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' -Name 'workCompleted' -Type 'REG_DWORD' -Value '1'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

    & $Log "Disabling Copilot..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type 'REG_DWORD' -Value '1'

    & $Log "Disabling Windows Update during OOBE (re-enabled on first logon via FirstLogon.ps1)..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'AUOptions' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'UseWUServer' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DisableWindowsUpdateAccess' -Type 'REG_DWORD' -Value '1'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'WUServer' -Type 'REG_SZ' -Value 'http://localhost:8080'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'WUStatusServer' -Type 'REG_SZ' -Value 'http://localhost:8080'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' -Name 'workCompleted' -Type 'REG_DWORD' -Value '1'
    Remove-ISOScriptReg 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate'
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Type 'REG_DWORD' -Value '0'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Services\BITS' -Name 'Start' -Type 'REG_DWORD' -Value '4'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv' -Name 'Start' -Type 'REG_DWORD' -Value '4'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc' -Name 'Start' -Type 'REG_DWORD' -Value '4'
    Set-ISOScriptReg -Path 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSvc' -Name 'Start' -Type 'REG_DWORD' -Value '4'

    & $Log "Preventing installation of Teams..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' -Name 'DisableInstallation' -Type 'REG_DWORD' -Value '1'

    & $Log "Preventing installation of new Outlook..."
    Set-ISOScriptReg -Path 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' -Name 'PreventRun' -Type 'REG_DWORD' -Value '1'

    & $Log "Unloading offline registry hives..."
    reg unload HKLM\zCOMPONENTS
    reg unload HKLM\zDEFAULT
    reg unload HKLM\zNTUSER
    reg unload HKLM\zSOFTWARE
    reg unload HKLM\zSYSTEM

    # -- 4. Delete scheduled task definition files -----------------------------
    & $Log "Deleting scheduled task definition files..."
    $tasksPath = "$ScratchDir\Windows\System32\Tasks"
    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force
    Remove-Item "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program"                  -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater"               -Force
    Remove-Item "$tasksPath\Microsoft\Windows\Chkdsk\Proxy"                                            -Force
    Remove-Item "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting"                  -Force
    Remove-Item "$tasksPath\Microsoft\Windows\InstallService"                                          -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\Windows\UpdateOrchestrator"                                      -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\Windows\UpdateAssistant"                                         -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\Windows\WaaSMedic"                                               -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\Windows\WindowsUpdate"                                           -Recurse -Force
    Remove-Item "$tasksPath\Microsoft\WindowsUpdate"                                                   -Recurse -Force
    & $Log "Scheduled task files deleted."

    # -- 5. Remove ISO support folder -----------------------------------------
    if ($ISOContentsDir -and (Test-Path $ISOContentsDir)) {
        & $Log "Removing ISO support\ folder..."
        Remove-Item -Path (Join-Path $ISOContentsDir "support") -Recurse -Force
        & $Log "ISO support\ folder removed."
    }
}
