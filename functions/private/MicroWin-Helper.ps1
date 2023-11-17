

function Remove-Features([switch] $dumpFeatures = $false, [switch] $keepDefender = $false)
{
	$appxlist = dism /image:$scratchDir /Get-Features | Select-String -Pattern "Feature Name : " -CaseSensitive -SimpleMatch
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
		$status = "Removing featue $feature"
		Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$appxlist.Count*100)
		Write-Debug "Removing featue $feature"
		dism /image:$scratchDir /Disable-Feature /FeatureName:$feature /Remove /NoRestart > $null
	}
	Write-Progress -Activity "Removing features" -Status "Ready" -Completed
}

function Remove-Packages
{
	$appxlist = dism /Image:$scratchDir /Get-Packages | Select-String -Pattern "Package Identity : " -CaseSensitive -SimpleMatch
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
		$status | Out-File "microwin.log" -Append
		Write-Progress -Activity "Removing Apps" -Status $status -PercentComplete ($counter++/$appxlist.Count*100)
		dism /image:$scratchDir /Remove-Package /PackageName:$appx /NoRestart
	}
	Write-Progress -Activity "Removing Apps" -Status "Ready" -Completed
}

function Remove-ProvisionedPackages
{
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

	$counter = 0
	foreach ($appx in $appxProvisionedPackages)
	{
		$status = "Removing Provisioned $appx"
		$status | Out-File "microwin.log" -Append
		Write-Progress -Activity "Removing Provisioned Apps" -Status $status -PercentComplete ($counter++/$appxProvisionedPackages.Count*100)
		dism /image:$scratchDir /Remove-ProvisionedAppxPackage /PackageName:$appx /NoRestart
								
	}
	Write-Progress -Activity "Removing Provisioned Apps" -Status "Ready" -Completed
}

function Disable-StartupApps
{
	$regStartList = Get-Item -path $32bit,$32bitRunOnce,$64bit,$64bitRunOnce,$currentLOU,$currentLOURunOnce | Where-Object {$_.ValueCount -ne 0} | Select-Object  property,name
	
	foreach ($regName in $regStartList.name) 
	{
		$regNumber = ($regName).IndexOf("\")
		$regLocation = ($regName).Insert("$regNumber",":")
		if ($regLocation -like "*HKEY_LOCAL_MACHINE*")
		{
			$regLocation = $regLocation.Replace("HKEY_LOCAL_MACHINE","HKLM")
			write-host $regLocation
		}
		if ($regLocation -like "*HKEY_CURRENT_USER*")
		{
			$regLocation = $regLocation.Replace("HKEY_CURRENT_USER","HKCU")
			write-host $regLocation
		}
		foreach ($disable in $disableList) 
		{
			if (Get-ItemProperty -Path "$reglocation" -name "$Disable" -ErrorAction SilentlyContinue) {
				Write-host "yeah i exist"
				#Remove-ItemProperty -Path "$location" -Name "$($startUp.name)" -whatif
			}else {write-host "no exist"}
		}   
	}
}
function Remove-FileOrDirectory([string] $pathToDelete, [string] $mask = "", [switch] $Directory = $false)
{
	if(([string]::IsNullOrEmpty($pathToDelete))) { return }
	if (-not (Test-Path -Path "$($pathToDelete)")) { return }

	# special code, for some reason when you try to delete some inbox apps
	# we have to get and delete log files directory. 
	Set-Owner -Path "$($scratchDir)\Windows\System32\LogFiles\WMI\RtBackup" -Recurse -Verbose
	icacls "$($scratchDir)\Windows\System32\LogFiles\WMI\RtBackup" /q /c /t /reset > $null
	
	Set-Owner -Path "$($scratchDir)\Windows\System32\WebThreatDefSvc" -Recurse -Verbose
	icacls "$($scratchDir)\Windows\System32\WebThreatDefSvc" /q /c /t /reset > $null
	
	$itemsToDelete = [System.Collections.ArrayList]::new()

	if ($mask -eq "")
	{
		Write-Debug "!!!!!!Adding $($pathToDelete) to array!!!!!!"
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
			$status | Out-File "microwin.log" -Append
			takeown /a /r /d Y /f "$($itemToDelete)" > $null
			icacls "$($itemToDelete)" /q /c /t /reset > $null
			Remove-Item -Force -Recurse "$($itemToDelete)"
		}
		elseif (Test-Path -Path "$($itemToDelete)" -PathType Leaf)
		{
			$status = "Deleting file: $($itemToDelete)"
			$status | Out-File "microwin.log" -Append
			takeown /f "$($itemToDelete)" > $null
			icacls "$($itemToDelete)" /grant Administrators:F /t /c > $null
			Remove-Item -Force "$($itemToDelete)"
		}
	}
	Write-Progress -Activity "Removing Items" -Status "Ready" -Completed
}

