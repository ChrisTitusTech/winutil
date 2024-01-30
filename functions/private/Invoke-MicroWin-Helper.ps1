function Invoke-MicroWin-Helper {
<#

    .SYNOPSIS
        checking unit tests

    .PARAMETER Name
        no parameters

    .EXAMPLE
        placeholder

#>

}

function Is-CompatibleImage() {
<#

    .SYNOPSIS
        Checks the version of a Windows image and determines whether or not it is compatible depending on the Major property

    .PARAMETER imgVersion
        The version of the Windows image

#>

    param
    (
        [Parameter(Mandatory = $true)] [string] $imgVersion
    )

    try {
        $version = [Version]$imgVersion
        if ($version.Major -ge 10)
        {
            return $True
        }
        else
        {
            return $False
        }
    } catch {
        return $False
    }
}

function Remove-Features([switch] $dumpFeatures = $false, [switch] $keepDefender = $false) {
<#

    .SYNOPSIS
        Removes certain features from ISO image

    .PARAMETER Name
        dumpFeatures - Dumps all features found in the ISO into a file called allfeaturesdump.txt. This file can be examined and used to decide what to remove.
		keepDefender - Should Defender be removed from the ISO?

    .EXAMPLE
        Remove-Features -keepDefender:$false

#>
	$appxlist = dism /English /image:$scratchDir /Get-Features | Select-String -Pattern "Feature Name : " -CaseSensitive -SimpleMatch
	$appxlist = $appxlist -split "Feature Name : " | Where-Object {$_}
	if ($dumpFeatures)
	{
		$appxlist > allfeaturesdump.txt
	}

	$appxlist = $appxlist | Where-Object {
		$_ -NotLike "*Printing*" -AND
		$_ -NotLike "*TelnetClient*" -AND
		$_ -NotLike "*PowerShell*" -AND
		$_ -NotLike "*NetFx*"
	}

	if ($keepDefender) { $appxlist = $appxlist | Where-Object { $_ -NotLike "*Defender*" }}

	foreach($feature in $appxlist)
	{
		$status = "Removing feature $feature"
		Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$appxlist.Count*100)
		Write-Debug "Removing feature $feature"
		# dism /image:$scratchDir /Disable-Feature /FeatureName:$feature /Remove /NoRestart > $null
	}
	Write-Progress -Activity "Removing features" -Status "Ready" -Completed
}

function Remove-Packages
{
	$appxlist = dism /English /Image:$scratchDir /Get-Packages | Select-String -Pattern "Package Identity : " -CaseSensitive -SimpleMatch
	$appxlist = $appxlist -split "Package Identity : " | Where-Object {$_}

	$appxlist = $appxlist | Where-Object {
			$_ -NotLike "*ApplicationModel*" -AND
			$_ -NotLike "*indows-Client-LanguagePack*" -AND
			$_ -NotLike "*LanguageFeatures-Basic*" -AND
			$_ -NotLike "*Package_for_ServicingStack*" -AND
			$_ -NotLike "*.NET*" -AND
			$_ -NotLike "*Store*" -AND
			$_ -NotLike "*VCLibs*" -AND
			$_ -NotLike "*AAD.BrokerPlugin",
			$_ -NotLike "*LockApp*" -AND
			$_ -NotLike "*Notepad*" -AND
			$_ -NotLike "*immersivecontrolpanel*" -AND
			$_ -NotLike "*ContentDeliveryManager*" -AND
			$_ -NotLike "*PinningConfirMationDialog*" -AND
			$_ -NotLike "*SecHealthUI*" -AND
			$_ -NotLike "*SecureAssessmentBrowser*" -AND
			$_ -NotLike "*PrintDialog*" -AND
			$_ -NotLike "*AssignedAccessLockApp*" -AND
			$_ -NotLike "*OOBENetworkConnectionFlow*" -AND
			$_ -NotLike "*Apprep.ChxApp*" -AND
			$_ -NotLike "*CBS*" -AND
			$_ -NotLike "*OOBENetworkCaptivePortal*" -AND
			$_ -NotLike "*PeopleExperienceHost*" -AND
			$_ -NotLike "*ParentalControls*" -AND
			$_ -NotLike "*Win32WebViewHost*" -AND
			$_ -NotLike "*InputApp*" -AND
			$_ -NotLike "*AccountsControl*" -AND
			$_ -NotLike "*AsyncTextService*" -AND
			$_ -NotLike "*CapturePicker*" -AND
			$_ -NotLike "*CredDialogHost*" -AND
			$_ -NotLike "*BioEnrollMent*" -AND
			$_ -NotLike "*ShellExperienceHost*" -AND
			$_ -NotLike "*DesktopAppInstaller*" -AND
			$_ -NotLike "*WebMediaExtensions*" -AND
			$_ -NotLike "*WMIC*" -AND
			$_ -NotLike "*UI.XaML*"	
		} 

	foreach ($appx in $appxlist)
	{
		$status = "Removing $appx"
		Write-Progress -Activity "Removing Apps" -Status $status -PercentComplete ($counter++/$appxlist.Count*100)
		dism /English /image:$scratchDir /Remove-Package /PackageName:$appx /NoRestart
	}
	Write-Progress -Activity "Removing Apps" -Status "Ready" -Completed
}

