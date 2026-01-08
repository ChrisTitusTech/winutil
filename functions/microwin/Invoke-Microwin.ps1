function Invoke-Microwin {
    <#
        .DESCRIPTION
        Invoke MicroWin routines...
    #>


    if($sync.ProcessRunning) {
        $msg = "GetIso process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # Define the constants for Windows API
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class PowerManagement {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE esFlags);

    [FlagsAttribute]
    public enum EXECUTION_STATE : uint {
        ES_SYSTEM_REQUIRED = 0x00000001,
        ES_DISPLAY_REQUIRED = 0x00000002,
        ES_CONTINUOUS = 0x80000000,
    }
}
"@

    # Prevent the machine from sleeping
    [PowerManagement]::SetThreadExecutionState([PowerManagement]::EXECUTION_STATE::ES_CONTINUOUS -bor [PowerManagement]::EXECUTION_STATE::ES_SYSTEM_REQUIRED -bor [PowerManagement]::EXECUTION_STATE::ES_DISPLAY_REQUIRED)

    # Ask the user where to save the file
    $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $SaveDialog.Filter = "ISO images (*.iso)|*.iso"
    $SaveDialog.ShowDialog() | Out-Null

    if ($SaveDialog.FileName -eq "") {
        $msg = "No file name for the target image was specified"
        Write-Host $msg
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        return
    }

    Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
    Invoke-MicrowinBusyInfo -action "wip" -message "Busy..." -interactive $false

    Write-Host "Target ISO location: $($SaveDialog.FileName)"

    $index = $sync.MicrowinWindowsFlavors.SelectedValue.Split(":")[0].Trim()
    Write-Host "Index chosen: '$index' from $($sync.MicrowinWindowsFlavors.SelectedValue)"

    $injectDrivers = $sync.MicrowinInjectDrivers.IsChecked
    $importDrivers = $sync.MicrowinImportDrivers.IsChecked

    $importVirtIO = $sync.MicrowinCopyVirtIO.IsChecked

    $mountDir = $sync.MicrowinMountDir.Text
    $scratchDir = $sync.MicrowinScratchDir.Text

    # Detect if the Windows image is an ESD file and convert it to WIM
    if (-not (Test-Path -Path "$mountDir\sources\install.wim" -PathType Leaf) -and (Test-Path -Path "$mountDir\sources\install.esd" -PathType Leaf)) {
        Write-Host "Exporting Windows image to a WIM file, keeping the index we want to work on. This can take several minutes, depending on the performance of your computer..."
        try {
            Export-WindowsImage -SourceImagePath "$mountDir\sources\install.esd" -SourceIndex $index -DestinationImagePath "$mountDir\sources\install.wim" -CompressionType "Max"
        } catch {
            # Usually the case if it can't find unattend.dll on the host system. Guys, fix your corrupt messes that are your installations!
            dism /english /export-image /sourceimagefile="$mountDir\sources\install.esd" /sourceindex=$index /destinationimagefile="$mountDir\sources\install.wim" /compress:max
        }
        if ($?) {
            Remove-Item -Path "$mountDir\sources\install.esd" -Force
            # Since we've already exported the image index we wanted, switch to the first one
            $index = 1
        } else {
            $msg = "The export process has failed and MicroWin processing cannot continue"
            Write-Host $msg
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            Invoke-MicrowinBusyInfo -action "warning" -message $msg
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
    }

    $imgVersion = (Get-WindowsImage -ImagePath "$mountDir\sources\install.wim" -Index $index).Version
    # Windows Setup is the second index in the boot image.
    $bootVersion = (Get-WindowsImage -ImagePath "$mountDir\sources\boot.wim" -Index 2).Version
    Write-Host "The Windows Image Build Version is: $imgVersion"
    Write-Host "The WinPE boot image Build Version is: $bootVersion"

    # Detect image version to avoid performing MicroWin processing on Windows 8 and earlier
    if ((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,10240,0))) -eq $false) {
        $msg = "This image is not compatible with MicroWin processing. Make sure it isn't a Windows 8 or earlier image."
        $dlg_msg = $msg + "`n`nIf you want more information, the version of the image selected is $($imgVersion)`n`nIf an image has been incorrectly marked as incompatible, report an issue to the developers."
        Write-Host $msg
        [System.Windows.MessageBox]::Show($dlg_msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Exclamation)
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        return
    }

    # Detect whether the image to process contains Windows 10 and show warning
    if ((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,21996,1))) -eq $false) {
        $msg = "Windows 10 has been detected in the image you want to process. While you can continue, Windows 10 is not a recommended target for MicroWin, and you may not get the full experience."
        $dlg_msg = $msg
        Write-Host $msg
        [System.Windows.MessageBox]::Show($dlg_msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Exclamation)
    }

    $mountDirExists = Test-Path $mountDir
    $scratchDirExists = Test-Path $scratchDir
    if (-not $mountDirExists -or -not $scratchDirExists) {
        $msg = "Required directories '$mountDirExists' '$scratchDirExists' and do not exist."
        Write-Error $msg
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        return
    }

    try {

        Write-Host "Mounting Windows image. This may take a while."
        Mount-WindowsImage -ImagePath "$mountDir\sources\install.wim" -Index $index -Path "$scratchDir"
        if ($?) {
            Write-Host "The Windows image has been mounted successfully. Continuing processing..."
        } else {
            $msg = "Could not mount image. Exiting..."
            Write-Host $msg
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            Invoke-MicrowinBusyInfo -action "warning" -message $msg
            return
        }

        if ($importDrivers) {
            Write-Host "Exporting drivers from active installation..."
            if (Test-Path "$env:TEMP\DRV_EXPORT") {
                Remove-Item "$env:TEMP\DRV_EXPORT" -Recurse -Force
            }
            if (($injectDrivers -and (Test-Path "$($sync.MicrowinDriverLocation.Text)"))) {
                Write-Host "Using specified driver source..."
                dism /english /online /export-driver /destination="$($sync.MicrowinDriverLocation.Text)" | Out-Host
                if ($?) {
                    # Don't add exported drivers yet, that is run later
                    Write-Host "Drivers have been exported successfully."
                } else {
                    Write-Host "Failed to export drivers."
                }
            } else {
                New-Item -Path "$env:TEMP\DRV_EXPORT" -ItemType Directory -Force
                dism /english /online /export-driver /destination="$env:TEMP\DRV_EXPORT" | Out-Host
                if ($?) {
                    Write-Host "Adding exported drivers..."
                    dism /english /image="$scratchDir" /add-driver /driver="$env:TEMP\DRV_EXPORT" /recurse | Out-Host
                } else {
                    Write-Host "Failed to export drivers. Continuing without importing them..."
                }
                if (Test-Path "$env:TEMP\DRV_EXPORT") {
                    Remove-Item "$env:TEMP\DRV_EXPORT" -Recurse -Force
                }
            }
        }

        if ($injectDrivers) {
            $driverPath = $sync.MicrowinDriverLocation.Text
            if (Test-Path $driverPath) {
                Write-Host "Adding Windows Drivers image($scratchDir) drivers($driverPath) "
                dism /English /image:$scratchDir /add-driver /driver:$driverPath /recurse | Out-Host
            } else {
                Write-Host "Path to drivers is invalid continuing without driver injection"
            }
        }

        Write-Host "Disabling WPBT Execution"
        reg load HKLM\zSYSTEM "$($scratchDir)\Windows\System32\config\SYSTEM"
        reg add "HKLM\zSYSTEM\ControlSet001\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f
        reg unload HKLM\zSYSTEM

        Write-Host "Skipping first logon animation..."
        reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE"
        reg add "HKLM\zSOFTWARE\Microsoft\Active Setup\Installed Components\CMP_NoFla" /f
        reg add "HKLM\zSOFTWARE\Microsoft\Active Setup\Installed Components\CMP_NoFla" /f /ve /t REG_SZ /d "Stop First Logon Animation Process"
        reg add "HKLM\zSOFTWARE\Microsoft\Active Setup\Installed Components\CMP_NoFla" /f /v StubPath /t REG_EXPAND_SZ /d '\"%WINDIR%\System32\cmd.exe\" /C \"taskkill /f /im firstlogonanim.exe\"'
        reg unload HKLM\zSOFTWARE

        # We have to prepare the target system to accept the diagnostics script
        reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE"
        reg add "HKLM\zSOFTWARE\WinUtil" /f
        reg add "HKLM\zSOFTWARE\WinUtil" /f /v "ToolboxVersion" /t REG_SZ /d "$($sync.version)"
        reg add "HKLM\zSOFTWARE\WinUtil" /f /v "MicroWinBuildDate" /t REG_SZ /d "$((Get-Date).ToString('yyMMdd-HHmm'))"

        # REAL software developers set execution policies to unrestricted but, because we're targeting
        # mainstream population, we have to lower the level of "riskiness" -- set remotesigned; at least that
        # lets us run PWSH scripts that WE create. Execution policies don't really make sense anyway if common sense
        # is lacking.
        reg add "HKLM\zSOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v "ExecutionPolicy" /t REG_SZ /d "RemoteSigned" /f

        reg unload HKLM\zSOFTWARE

        if ($importVirtIO) {
            Write-Host "Copying VirtIO drivers..."
            Microwin-CopyVirtIO
        }

        Write-Host "Remove Features from the image"
        Microwin-RemoveFeatures -UseCmdlets $true
        Write-Host "Removing features complete!"
        Write-Host "Removing OS packages"
        Microwin-RemovePackages -UseCmdlets $true
        Write-Host "Removing Appx Bloat"
        Microwin-RemoveProvisionedPackages -UseCmdlets $true

        # Detect Windows 11 24H2 and add dependency to FileExp to prevent Explorer look from going back - thanks @WitherOrNot and @thecatontheceiling
        # ----- UPDATE UPDATE UPDATE: they fixed this in 10.0.26100.7019. DO NOT DO THIS OTHERWISE IT BREAKS EXPLORER AGAIN BECAUSE THE CHEEKY LITTLE
        # ----- PoS CHANGED APPRUNTIME.CBS TO APPRUNTIME.CBS.1.6. Thing is, we don't need to patch this in those builds because it no longer breaks
        # ----- when you don't patch.
        if (((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,26100,1))) -eq $true) -and ((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,26100,7019))) -eq $false)) {
            try {
                if (Test-Path "$scratchDir\Windows\SystemApps\MicrosoftWindows.Client.FileExp_cw5n1h2txyewy\appxmanifest.xml" -PathType Leaf) {
                    # Found the culprit. Do the following:
                    # 1. Take ownership of the file, from TrustedInstaller to Administrators
                    takeown /F "$scratchDir\Windows\SystemApps\MicrosoftWindows.Client.FileExp_cw5n1h2txyewy\appxmanifest.xml" /A
                    # 2. Set ACLs so that we can write to it
                    icacls "$scratchDir\Windows\SystemApps\MicrosoftWindows.Client.FileExp_cw5n1h2txyewy\appxmanifest.xml" /grant "$(Microwin-GetLocalizedUsers -admins $true):(M)" | Out-Host
                    # 3. Open the file and do the modification
                    $appxManifest = Get-Content -Path "$scratchDir\Windows\SystemApps\MicrosoftWindows.Client.FileExp_cw5n1h2txyewy\appxmanifest.xml"
                    $originalLine = $appxManifest[13]
                    $dependency = "`n        <PackageDependency Name=`"Microsoft.WindowsAppRuntime.CBS`" MinVersion=`"1.0.0.0`" Publisher=`"CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US`" />"
                    $appxManifest[13] = "$originalLine$dependency"
                    Set-Content -Path "$scratchDir\Windows\SystemApps\MicrosoftWindows.Client.FileExp_cw5n1h2txyewy\appxmanifest.xml" -Value $appxManifest -Force -Encoding utf8
                }
            }
            catch {
                # Fall back to what we used to do: delayed disablement
                Enable-WindowsOptionalFeature -Path "$scratchDir" -FeatureName "Recall"
            }
        }

        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\LogFiles\WMI\RtBackup" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\DiagTrack" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\InboxApps" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\LocationNotificationWindows.exe"
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Media Player" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Media Player" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Mail" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Mail" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Internet Explorer" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Internet Explorer" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\GameBarPresenceWriter"
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDriveSetup.exe"
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDrive.ico"
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*narratorquickstart*" -Directory
        Microwin-RemoveFileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*ParentalControls*" -Directory
        Write-Host "Removal complete!"

        Write-Host "Create unattend.xml"

        if (($sync.MicrowinAutoConfigBox.Text -ne "") -and (Test-Path "$($sync.MicrowinAutoConfigBox.Text)"))
        {
            try
            {
                Write-Host "A configuration file has been specified. Copying to WIM file..."
                Copy-Item "$($sync.MicrowinAutoConfigBox.Text)" "$($scratchDir)\winutil-config.json"
            }
            catch
            {
                Write-Host "The config file could not be copied. Continuing without it..."
            }
        }

        # Create unattended answer file with user information - Check condition to learn more about this functionality
        if ($sync.MicrowinUserName.Text -eq "")
        {
            Microwin-NewUnattend -userName "User"
        }
        else
        {
            if ($sync.MicrowinUserPassword.Password -eq "")
            {
                Microwin-NewUnattend -userName "$($sync.MicrowinUserName.Text)"
            }
            else
            {
                Microwin-NewUnattend -userName "$($sync.MicrowinUserName.Text)" -userPassword "$($sync.MicrowinUserPassword.Password)"
            }
        }
        Write-Host "Done Create unattend.xml"
        Write-Host "Copy unattend.xml file into the ISO"
        New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\Panther"
        Copy-Item "$env:temp\unattend.xml" "$($scratchDir)\Windows\Panther\unattend.xml" -force
        New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\System32\Sysprep"
        Copy-Item "$env:temp\unattend.xml" "$($scratchDir)\Windows\System32\Sysprep\unattend.xml" -force
        Write-Host "Done Copy unattend.xml"

        Write-Host "Create FirstRun"
        Microwin-NewFirstRun
        Write-Host "Done create FirstRun"
        Write-Host "Copy FirstRun.ps1 into the ISO"
        Copy-Item "$env:temp\FirstStartup.ps1" "$($scratchDir)\Windows\FirstStartup.ps1" -force
        Write-Host "Done copy FirstRun.ps1"

        Write-Host "Copy checkinstall.cmd into the ISO"
        Microwin-NewCheckInstall
        Copy-Item "$env:temp\checkinstall.cmd" "$($scratchDir)\Windows\checkinstall.cmd" -force
        Write-Host "Done copy checkinstall.cmd"

        Write-Host "Creating a directory that allows to bypass Wifi setup"
        New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\System32\OOBE\BYPASSNRO"

        Write-Host "Loading registry"
        reg load HKLM\zDEFAULT "$($scratchDir)\Windows\System32\config\default"
        reg load HKLM\zNTUSER "$($scratchDir)\Users\Default\ntuser.dat"
        reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE"
        reg load HKLM\zSYSTEM "$($scratchDir)\Windows\System32\config\SYSTEM"

        Write-Host "Disabling Teams"
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall" /t REG_DWORD /d 0 /f   >$null 2>&1
        reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 2 /f                             >$null 2>&1
        reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f        >$null 2>&1
        reg query "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall"                      >$null 2>&1
        Write-Host "Done disabling Teams"

        Write-Host "Fix Windows Volume Mixer Issue"
        reg add "HKLM\zNTUSER\Software\Microsoft\Internet Explorer\LowRegistry\Audio\PolicyConfig\PropertyStore" /f

        Write-Host "Bypassing system requirements (system image)"
        reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d 0 /f
        reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d 0 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d 1 /f

        # Prevent Windows Update Installing so called Expedited Apps - 24H2 and newer
        if ((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,26100,1))) -eq $true) {
            @(
                'EdgeUpdate',
                'DevHomeUpdate',
                'OutlookUpdate',
                'CrossDeviceUpdate'
            ) | ForEach-Object {
                Write-Host "Removing Windows Expedited App: $_"
                reg delete "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\$_" /f | Out-Null
            }
        }

        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f
        Write-Host "Setting all services to start manually"
        reg add "HKLM\zSOFTWARE\CurrentControlSet\Services" /v Start /t REG_DWORD /d 3 /f

        Write-Host "Enabling Local Accounts on OOBE"
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d "1" /f

        Write-Host "Disabling Sponsored Apps"
        reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
        reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d '{\"pinnedList\": [{}]}' /f
        Write-Host "Done removing Sponsored Apps"

        Write-Host "Disabling Reserved Storage"
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d 0 /f

        Write-Host "Showing file extensions..."
        reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f

        if ((Microwin-TestCompatibleImage $imgVersion $([System.Version]::new(10,0,21996,1))) -eq $false) {
            # We're dealing with Windows 10. Configure sane desktop settings. NOTE: even though stuff to disable News and Interests is there,
            # it doesn't seem to work, and I don't want to waste more time dealing with an operating system that will lose support in a year (2025)

            # I invite anyone to work on improving stuff for News and Interests, but that won't be me!

            Write-Host "Disabling Search Highlights..."
            reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds\DSB" /v "ShowDynamicContent" /t REG_DWORD /d 0 /f
            reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f
            reg add "HKLM\zSOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f
            reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "TraySearchBoxVisible" /t REG_DWORD /d 1 /f
            reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
        }

    } catch {
        Write-Error "An unexpected error occurred: $_"
    } finally {
        Write-Host "Unmounting Registry..."
        reg unload HKLM\zDEFAULT
        reg unload HKLM\zNTUSER
        reg unload HKLM\zSOFTWARE
        reg unload HKLM\zSYSTEM

        Write-Host "Cleaning up image..."
        dism /English /image:$scratchDir /Cleanup-Image /StartComponentCleanup /ResetBase
        Write-Host "Cleanup complete."
        $committed = $false
        $unmounted = $false

        Write-Host "Saving image..."

        try {
            Save-WindowsImage -Path "$scratchDir"
            $committed = $true
        } catch {
            do {
                # we'll prevent stuff inside this loop from throwing exceptions and breaking from the loop.
                try {
                    Save-WindowsImage -Path "$scratchDir"
                    $committed = $true
                } catch {
                    Write-Host "Commit operation unsuccessful. Trying again after 3 seconds..."
                    Start-Sleep -Seconds 3
                }
            } until ($committed)
        }

        Write-Host "Unmounting image..."

        try {
            # because we've already saved the changes earlier, we can safely discard
            Dismount-WindowsImage -Discard -Path "$scratchDir"
            $unmounted = $true
        } catch {
            do {
                # we'll prevent stuff inside this loop from throwing exceptions and breaking from the loop.
                try {
                    Dismount-WindowsImage -Discard -Path "$scratchDir"
                    $unmounted = $true
                } catch {
                    Write-Host "Unmount operation unsuccessful. Trying again after 3 seconds..."
                    Start-Sleep -Seconds 3
                }
            } until ($unmounted)
        }
    }

    try {

        Write-Host "Exporting image into $mountDir\sources\install2.wim"
        try {
            Export-WindowsImage -SourceImagePath "$mountDir\sources\install.wim" -SourceIndex $index -DestinationImagePath "$mountDir\sources\install2.wim" -CompressionType "Max"
        } catch {
            # Usually the case if it can't find unattend.dll on the host system. Guys, fix your corrupt messes that are your installations!
            dism /english /export-image /sourceimagefile="$mountDir\sources\install.wim" /sourceindex=$index /destinationimagefile="$mountDir\sources\install2.wim" /compress:max
        }
        Write-Host "Remove old '$mountDir\sources\install.wim' and rename $mountDir\sources\install2.wim"
        Remove-Item "$mountDir\sources\install.wim"
        Rename-Item "$mountDir\sources\install2.wim" "$mountDir\sources\install.wim"

        if (-not (Test-Path -Path "$mountDir\sources\install.wim")) {
            $msg = "Something went wrong. Please report this bug to the devs."
            Write-Error "$($msg) '$($mountDir)\sources\install.wim' doesn't exist"
            Invoke-MicrowinBusyInfo -action "warning" -message $msg
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            return
        }
        Write-Host "Windows image completed. Continuing with boot.wim."

        # Next step boot image
        Write-Host "Mounting boot image $mountDir\sources\boot.wim into $scratchDir"
        Mount-WindowsImage -ImagePath "$mountDir\sources\boot.wim" -Index 2 -Path "$scratchDir"

        if ($injectDrivers) {
            $driverPath = $sync.MicrowinDriverLocation.Text
            if (Test-Path $driverPath) {
                Write-Host "Adding Windows Drivers image($scratchDir) drivers($driverPath) "
                dism /English /image:$scratchDir /add-driver /driver:$driverPath /recurse | Out-Host
            } else {
                Write-Host "Path to drivers is invalid continuing without driver injection"
            }
        }

        Write-Host "Loading registry..."
        reg load HKLM\zDEFAULT "$($scratchDir)\Windows\System32\config\default" >$null
        reg load HKLM\zNTUSER "$($scratchDir)\Users\Default\ntuser.dat" >$null
        reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE" >$null
        reg load HKLM\zSYSTEM "$($scratchDir)\Windows\System32\config\SYSTEM" >$null
        Write-Host "Bypassing system requirements on the setup image"
        reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d 0 /f
        reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d 0 /f
        reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d 0 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f
        reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d 1 /f
        # Fix Computer Restarted Unexpectedly Error on New Bare Metal Install
        reg add "HKLM\zSYSTEM\Setup\Status\ChildCompletion" /v "setup.exe" /t REG_DWORD /d 3 /f

        # Force old Setup on 24H2+ WinPE images due to personal preference; it's simply faster and
        # more reliable than MoSetup. I simply can't stand that new setup system.
        if ((Microwin-TestCompatibleImage $bootVersion $([System.Version]::new(10,0,26040,0))) -and (Test-Path -Path "$scratchDir\sources\setup.exe" -PathType Leaf)) {
            reg add "HKLM\zSYSTEM\Setup" /f /v "CmdLine" /t REG_SZ /d "\sources\setup.exe"
        }
    } catch {
        Write-Error "An unexpected error occurred: $_"
    } finally {
        Write-Host "Unmounting Registry..."
        reg unload HKLM\zDEFAULT
        reg unload HKLM\zNTUSER
        reg unload HKLM\zSOFTWARE
        reg unload HKLM\zSYSTEM

        $committed = $false
        $unmounted = $false

        Write-Host "Saving image..."

        try {
            Save-WindowsImage -Path "$scratchDir"
            $committed = $true
        } catch {
            do {
                # we'll prevent stuff inside this loop from throwing exceptions and breaking from the loop.
                try {
                    Save-WindowsImage -Path "$scratchDir"
                    $committed = $true
                } catch {
                    Write-Host "Commit operation unsuccessful. Trying again after 3 seconds..."
                    Start-Sleep -Seconds 3
                }
            } until ($committed)
        }

        Write-Host "Unmounting image..."

        try {
            # because we've already saved the changes earlier, we can safely discard
            Dismount-WindowsImage -Discard -Path "$scratchDir"
            $unmounted = $true
        } catch {
            do {
                # we'll prevent stuff inside this loop from throwing exceptions and breaking from the loop.
                try {
                    Dismount-WindowsImage -Discard -Path "$scratchDir"
                    $unmounted = $true
                } catch {
                    Write-Host "Unmount operation unsuccessful. Trying again after 3 seconds..."
                    Start-Sleep -Seconds 3
                }
            } until ($unmounted)
        }

        Write-Host "Creating ISO image"

        $peToolsPath = ""

        $adkKitsRoot = Microwin-GetKitsRoot -wow64environment $false
        $adkKitsRoot_WOW64Environ = Microwin-GetKitsRoot -wow64environment $true

        $expectedADKPath = "$($adkKitsRoot)Assessment and Deployment Kit"
        $expectedADKPath_WOW64Environ = "$($adkKitsRoot_WOW64Environ)Assessment and Deployment Kit"

        # if we downloaded oscdimg from github it will be in the temp directory so use it
        # if it is not in temp it is part of ADK and is in global PATH so just set it to oscdimg.exe
        $oscdimgPath = Join-Path $env:TEMP 'oscdimg.exe'
        $oscdImgFound = Test-Path -Path "$oscdimgPath" -PathType Leaf
        if ((-not ($oscdImgFound)) -and ((Microwin-TestKitsRootPaths -adkKitsRootPath "$expectedADKPath" -adkKitsRootPath_WOW64Environ "$expectedADKPath_WOW64Environ") -eq $true)) {
            if ($expectedADKPath -ne "Assessment and Deployment Kit") { $peToolsPath = $expectedADKPath }
            if (($peToolsPath -eq "") -and ($expectedADKPath_WOW64Environ -ne "Assessment and Deployment Kit")) { $peToolsPath = $expectedADKPath_WOW64Environ }

            Write-Host "Using $peToolsPath as the Preinstallation Environment tools path..."
            # Paths change depending on platform
            if ([Environment]::Is64BitOperatingSystem) {
                $oscdimgPath = "$peToolsPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
            } else {
                $oscdimgPath = "$peToolsPath\Deployment Tools\x86\Oscdimg\oscdimg.exe"
            }
        }

        Write-Host "[INFO] Using oscdimg.exe from: $oscdimgPath"

        $oscdimgProc = Start-Process -FilePath "$oscdimgPath" -ArgumentList "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$mountDir\boot\etfsboot.com`"#pEF,e,b`"$mountDir\efi\microsoft\boot\efisys.bin`" `"$mountDir`" `"$($SaveDialog.FileName)`"" -Wait -PassThru -NoNewWindow

        $LASTEXITCODE = $oscdimgProc.ExitCode

        Write-Host "OSCDIMG Error Level : $($oscdimgProc.ExitCode)"

        Write-Host " _____                       "
        Write-Host "(____ \                      "
        Write-Host " _   \ \ ___  ____   ____    "
        Write-Host "| |   | / _ \|  _ \ / _  )   "
        Write-Host "| |__/ / |_| | | | ( (/ /    "
        Write-Host "|_____/ \___/|_| |_|\____)   "

        # Check if the ISO was successfully created - CTT edit
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n`nPerforming Cleanup..."
                Remove-Item -Recurse -Force "$($scratchDir)"
                Remove-Item -Recurse -Force "$($mountDir)"
            $msg = "Done. ISO image is located here: $($SaveDialog.FileName)"
            Write-Host $msg
            Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
            Invoke-MicrowinBusyInfo -action "done" -message "Finished!"
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Host "ISO creation failed. The "$($mountDir)" directory has not been removed."
            try {
                # This creates a new Win32 exception from which we can extract a message in the system language.
                # Now, this will NOT throw an exception
                $exitCode = New-Object System.ComponentModel.Win32Exception($LASTEXITCODE)
                Write-Host "Reason: $($exitCode.Message)"
                Invoke-MicrowinBusyInfo -action "warning" -message $exitCode.Message
                Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
                [System.Windows.MessageBox]::Show("MicroWin failed to make the ISO.", "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            } catch {
                # Could not get error description from Windows APIs
            }
        }

        Toggle-MicrowinPanel 1

        $sync.MicrowinFinalIsoLocation.Text = "$($SaveDialog.FileName)"
        # Allow the machine to sleep again (optional)
        [PowerManagement]::SetThreadExecutionState(0)
        $sync.ProcessRunning = $false
    }
}
