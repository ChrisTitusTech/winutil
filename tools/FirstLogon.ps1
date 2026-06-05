# Run WinUtil Tweaks

& ([ScriptBlock]::Create((irm https://gist.github.com/GabiNun2/58ea0a785e407bbdf84503ac01efc6e1/raw/winutil.ps1))) -Preset Advanced

# Ensure msteams was removed
Get-AppxPackage -Name MSTeams | Remove-AppxPackage -AllUsers

# Run WinUtil Toggles

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
New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education | Out-Null
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education -Name IsEducationEnvironment -Value 1

New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer | Out-Null
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Name HideRecommendedSection -Value 1

New-Item -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start | Out-Null
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start -Name HideRecommendedSection -Value 1

# Run WinUtil Security Updates

New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Force | Out-Null

Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name ExcludeWUDriversInQualityUpdate -Value 1

Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name BranchReadinessLevel -Value 20
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name DeferFeatureUpdatesPeriodInDays -Value 365
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name DeferQualityUpdatesPeriodInDays -Value 4

# Reenable updates
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv -Name ImagePath -Value "$Env:SystemRoot\System32\svchost.exe -k netsvcs -p"

# Clear out the start menu
Invoke-WebRequest -Uri https://github.com/Raphire/Win11Debloat/raw/master/Assets/Start/start2.bin -OutFile $Env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin

Restart-Computer
