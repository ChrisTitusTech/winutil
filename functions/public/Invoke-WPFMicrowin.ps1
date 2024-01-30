function Invoke-WPFMicrowin {
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
        Write-Host "No file name for the target image was specified"
        return
    }

    Write-Host "Target ISO location: $($SaveDialog.FileName)"

	$index = $sync.MicrowinWindowsFlavors.SelectedValue.Split(":")[0].Trim()
	Write-Host "Index chosen: '$index' from $($sync.MicrowinWindowsFlavors.SelectedValue)"

	$keepPackages = $sync.WPFMicrowinKeepProvisionedPackages.IsChecked
	$keepProvisionedPackages = $sync.WPFMicrowinKeepAppxPackages.IsChecked
	$keepDefender = $sync.WPFMicrowinKeepDefender.IsChecked
	$keepEdge = $sync.WPFMicrowinKeepEdge.IsChecked
	$copyToUSB = $sync.WPFMicrowinCopyToUsb.IsChecked
	$injectDrivers = $sync.MicrowinInjectDrivers.IsChecked

    $mountDir = $sync.MicrowinMountDir.Text
    $scratchDir = $sync.MicrowinScratchDir.Text

    $imgVersion = (Get-WindowsImage -ImagePath $mountDir\sources\install.wim -Index $index).Version

    # Detect image version to avoid performing MicroWin processing on Windows 8 and earlier
    if ((Is-CompatibleImage $imgVersion) -eq $false)
    {
		$msg = "This image is not compatible with MicroWin processing. Make sure it isn't a Windows 8 or earlier image."
        $dlg_msg = $msg + "`n`nIf you want more information, the version of the image selected is $($imgVersion)`n`nIf an image has been incorrectly marked as incompatible, report an issue to the developers."
		Write-Host $msg
		[System.Windows.MessageBox]::Show($dlg_msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Exclamation)
        return
    }

	$mountDirExists = Test-Path $mountDir
    $scratchDirExists = Test-Path $scratchDir
	if (-not $mountDirExists -or -not $scratchDirExists) 
	{
        Write-Error "Required directories '$mountDirExists' '$scratchDirExists' and do not exist."
        return
    }

	try {

		Write-Host "Mounting Windows image. This may take a while."
		dism /mount-image /imagefile:$mountDir\sources\install.wim /index:$index /mountdir:$scratchDir
		Write-Host "Mounting complete! Performing removal of applications..."

		if ($injectDrivers)
		{
			$driverPath = $sync.MicrowinDriverLocation.Text
			if (Test-Path $driverPath)
			{
				Write-Host "Adding Windows Drivers image($scratchDir) drivers($driverPath) "
				dism /English /image:$scratchDir /add-driver /driver:$driverPath /recurse | Out-Host
			}
			else 
			{
				Write-Host "Path to drivers is invalid continuing without driver injection"
			}
		}

		Write-Host "Remove Features from the image"
		Remove-Features -keepDefender:$keepDefender
		Write-Host "Removing features complete!"

		Write-Host "Removing Appx Bloat"
		if (!$keepPackages)
		{
			Remove-Packages
		}
		if (!$keepProvisionedPackages)
		{
			Remove-ProvisionedPackages -keepSecurity:$keepDefender
		}

		# special code, for some reason when you try to delete some inbox apps
		# we have to get and delete log files directory. 
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\LogFiles\WMI\RtBackup" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\WebThreatDefSvc" -Directory

		# Defender is hidden in 2 places we removed a feature above now need to remove it from the disk
		if (!$keepDefender) 
		{
			Write-Host "Removing Defender"
			Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Defender" -Directory
			Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Defender"
		}
		if (!$keepEdge)
		{
			Write-Host "Removing Edge"
			Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Microsoft" -mask "*edge*" -Directory
			Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Microsoft" -mask "*edge*" -Directory
			Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*edge*" -Directory
		}

		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\DiagTrack" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\InboxApps" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\SecurityHealthSystray.exe"
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\LocationNotificationWindows.exe" 
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Photo Viewer" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Photo Viewer" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Media Player" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Media Player" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Mail" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Mail" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Internet Explorer" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Internet Explorer" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\GameBarPresenceWriter"
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDriveSetup.exe"
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDrive.ico"
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*Windows.Search*" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*narratorquickstart*" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*Xbox*" -Directory
		Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*ParentalControls*" -Directory
		Write-Host "Removal complete!"

		Write-Host "Create unattend.xml"
		New-Unattend
		Write-Host "Done Create unattend.xml"
		Write-Host "Copy unattend.xml file into the ISO"
		New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\Panther"
		Copy-Item "$env:temp\unattend.xml" "$($scratchDir)\Windows\Panther\unattend.xml" -force
		New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\System32\Sysprep"
		Copy-Item "$env:temp\unattend.xml" "$($scratchDir)\Windows\System32\Sysprep\unattend.xml" -force
		Copy-Item "$env:temp\unattend.xml" "$($scratchDir)\unattend.xml" -force
		Write-Host "Done Copy unattend.xml"

		Write-Host "Create FirstRun"
		New-FirstRun
		Write-Host "Done create FirstRun"
		Write-Host "Copy FirstRun.ps1 into the ISO"
		Copy-Item "$env:temp\FirstStartup.ps1" "$($scratchDir)\Windows\FirstStartup.ps1" -force
		Write-Host "Done copy FirstRun.ps1"

		Write-Host "Copy link to winutil.ps1 into the ISO"
		$desktopDir = "$($scratchDir)\Windows\Users\Default\Desktop"
		New-Item -ItemType Directory -Force -Path "$desktopDir"
	    dism /English /image:$($scratchDir) /set-profilepath:"$($scratchDir)\Windows\Users\Default"
		$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://christitus.com/win | iex'"
		$shortcutPath = "$desktopDir\WinUtil.lnk"
		$shell = New-Object -ComObject WScript.Shell
		$shortcut = $shell.CreateShortcut($shortcutPath)

		if (Test-Path -Path "$env:TEMP\cttlogo.png")
		{
			$pngPath = "$env:TEMP\cttlogo.png"
			$icoPath = "$env:TEMP\cttlogo.ico"
			ConvertTo-Icon -bitmapPath $pngPath -iconPath $icoPath
			Write-Host "ICO file created at: $icoPath"
			Copy-Item "$env:TEMP\cttlogo.png" "$($scratchDir)\Windows\cttlogo.png" -force
			Copy-Item "$env:TEMP\cttlogo.ico" "$($scratchDir)\Windows\cttlogo.ico" -force
			$shortcut.IconLocation = "c:\Windows\cttlogo.ico"
		}

		$shortcut.TargetPath = "powershell.exe"
		$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
		$shortcut.Save()
		Write-Host "Shortcut to winutil created at: $shortcutPath"
		# *************************** Automation black ***************************

		Write-Host "Copy checkinstall.cmd into the ISO"
		New-CheckInstall
		Copy-Item "$env:temp\checkinstall.cmd" "$($scratchDir)\Windows\checkinstall.cmd" -force
		Write-Host "Done copy checkinstall.cmd"

		Write-Host "Creating a directory that allows to bypass Wifi setup"
		New-Item -ItemType Directory -Force -Path "$($scratchDir)\Windows\System32\OOBE\BYPASSNRO"

		Write-Host "Loading registry"
		reg load HKLM\zCOMPONENTS "$($scratchDir)\Windows\System32\config\COMPONENTS"
		reg load HKLM\zDEFAULT "$($scratchDir)\Windows\System32\config\default"
		reg load HKLM\zNTUSER "$($scratchDir)\Users\Default\ntuser.dat"
		reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE"
		reg load HKLM\zSYSTEM "$($scratchDir)\Windows\System32\config\SYSTEM"

		Write-Host "Disabling Teams"
		reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall" /t REG_DWORD /d 0 /f   >$null 2>&1
		reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 2 /f                             >$null 2>&1
		reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f        >$null 2>&1  
		reg query "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall"                      >$null 2>&1
		# Write-Host Error code $LASTEXITCODE
		Write-Host "Done disabling Teams"

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

		if (!$keepEdge)
		{
			Write-Host "Removing Edge icon from taskbar"
			reg delete "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "Favorites" /f 		  >$null 2>&1
			reg delete "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesChanges" /f   >$null 2>&1
			reg delete "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "Pinned" /f             >$null 2>&1
			reg delete "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "LayoutCycle" /f        >$null 2>&1
			Write-Host "Edge icon removed from taskbar"
		}

		reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f
		Write-Host "Setting all services to start manually"
		reg add "HKLM\zSOFTWARE\CurrentControlSet\Services" /v Start /t REG_DWORD /d 3 /f
		# Write-Host $LASTEXITCODE

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

		Write-Host "Changing theme to dark. This only works on Activated Windows"
		reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
		reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f

	} catch {
        Write-Error "An unexpected error occurred: $_"
    } finally {
		Write-Host "Unmounting Registry..."
		reg unload HKLM\zCOMPONENTS
		reg unload HKLM\zDEFAULT
		reg unload HKLM\zNTUSER
		reg unload HKLM\zSOFTWARE
		reg unload HKLM\zSYSTEM

		Write-Host "Cleaning up image..."
		dism /English /image:$scratchDir /Cleanup-Image /StartComponentCleanup /ResetBase
		Write-Host "Cleanup complete."

		Write-Host "Unmounting image..."
		dism /unmount-image /mountdir:$scratchDir /commit
	} 
	
	try {

		Write-Host "Exporting image into $mountDir\sources\install2.wim"
		dism /Export-Image /SourceImageFile:"$mountDir\sources\install.wim" /SourceIndex:$index /DestinationImageFile:"$mountDir\sources\install2.wim" /compress:max
		Write-Host "Remove old '$mountDir\sources\install.wim' and rename $mountDir\sources\install2.wim"
		Remove-Item "$mountDir\sources\install.wim"
		Rename-Item "$mountDir\sources\install2.wim" "$mountDir\sources\install.wim"

		if (-not (Test-Path -Path "$mountDir\sources\install.wim"))
		{
			Write-Error "Something went wrong and '$mountDir\sources\install.wim' doesn't exist. Please report this bug to the devs"
			return
		}
		Write-Host "Windows image completed. Continuing with boot.wim."

		# Next step boot image		
		Write-Host "Mounting boot image $mountDir\sources\boot.wim into $scratchDir"
		dism /mount-image /imagefile:"$mountDir\sources\boot.wim" /index:2 /mountdir:"$scratchDir"

		if ($injectDrivers)
		{
			$driverPath = $sync.MicrowinDriverLocation.Text
			if (Test-Path $driverPath)
			{
				Write-Host "Adding Windows Drivers image($scratchDir) drivers($driverPath) "
				dism /English /image:$scratchDir /add-driver /driver:$driverPath /recurse | Out-Host
			}
			else 
			{
				Write-Host "Path to drivers is invalid continuing without driver injection"
			}
		}
	
		Write-Host "Loading registry..."
		reg load HKLM\zCOMPONENTS "$($scratchDir)\Windows\System32\config\COMPONENTS" >$null
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
	} catch {
        Write-Error "An unexpected error occurred: $_"
    } finally {
		Write-Host "Unmounting Registry..."
		reg unload HKLM\zCOMPONENTS
		reg unload HKLM\zDEFAULT
		reg unload HKLM\zNTUSER
		reg unload HKLM\zSOFTWARE
		reg unload HKLM\zSYSTEM

		Write-Host "Unmounting image..."
		dism /unmount-image /mountdir:$scratchDir /commit 

		Write-Host "Creating ISO image"

		# if we downloaded oscdimg from github it will be in the temp directory so use it
		# if it is not in temp it is part of ADK and is in global PATH so just set it to oscdimg.exe
		$oscdimgPath = Join-Path $env:TEMP 'oscdimg.exe'
		$oscdImgFound = Test-Path $oscdimgPath -PathType Leaf
		if (!$oscdImgFound)
		{
			$oscdimgPath = "oscdimg.exe"
		}

		Write-Host "[INFO] Using oscdimg.exe from: $oscdimgPath"
		#& oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,b$mountDir\boot\etfsboot.com#pEF,e,b$mountDir\efi\microsoft\boot\efisys.bin $mountDir $env:temp\microwin.iso
		#Start-Process -FilePath $oscdimgPath -ArgumentList "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$mountDir\boot\etfsboot.com#pEF,e,b$mountDir\efi\microsoft\boot\efisys.bin $mountDir $env:temp\microwin.iso" -NoNewWindow -Wait
		#Start-Process -FilePath $oscdimgPath -ArgumentList '-m -o -u2 -udfver102 -bootdata:2#p0,e,b$mountDir\boot\etfsboot.com#pEF,e,b$mountDir\efi\microsoft\boot\efisys.bin $mountDir `"$($SaveDialog.FileName)`"' -NoNewWindow -Wait
        $oscdimgProc = New-Object System.Diagnostics.Process
        $oscdimgProc.StartInfo.FileName = $oscdimgPath
        $oscdimgProc.StartInfo.Arguments = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$mountDir\boot\etfsboot.com#pEF,e,b$mountDir\efi\microsoft\boot\efisys.bin $mountDir `"$($SaveDialog.FileName)`""
        $oscdimgProc.StartInfo.CreateNoWindow = $True
        $oscdimgProc.StartInfo.WindowStyle = "Hidden"
        $oscdimgProc.StartInfo.UseShellExecute = $False
        $oscdimgProc.Start()
        $oscdimgProc.WaitForExit()

		if ($copyToUSB)
		{
			Write-Host "Copying target ISO to the USB drive"
			#Copy-ToUSB("$env:temp\microwin.iso")
			Copy-ToUSB("$($SaveDialog.FileName)")
			if ($?) { Write-Host "Done Copying target ISO to USB drive!" } else { Write-Host "ISO copy failed." }
		}
		
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
			#$msg = "Done. ISO image is located here: $env:temp\microwin.iso"
			$msg = "Done. ISO image is located here: $($SaveDialog.FileName)"
			Write-Host $msg
			[System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
		} else {
			Write-Host "ISO creation failed. The "$($mountDir)" directory has not been removed."
		}
		
		$sync.MicrowinOptionsPanel.Visibility = 'Collapsed'
		
		#$sync.MicrowinFinalIsoLocation.Text = "$env:temp\microwin.iso"
        $sync.MicrowinFinalIsoLocation.Text = "$($SaveDialog.FileName)"
		# Allow the machine to sleep again (optional)
		[PowerManagement]::SetThreadExecutionState(0)
		$sync.ProcessRunning = $false
	}
}