function Remove-ProvisionedPackages([switch] $keepSecurity = $false)
{
<#

    .SYNOPSIS
        Removes AppX packages from a Windows image during MicroWin processing

    .PARAMETER Name
        keepSecurity - Boolean that determines whether to keep "Microsoft.SecHealthUI" (Windows Security) in the Windows image

    .EXAMPLE
        Remove-ProvisionedPackages -keepSecurity:$false

#>
	$appxProvisionedPackages = Get-AppxProvisionedPackage -Path "$($scratchDir)" | Where-Object	{
			$_.PackageName -NotLike "*AppInstaller*" -AND
			$_.PackageName -NotLike "*Store*" -and
			$_.PackageName -NotLike "*dism*" -and
			$_.PackageName -NotLike "*Foundation*" -and
			$_.PackageName -NotLike "*FodMetadata*" -and
			$_.PackageName -NotLike "*LanguageFeatures*" -and
			$_.PackageName -NotLike "*Notepad*" -and
			$_.PackageName -NotLike "*Printing*" -and
			$_.PackageName -NotLike "*Wifi*" -and
			$_.PackageName -NotLike "*Foundation*" 
		} 
    
    if ($?)
    {
        if ($keepSecurity) { $appxProvisionedPackages = $appxProvisionedPackages | Where-Object { $_.PackageName -NotLike "*SecHealthUI*" }}
	    $counter = 0
	    foreach ($appx in $appxProvisionedPackages)
	    {
		    $status = "Removing Provisioned $($appx.PackageName)"
		    Write-Progress -Activity "Removing Provisioned Apps" -Status $status -PercentComplete ($counter++/$appxProvisionedPackages.Count*100)
		    dism /English /image:$scratchDir /Remove-ProvisionedAppxPackage /PackageName:$($appx.PackageName) /NoRestart
	    }
	    Write-Progress -Activity "Removing Provisioned Apps" -Status "Ready" -Completed
    }
    else
    {
        Write-Host "Could not get Provisioned App information. Skipping process..."
    }
}

function Copy-ToUSB([string] $fileToCopy)
{
	foreach ($volume in Get-Volume) {
		if ($volume -and $volume.FileSystemLabel -ieq "ventoy") {
			$destinationPath = "$($volume.DriveLetter):\"
			#Copy-Item -Path $fileToCopy -Destination $destinationPath -Force
			# Get the total size of the file
			$totalSize = (Get-Item $fileToCopy).length

			Copy-Item -Path $fileToCopy -Destination $destinationPath -Verbose -Force -Recurse -Container -PassThru |
				ForEach-Object {
					# Calculate the percentage completed
					$completed = ($_.BytesTransferred / $totalSize) * 100

					# Display the progress bar
					Write-Progress -Activity "Copying File" -Status "Progress" -PercentComplete $completed -CurrentOperation ("{0:N2} MB / {1:N2} MB" -f ($_.BytesTransferred / 1MB), ($totalSize / 1MB))
				}

			Write-Host "File copied to Ventoy drive $($volume.DriveLette)"
			return
		}
	}
	Write-Host "Ventoy USB Key is not inserted"
}

