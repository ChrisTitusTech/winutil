# Run WinUtil Tweaks

@'
[
  "WPFTweaksActivity",
  "WPFTweaksConsumerFeatures",
  "WPFTweaksDisableExplorerAutoDiscovery",
  "WPFTweaksWPBT",
  "WPFTweaksLocation",
  "WPFTweaksServices",
  "WPFTweaksTelemetry",
  "WPFTweaksDeliveryOptimization",
  "WPFTweaksDeleteTempFiles",
  "WPFTweaksEndTaskOnTaskbar",
  "WPFTweaksDisableStoreSearch",
  "WPFTweaksRevertStartMenu",
  "WPFTweaksWidget",
  "WPFTweaksWindowsAI",
  "WPFTweaksRightClickMenu",
  "WPFAppxMicrosoft_WindowsFeedbackHub",
  "WPFAppxMicrosoft_ScreenSketch",
  "WPFAppxMicrosoft_Copilot",
  "WPFAppxMicrosoft_MicrosoftStickyNotes",
  "WPFAppxMicrosoft_WindowsSoundRecorder",
  "WPFAppxMicrosoft_MicrosoftOfficeHub",
  "WPFAppxMicrosoft_WindowsMaps",
  "WPFAppxMicrosoft_GetHelp",
  "WPFAppxMicrosoft_WindowsDevHome",
  "WPFAppxMicrosoft_MicrosoftSolitaireCollection",
  "WPFAppxMicrosoft_Todos",
  "WPFAppxClipchamp_Clipchamp",
  "WPFAppxMicrosoft_BingNews",
  "WPFAppxMicrosoftCorporationII_QuickAssist",
  "WPFAppxMicrosoft_PowerAutomateDesktop",
  "WPFAppxMicrosoft_BingWeather",
  "WPFAppxMicrosoft_BingSearch",
  "WPFAppxMicrosoft_WindowsAlarms",
  "WPFAppxMSTeams",
  "WPFAppxMicrosoft_OutlookForWindows"
]
'@ | Set-Content $Env:SystemRoot\Setup\config.json

& ([ScriptBlock]::Create((Invoke-RestMethod -Uri https://gist.github.com/GabiNun2/42a86e423c736478aa474081375c5109/raw/winutil.ps1))) -Config $Env:SystemRoot\Setup\config.json

# Hide 'Task view' button on the taskbar
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0

# Show file extensions for known file types
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# Change the default location that File Explorer opens to 'This PC'
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

# Align taskbar to the left
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0

# Hide search box on the taskbar
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

# Sets the current wallpaper into the default dark mode one
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $Env:SystemRoot\Web\Wallpaper\Windows\img19.jpg

# Enable dark theme for system and apps
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0

# Hide recommended section in the start menu
New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education -Force
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education -Name IsEducationEnvironment -Value 1

New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Force
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Name HideRecommendedSection -Value 1

New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start -Force
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

# Remove all pinned apps from the start menu
Invoke-WebRequest -Uri https://github.com/Raphire/Win11Debloat/raw/master/Assets/Start/start2.bin -OutFile $Env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin

# Removed edge icon from the desktop
Remove-Item -Path "$Env:Public\Desktop\Microsoft Edge.lnk"

# Removed onedrive startup entry
Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name OneDriveSetup

# Removed Windows.old if it's empty
if (-not (Get-ChildItem -Path $Env:SystemDrive\Windows.old -ErrorAction SilentlyContinue)) {
    Remove-Item -Path $Env:SystemDrive\Windows.old
}

Restart-Computer
