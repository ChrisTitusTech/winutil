## Known Issues and Fixes
- Windows taking longer to shut down:
  - [#69](https://github.com/ChrisTitusTech/winutil/issues/69) Turn on fast startup: Press Windows key + R, then type:
  ```
  control /name Microsoft.PowerOptions /page pageGlobalSettings
  ```
  - If that doesn't work, Disable Hibernation: Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11) and enter:
  ```
  powercfg /H off
  ```
- [#69](https://github.com/ChrisTitusTech/winutil/issues/69) [95](https://github.com/ChrisTitusTech/winutil/issues/95) [#232](https://github.com/ChrisTitusTech/winutil/issues/232) Windows Search does not work: Enable Background Apps
- [#198](https://github.com/ChrisTitusTech/winutil/issues/198) Xbox Game Bar Activation Broken: Set the Xbox Accessory Management Service to Automatic
```
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```
- Windows Insider Builds not installing: Telemetry needs to be enabled
```
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
 ```
- Winget requires interaction on first run: Manually type 'y' and 'enter' into the PowerShell console to continue
- (Windows 11) Quick Settings no longer works: Launch the Script and click 'Enable Action Center'
- Explorer no longer launches: Go to Control Panel, File Explorer Options, Change the 'Open File Explorer to' option to 'This PC'.
- Script doesn't run/PowerShell crashes:
  1. Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11)
  2. Run:
  ```
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```
  3. Run:
  ```
  irm christitus.com/win | iex
  ```