function Remove-FileOrDirectory([string] $pathToDelete, [string] $mask = "", [switch] $Directory = $false)
{
	if(([string]::IsNullOrEmpty($pathToDelete))) { return }
	if (-not (Test-Path -Path "$($pathToDelete)")) { return }

	$yesNo = Get-LocalizedYesNo
	Write-Host "[INFO] In Your local takeown expects '$($yesNo[0])' as a Yes answer."

	# Specify the path to the directory
	# $directoryPath = "$($scratchDir)\Windows\System32\LogFiles\WMI\RtBackup"
	# takeown /a /r /d $yesNo[0] /f "$($directoryPath)" > $null
	# icacls "$($directoryPath)" /q /c /t /reset > $null
	# icacls $directoryPath /setowner "*S-1-5-32-544"
	# icacls $directoryPath /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
	# Remove-Item -Path $directoryPath -Recurse -Force

	# # Grant full control to BUILTIN\Administrators using icacls
	# $directoryPath = "$($scratchDir)\Windows\System32\WebThreatDefSvc" 
	# takeown /a /r /d $yesNo[0] /f "$($directoryPath)" > $null
	# icacls "$($directoryPath)" /q /c /t /reset > $null
	# icacls $directoryPath /setowner "*S-1-5-32-544"
	# icacls $directoryPath /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
	# Remove-Item -Path $directoryPath -Recurse -Force
	
	$itemsToDelete = [System.Collections.ArrayList]::new()

	if ($mask -eq "")
	{
		Write-Debug "Adding $($pathToDelete) to array."
		[void]$itemsToDelete.Add($pathToDelete)
	}
	else 
	{
		Write-Debug "Adding $($pathToDelete) to array and mask is $($mask)" 
		if ($Directory)	{ $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse -Directory }
		else { $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse }
	}

	foreach($itemToDelete in $itemsToDelete)
	{
		$status = "Deleteing $($itemToDelete)"
		Write-Progress -Activity "Removing Items" -Status $status -PercentComplete ($counter++/$itemsToDelete.Count*100)

		if (Test-Path -Path "$($itemToDelete)" -PathType Container) 
		{
			$status = "Deleting directory: $($itemToDelete)"

			takeown /r /d $yesNo[0] /a /f "$($itemToDelete)"
			icacls "$($itemToDelete)" /q /c /t /reset
			icacls $itemToDelete /setowner "*S-1-5-32-544"
			icacls $itemToDelete /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
			Remove-Item -Force -Recurse "$($itemToDelete)"
		}
		elseif (Test-Path -Path "$($itemToDelete)" -PathType Leaf)
		{
			$status = "Deleting file: $($itemToDelete)"

			takeown /a /f "$($itemToDelete)"
			icacls "$($itemToDelete)" /q /c /t /reset
			icacls "$($itemToDelete)" /setowner "*S-1-5-32-544"
			icacls "$($itemToDelete)" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
			Remove-Item -Force "$($itemToDelete)"
		}
	}
	Write-Progress -Activity "Removing Items" -Status "Ready" -Completed
}

