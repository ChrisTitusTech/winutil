$ProgressPreference = 'SilentlyContinue'
Write-Host "Running winutil tweaks please wait..."

# WPFTweaksActivity
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name EnableActivityFeed -Value 0
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name PublishUserActivities -Value 0
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name UploadUserActivities -Value 0

# WPFTweaksConsumerFeatures
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent -Name DisableWindowsConsumerFeatures -Value 1

# WPFTweaksWPBT
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name DisableWpbtExecution -Value 1

# WPFTweaksDeBloat
Get-AppxPackage Microsoft.WindowsFeedbackHub | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.BingNews | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.BingSearch | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.BingWeather | Remove-AppxPackage -AllUsers
Get-AppxPackage Clipchamp.Clipchamp | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.Todos | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.PowerAutomateDesktop | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.WindowsSoundRecorder | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.Windows.DevHome | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.Paint | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.OutlookForWindows | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.WindowsAlarms | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.StartExperiencesApp | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.GetHelp | Remove-AppxPackage -AllUsers
Get-AppxPackage Microsoft.ZuneMusic | Remove-AppxPackage -AllUsers
Get-AppxPackage MicrosoftCorporationII.QuickAssist | Remove-AppxPackage -AllUsers
Get-AppxPackage MSTeams | Remove-AppxPackage -AllUsers

# WPFTweaksLocation
Set-Service -Name lfsvc -StartupType Disabled

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name Value -Value Deny
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name SensorPermissionState -Value 0
Set-ItemProperty -Path HKLM:\SYSTEM\Maps -Name AutoUpdateEnabled -Value 0

# WPFTweaksServices
Set-Service -Name CscService -StartupType Disabled
Set-Service -Name DiagTrack -StartupType Disabled
Set-Service -Name MapsBroker -StartupType Manual
Set-Service -Name StorSvc -StartupType Manual
Set-Service -Name SharedAccess -StartupType Disabled

$Memory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control -Name SvcHostSplitThresholdInKB -Value $Memory

# WPFTweaksTelemetry
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy -Name TailoredExperiencesWithDiagnosticDataEnabled -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy -Name HasAccepted -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Input\TIPC -Name Enabled -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\InputPersonalization -Name RestrictImplicitInkCollection -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\InputPersonalization -Name RestrictImplicitTextCollection -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore -Name HarvestContacts -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Personalization\Settings -Name AcceptedPrivacyPolicy -Value 0
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name AllowTelemetry -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Start_TrackProgs -Value 0
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name PublishUserActivities -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Siuf\Rules -Name NumberOfSIUFInPeriod -Value 0
Remove-ItemProperty -Path HKCU:\Software\Microsoft\Siuf\Rules -Name PeriodInNanoSeconds

Set-MpPreference -SubmitSamplesConsent 2

Set-Service -Name diagtrack -StartupType Disabled
Set-Service -Name wermgr -StartupType Disabled

# WPFTweaksDeliveryOptimization
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization -Name DODownloadMode -Value 0

# WPFTweaksEndTaskOnTaskbar
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings -Name TaskbarEndTask -Value 1

# WPFTweaksDisableStoreSearch
icacls $Env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db /deny Everyone:F

# WPFTweaksRevertStartMenu
Set-ItemProperty -Path HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\3036241548 -Name EnabledState -Value 1

# WPFTweaksWidget
Get-Process *Widget* | Stop-Process
Get-AppxPackage Microsoft.WidgetsPlatformRuntime | Remove-AppxPackage -AllUsers
Get-AppxPackage MicrosoftWindows.Client.WebExperience | Remove-AppxPackage -AllUsers

# WPFTweaksWindowsAI
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name SettingsPageVisibility -Value hide:aicomponents
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\WindowsNotepad -Name DisableAIFeatures -Value 1

$Appx = Get-AppxPackage MicrosoftWindows.Client.CoreAI
$Sid = (Get-LocalUser $Env:UserName).Sid.Value
New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$Sid\$Appx" -Force

Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers
Remove-AppxPackage $Appx

Set-Service -Name WSAIFabricSvc -StartupType Disabled
Disable-WindowsOptionalFeature -FeatureName Recall -Online -NoRestart

# WPFTweaksRightClickMenu
New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name InprocServer32 -Value "" -Force

# Ensure onedrive will be removed
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name RemoveOneDrive -Value "$Env:SystemRoot\System32\OneDriveSetup.exe /uninstall"

# Clear out the taskbar
$ClearTaskbar = "powershell -Command Remove-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband -Recurse;Stop-Process -Name explorer"
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name ClearTaskbar -Value $ClearTaskbar

# Disables the task view button on the taskbar
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0

# Shows .extensions in explorer
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# Changes the default launch location in explorer to this pc
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

# Sets the taskbar to be left aligned
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0

# Disables the search box on the taskbar
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

# Sets the current wallpaper into the default dark mode one
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $Env:SystemRoot\Web\Wallpaper\Windows\img19.jpg

# Enables dark mode in apps and system
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0

# Disable recommended section in the start menu
New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education -Name IsEducationEnvironment -Value 1

New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Name HideRecommendedSection -Value 1

New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start -Name HideRecommendedSection -Value 1

# Run WinUtil Security Updates
New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Force

Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name ExcludeWUDriversInQualityUpdate -Value 1

Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name BranchReadinessLevel -Value 20
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name DeferFeatureUpdatesPeriodInDays -Value 365
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name DeferQualityUpdatesPeriodInDays -Value 4

# Reenable updates
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv -Name ImagePath -Value "$Env:SystemRoot\System32\svchost.exe -k netsvcs -p"

# Clear out the start menu
Invoke-WebRequest -Uri https://github.com/Raphire/Win11Debloat/raw/master/Assets/Start/start2.bin -OutFile $Env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin

# Removed edge icon from the desktop
Remove-Item -Path "$Env:Public\Desktop\Microsoft Edge.lnk"

# Removed Windows.old if it's empty
if (-not (Get-ChildItem -Path $Env:SystemDrive\Windows.old -ErrorAction SilentlyContinue)) {
  Remove-Item -Path $Env:SystemDrive\Windows.old
}

Restart-Computer
