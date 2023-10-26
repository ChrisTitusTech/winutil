function ReadAllUIElements {
    $CheckBoxes = $sync.GetEnumerator() | Where-Object {$psitem -like "WPFUpdatessec*"} 
    Foreach ($CheckBox in $CheckBoxes) {
        Write-Host "File path $($Checkbox.Name)"
    }
}

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

	Write-Host "         _                     __    __  _         "
	Write-Host "  /\/\  (_)  ___  _ __   ___  / / /\ \ \(_) _ __   "
	Write-Host " /    \ | | / __|| '__| / _ \ \ \/  \/ /| || '_ \  "
	Write-Host "/ /\/\ \| || (__ | |   | (_) | \  /\  / | || | | | "
	Write-Host "\/    \/|_| \___||_|    \___/   \/  \/  |_||_| |_| "

	# get unattench
	# get firststartup.ps1

	$index = $sync.MicrowinWindowsFlavors.SelectedValue.Split(":")[0].Trim()
	Write-Host "Index chosen: '$index' from $($sync.MicrowinWindowsFlavors.SelectedValue)"

	$keepPackages = $sync.WPFMicrowinKeepProvisionedPackages.IsChecked
	$keepProvisionedPackages = $sync.WPFMicrowinKeepAppxPackages.IsChecked
	$keepDefender = $sync.WPFMicrowinKeepDefender.IsChecked
	$keepEdge = $sync.WPFMicrowinKeepEdge.IsChecked
    # xcopy we can verify files and also not copy files that already exist, but hard to measure
    $mountDir = $sync.MicrowinMountDir.Text
    $scratchDir = $sync.MicrowinScratchDir.Text

    Write-Host "Mounting Windows image. This may take a while."
	dism /mount-image /imagefile:$mountDir\sources\install.wim /index:$index /mountdir:$scratchDir
	Write-Host "Mounting complete! Performing removal of applications..."

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
		Remove-ProvisionedPackages
	}
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

	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\DiagTrack"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\InboxApps"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\SecurityHealthSystray.exe"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\LocationNotificationWindows.exe"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Photo Viewer"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Photo Viewer"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Media Player"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Media Player"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Windows Mail"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Windows Mail"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Internet Explorer"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Internet Explorer"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files (x86)\Microsoft"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Program Files\Microsoft"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\GameBarPresenceWriter"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDriveSetup.exe"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\System32\OneDrive.ico"
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*Windows.Search*" -Directory
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*narratorquickstart*" -Directory
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*Xbox*" -Directory
	Remove-FileOrDirectory -pathToDelete "$($scratchDir)\Windows\SystemApps" -mask "*ParentalControls*" -Directory
	Write-Host "Removal complete!"

	# this doesn't work for some reason, this script is not being run at the end of the install
	# if someone knows how to fix this, feel free to modify
	New-Item -ItemType Directory -Force -Path $scratchDir\Windows\Setup\Scripts\
	# this is just test, if this made to work properly, this is where final cleanup can happen
	"wmic cpu get Name > C:\cpu.txt" | Out-File -FilePath "$($scratchDir)\Windows\Setup\Scripts\SetupComplete.cmd" -NoClobber -Append
	"wmic bios get serialnumber > C:\SerialNumber.txt" | Out-File -FilePath "$($scratchDir)\Windows\Setup\Scripts\SetupComplete.cmd" -NoClobber -Append
	"devmgmt.msc /s" | Out-File -FilePath "$($scratchDir)\Windows\Setup\Scripts\SetupComplete.cmd" -NoClobber -Append
	New-Item -ItemType Directory -Force -Path $scratchDir\Windows\Panther
	Copy-Item $pwd\unattend.xml $scratchDir\Windows\Panther\unattend.xml -force
	New-Item -ItemType Directory -Force -Path $scratchDir\Windows\System32\Sysprep
	Copy-Item $pwd\unattend.xml $scratchDir\Windows\System32\Sysprep\unattend.xml -force
	Copy-Item $pwd\FirstStartup.ps1 $scratchDir\Windows\FirstStartup.ps1 -force
	Copy-Item $pwd\winutil.ps1 $scratchDir\Windows\winutil.ps1 -force

	# in case we want to get the file from the internet instead?
	# Write-Host "Download latest winutil.ps1"
	# Invoke-WebRequest -Uri "https://christitus.com/win" -OutFile "$($scratchDir)\Windows\system32\winutil.ps1"

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

	Write-Host "Unmounting Registry..."
	reg unload HKLM\zCOMPONENTS
	reg unload HKLM\zDEFAULT
	reg unload HKLM\zNTUSER
	reg unload HKLM\zSOFTWARE
	reg unload HKLM\zSYSTEM

	Write-Host "Cleaning up image..."
	dism /image:$scratchDir /Cleanup-Image /StartComponentCleanup /ResetBase
	Write-Host "Cleanup complete."

	Write-Host "Unmounting image..."
	dism /unmount-image /mountdir:$scratchDir /commit

	Write-Host "Exporting image..."
	dism /Export-Image /SourceImageFile:$mountDir\sources\install.wim /SourceIndex:$index /DestinationImageFile:$mountDir\sources\install2.wim /compress:max
	Remove-Item $mountDir\sources\install.wim
	Rename-Item $mountDir\sources\install2.wim install.wim

	Write-Host "Windows image completed. Continuing with boot.wim."

	Write-Host "Mounting boot image:"
	dism /mount-image /imagefile:$mountDir\sources\boot.wim /index:2 /mountdir:$scratchDir

	Write-Host "Loading registry..."
	reg load HKLM\zCOMPONENTS "$($scratchDir)\Windows\System32\config\COMPONENTS" >$null
	reg load HKLM\zDEFAULT "$($scratchDir)\Windows\System32\config\default" >$null
	reg load HKLM\zNTUSER "$($scratchDir)\Users\Default\ntuser.dat" >$null
	reg load HKLM\zSOFTWARE "$($scratchDir)\Windows\System32\config\SOFTWARE" >$null
	reg load HKLM\zSYSTEM "$($scratchDir)\Windows\System32\config\SYSTEM" >$null
	Write-Host "Bypassing system requirements(on the setup image)"
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

	Write-Host "Unmounting Registry..."
	reg unload HKLM\zCOMPONENTS
	reg unload HKLM\zDEFAULT
	reg unload HKLM\zNTUSER
	reg unload HKLM\zSOFTWARE
	reg unload HKLM\zSYSTEM

	Write-Host "Unmounting image..."
	dism /unmount-image /mountdir:$scratchDir /commit 

	Write-Host "Creating ISO image"
	& oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,b$mountDir\boot\etfsboot.com#pEF,e,b$mountDir\efi\microsoft\boot\efisys.bin $mountDir $pwd\microwin.iso
	Write-Host "Performing Cleanup"
	Remove-Item -Recurse -Force "$($scratchDir)"
	Remove-Item -Recurse -Force "$($mountDir)"
	Write-Host " _____                       "
	Write-Host "(____ \                      "
	Write-Host " _   \ \ ___  ____   ____    "
	Write-Host "| |   | / _ \|  _ \ / _  )   "
	Write-Host "| |__/ / |_| | | | ( (/ /    "
	Write-Host "|_____/ \___/|_| |_|\____)   "
	$sync.ProcessRunning = $false
}