function New-Unattend {

	# later if we wont to remove even more bloat EU requires MS to remove everything from English(world)
	# Below is an example how to do it we probably should create a drop down with common locals
	# 	<settings pass="specialize">
	#     <!-- Specify English (World) locale -->
	#     <component name="Microsoft-Windows-International-Core" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	#       <SetupUILanguage>
	#         <UILanguage>en-US</UILanguage>
	#       </SetupUILanguage>
	#       <InputLocale>en-US</InputLocale>
	#       <SystemLocale>en-US</SystemLocale>
	#       <UILanguage>en-US</UILanguage>
	#       <UserLocale>en-US</UserLocale>
	#     </component>
	#   </settings>

	#   <settings pass="oobeSystem">
	#     <!-- Specify English (World) locale -->
	#     <component name="Microsoft-Windows-International-Core" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	#       <InputLocale>en-US</InputLocale>
	#       <SystemLocale>en-US</SystemLocale>
	#       <UILanguage>en-US</UILanguage>
	#       <UserLocale>en-US</UserLocale>
	#     </component>
	#   </settings>
	# using here string to embedd unattend
	# 	<RunSynchronousCommand wcm:action="add">
	# 	<Order>1</Order>
	# 	<Path>net user administrator /active:yes</Path>
	# </RunSynchronousCommand>

	# this section doesn't work in win10/????
# 	<settings pass="specialize">
# 	<component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
# 		<CEIPEnabled>0</CEIPEnabled>
# 	</component>
# 	<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
# 		<ConfigureChatAutoInstall>false</ConfigureChatAutoInstall>
# 	</component>
# </settings>

	$unattend = @'
	<?xml version="1.0" encoding="utf-8"?>
	<unattend xmlns="urn:schemas-microsoft-com:unattend"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

		<settings pass="auditUser">
			<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<RunSynchronous>
					<RunSynchronousCommand wcm:action="add">
						<Order>1</Order>
						<CommandLine>CMD /C echo LAU GG&gt;C:\Windows\LogAuditUser.txt</CommandLine>
						<Description>StartMenu</Description>
					</RunSynchronousCommand>
				</RunSynchronous>
			</component>
		</settings>
		<settings pass="oobeSystem">
			<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<OOBE>
                	<HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
	                <SkipUserOOBE>false</SkipUserOOBE>
                	<SkipMachineOOBE>false</SkipMachineOOBE>
					<HideOnlineAccountScreens>true</HideOnlineAccountScreens>
					<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
					<HideEULAPage>true</HideEULAPage>
					<ProtectYourPC>3</ProtectYourPC>
				</OOBE>
				<FirstLogonCommands>
					<SynchronousCommand wcm:action="add">
						<Order>1</Order>
						<CommandLine>cmd.exe /c echo 23&gt;c:\windows\csup.txt</CommandLine>
					</SynchronousCommand>
					<SynchronousCommand wcm:action="add">
						<Order>2</Order>
						<CommandLine>CMD /C echo GG&gt;C:\Windows\LogOobeSystem.txt</CommandLine>
					</SynchronousCommand>
					<SynchronousCommand wcm:action="add">
						<Order>3</Order>
						<CommandLine>powershell -ExecutionPolicy Bypass -File c:\windows\FirstStartup.ps1</CommandLine>
					</SynchronousCommand>
				</FirstLogonCommands>
			</component>
		</settings>
	</unattend>
'@
	$unattend | Out-File -FilePath "$env:temp\unattend.xml" -Force
}