function New-Unattend {

	$unattend = @"
	<?xml version="1.0" encoding="utf-8"?>
	<unattend xmlns="urn:schemas-microsoft-com:unattend"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		<settings pass="specialize">
			<component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<CEIPEnabled>0</CEIPEnabled>
			</component>
			<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<ConfigureChatAutoInstall>false</ConfigureChatAutoInstall>
			</component>
			<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<RunSynchronous>
					<RunSynchronousCommand wcm:action="add">
						<Order>1</Order>
						<Path>CMD /C date 0&lt;C:\Windows\LogSpecialize.txt</Path>
						<Description>Set date</Description>
					</RunSynchronousCommand>
				</RunSynchronous>
			</component>
		</settings>
		<settings pass="auditUser">
			<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<RunSynchronous>
					<RunSynchronousCommand wcm:action="add">
						<Order>1</Order>
						<Path>net user administrator /active:yes</Path>
					</RunSynchronousCommand>
					<RunSynchronousCommand wcm:action="add">
						<Order>2</Order>
						<Path>CMD /C date 0&lt;C:\Windows\LogAuditUser.txt</Path>
						<Description>StartMenu</Description>
					</RunSynchronousCommand>
				</RunSynchronous>
			</component>
		</settings>
		<settings pass="oobeSystem">
			<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				  <OOBE>
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
						<CommandLine>powershell -ExecutionPolicy Bypass -File c:\windows\FirstStartup.ps1</CommandLine>
					</SynchronousCommand>
					<SynchronousCommand wcm:action="add">
						<Order>3</Order>
						<CommandLine>CMD /C date 0&lt;C:\Windows\LogOobeSystem.txt</CommandLine>
					</SynchronousCommand>
				</FirstLogonCommands>
			</component>
		</settings>
	</unattend>
"@
	$unattend | Out-File -FilePath "$env:temp\unattend.xml" -Force
}

function New-FirstRun {

	$firstRun = @"
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
		$servicesAuto = @(
			"AudioEndpointBuilder",
			"AudioSrv",
			"Audiosrv",
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
	
		$allServices = Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $servicesAuto -NotContains $_.Name}
		foreach($service in $allServices)
		{
			Stop-Service -Name $service.Name -PassThru
			Set-Service $service.Name -StartupType Manual
			"Stopping service $service" | Out-File -FilePath c:\windows\LogProcess.txt -Append
		}
	}
	
	"FirstStartup has worked" | Out-File -FilePath c:\windows\LogProcess.txt -Append
	
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
	# Delete all files in the Taskbar directory
	Get-ChildItem -Path $taskbarPath -File | Remove-Item -Force
	
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesRemovedChanges"
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesChanges"
	Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "Favorites"
	
	# Delete Edge Icon from desktop
	$desktopPath = [Environment]::GetFolderPath('Desktop')
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
	
	# Restart the explorer process
	Stop-Process -Name explorer -Force
	Start-Process explorer
	
	if (Test-Path 'C:\Windows\winutil.ps1') 
	{ 
	#    Invoke-Expression -Command "winget install --id nomacs"
		Invoke-Expression -Command "C:\Windows\winutil.ps1"
	}
"@
	$firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force 
}