function New-CheckInstall {

	# using here string to embedd firstrun
	$checkInstall = @'
	@echo off
	if exist "C:\windows\cpu.txt" (
		echo C:\windows\cpu.txt exists
	) else (
		echo C:\windows\cpu.txt does not exist
	)
	if exist "C:\windows\SerialNumber.txt" (
		echo C:\windows\SerialNumber.txt exists
	) else (
		echo C:\windows\SerialNumber.txt does not exist
	)
	if exist "C:\unattend.xml" (
		echo C:\unattend.xml exists
	) else (
		echo C:\unattend.xml does not exist
	)
	if exist "C:\Windows\Setup\Scripts\SetupComplete.cmd" (
		echo C:\Windows\Setup\Scripts\SetupComplete.cmd exists
	) else (
		echo C:\Windows\Setup\Scripts\SetupComplete.cmd does not exist
	)
	if exist "C:\Windows\Panther\unattend.xml" (
		echo C:\Windows\Panther\unattend.xml exists
	) else (
		echo C:\Windows\Panther\unattend.xml does not exist
	)
	if exist "C:\Windows\System32\Sysprep\unattend.xml" (
		echo C:\Windows\System32\Sysprep\unattend.xml exists
	) else (
		echo C:\Windows\System32\Sysprep\unattend.xml does not exist
	)
	if exist "C:\Windows\FirstStartup.ps1" (
		echo C:\Windows\FirstStartup.ps1 exists
	) else (
		echo C:\Windows\FirstStartup.ps1 does not exist
	)
	if exist "C:\Windows\winutil.ps1" (
		echo C:\Windows\winutil.ps1 exists
	) else (
		echo C:\Windows\winutil.ps1 does not exist
	)
	if exist "C:\Windows\LogSpecialize.txt" (
		echo C:\Windows\LogSpecialize.txt exists
	) else (
		echo C:\Windows\LogSpecialize.txt does not exist
	)
	if exist "C:\Windows\LogAuditUser.txt" (
		echo C:\Windows\LogAuditUser.txt exists
	) else (
		echo C:\Windows\LogAuditUser.txt does not exist
	)
	if exist "C:\Windows\LogOobeSystem.txt" (
		echo C:\Windows\LogOobeSystem.txt exists
	) else (
		echo C:\Windows\LogOobeSystem.txt does not exist
	)
	if exist "c:\windows\csup.txt" (
		echo c:\windows\csup.txt exists
	) else (
		echo c:\windows\csup.txt does not exist
	)
	if exist "c:\windows\LogFirstRun.txt" (
		echo c:\windows\LogFirstRun.txt exists
	) else (
		echo c:\windows\LogFirstRun.txt does not exist
	)
'@
	$checkInstall | Out-File -FilePath "$env:temp\checkinstall.cmd" -Force -Encoding Ascii
}

function New-FirstRun {

	# using here string to embedd firstrun
	$firstRun = @'
	# Set the global error action preference to continue
	$ErrorActionPreference = "Continue"
	function Remove-RegistryValue
	{
		param (
			[Parameter(Mandatory = $true)]
			[string]$RegistryPath,
	
			[Parameter(Mandatory = $true)]
			[string]$ValueName
		)
	
		# Check if the registry path exists
		if (Test-Path -Path $RegistryPath)
		{
			$registryValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
	
			# Check if the registry value exists
			if ($registryValue)
			{
				# Remove the registry value
				Remove-ItemProperty -Path $RegistryPath -Name $ValueName -Force
				Write-Host "Registry value '$ValueName' removed from '$RegistryPath'."
			}
			else
			{
				Write-Host "Registry value '$ValueName' not found in '$RegistryPath'."
			}
		}
		else
		{
			Write-Host "Registry path '$RegistryPath' not found."
		}
	}
	
	function Stop-UnnecessaryServices
	{
		$servicesToExclude = @(
			"AudioSrv",
			"AudioEndpointBuilder",
			"BFE",
			"BITS",
			"BrokerInfrastructure",
			"CDPSvc",
			"CDPUserSvc_dc2a4",
			"CoreMessagingRegistrar",
			"CryptSvc",
			"DPS",
			"DcomLaunch",
			"Dhcp",
			"DispBrokerDesktopSvc",
			"Dnscache",
			"DoSvc",
			"DusmSvc",
			"EventLog",
			"EventSystem",
			"FontCache",
			"LSM",
			"LanmanServer",
			"LanmanWorkstation",
			"MapsBroker",
			"MpsSvc",
			"OneSyncSvc_dc2a4",
			"Power",
			"ProfSvc",
			"RpcEptMapper",
			"RpcSs",
			"SCardSvr",
			"SENS",
			"SamSs",
			"Schedule",
			"SgrmBroker",
			"ShellHWDetection",
			"Spooler",
			"SysMain",
			"SystemEventsBroker",
			"TextInputManagementService",
			"Themes",
			"TrkWks",
			"UserManager",
			"VGAuthService",
			"VMTools",
			"WSearch",
			"Wcmsvc",
			"WinDefend",
			"Winmgmt",
			"WlanSvc",
			"WpnService",
			"WpnUserService_dc2a4",
			"cbdhsvc_dc2a4",
			"edgeupdate",
			"gpsvc",
			"iphlpsvc",
			"mpssvc",
			"nsi",
			"sppsvc",
			"tiledatamodelsvc",
			"vm3dservice",
			"webthreatdefusersvc_dc2a4",
			"wscsvc"
)	
	
		$runningServices = Get-Service | Where-Object { $servicesToExclude -notcontains $_.Name }
		foreach($service in $runningServices)
		{
            Stop-Service -Name $service.Name -PassThru
			Set-Service $service.Name -StartupType Manual
			"Stopping service $($service.Name)" | Out-File -FilePath c:\windows\LogFirstRun.txt -Append -NoClobber
		}
	}
	
	"FirstStartup has worked" | Out-File -FilePath c:\windows\LogFirstRun.txt -Append -NoClobber
	
	$Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
	Set-ItemProperty -Path $Theme -Name AppsUseLightTheme -Value 1
	Set-ItemProperty -Path $Theme -Name SystemUsesLightTheme -Value 1

	# figure this out later how to set updates to security only
	#Import-Module -Name PSWindowsUpdate; 
	#Stop-Service -Name wuauserv
	#Set-WUSettings -MicrosoftUpdateEnabled -AutoUpdateOption 'Never'
	#Start-Service -Name wuauserv
	
	Stop-UnnecessaryServices
	
	$taskbarPath = "$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
	# Delete all files on the Taskbar 
	Get-ChildItem -Path $taskbarPath -File | Remove-Item -Force
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesRemovedChanges"
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesChanges"
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "Favorites"
	
	# Stop-Process -Name explorer -Force

	$process = Get-Process -Name "explorer"
	Stop-Process -InputObject $process
	# Wait for the process to exit
	Wait-Process -InputObject $process
	Start-Sleep -Seconds 3

	# Delete Edge Icon from the desktop
	$edgeShortcutFiles = Get-ChildItem -Path $desktopPath -Filter "*Edge*.lnk"
	# Check if Edge shortcuts exist on the desktop
	if ($edgeShortcutFiles) 
	{
		foreach ($shortcutFile in $edgeShortcutFiles) 
		{
			# Remove each Edge shortcut
			Remove-Item -Path $shortcutFile.FullName -Force
			Write-Host "Edge shortcut '$($shortcutFile.Name)' removed from the desktop."
		}
	}
	Remove-Item -Path "$env:USERPROFILE\Desktop\*.lnk"
	Remove-Item -Path "C:\Users\Default\Desktop\*.lnk"

	# ************************************************
	# Create WinUtil shortcut on the desktop
	#
	$desktopPath = "$($env:USERPROFILE)\Desktop"
	# Specify the target PowerShell command
	$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://christitus.com/win | iex'"
	# Specify the path for the shortcut
	$shortcutPath = Join-Path $desktopPath 'winutil.lnk'
	# Create a shell object
	$shell = New-Object -ComObject WScript.Shell
	
	# Create a shortcut object
	$shortcut = $shell.CreateShortcut($shortcutPath)

	if (Test-Path -Path "c:\Windows\cttlogo.png")
	{
		$shortcut.IconLocation = "c:\Windows\cttlogo.png"
	}
	
	# Set properties of the shortcut
	$shortcut.TargetPath = "powershell.exe"
	$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
	# Save the shortcut
	$shortcut.Save()
	Write-Host "Shortcut created at: $shortcutPath"
	# 
	# Done create WinUtil shortcut on the desktop
	# ************************************************

	Start-Process explorer
	
'@
	$firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force 
}