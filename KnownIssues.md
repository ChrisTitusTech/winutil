## Known Issues and Fixes
- [#333](https://github.com/ChrisTitusTech/win10script/issues/333) Windows taking longer to shut down:
  - Turn on fast startup: Press Windows key + R, then type:
  ```
  control /name Microsoft.PowerOptions /page pageGlobalSettings
  ```
  - If that doesn't work, Disable Hibernation: Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11) and enter:
  ```
  powercfg /H off
  ```
- [#253](https://github.com/ChrisTitusTech/win10script/issues/253) Windows Search does not work: Enable Background Apps
- [#278](https://github.com/ChrisTitusTech/win10script/issues/278) Xbox Game Bar Activation Broken: Set the Xbox Accessory Management Service to Automatic
```
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```
- [#250](https://github.com/ChrisTitusTech/win10script/issues/250) Windows Insider Builds not installing: Telemetry needs to be enabled
```
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
 ```
- [#245](https://github.com/ChrisTitusTech/win10script/issues/245) winget requires interaction on first run: Manually type 'y' and 'enter' into the PowerShell console to continue
- [#237](https://github.com/ChrisTitusTech/win10script/issues/237) (Windows 11) Quick Settings no longer works: Launch the Script and click 'Enable Action Center'
- [#214](https://github.com/ChrisTitusTech/win10script/issues/214) [#165](https://github.com/ChrisTitusTech/win10script/issues/165) [#150](https://github.com/ChrisTitusTech/win10script/issues/150) Explorer no longer launches: Go to Control Panel, File Explorer Options, Change the 'Open File Explorer to' option to 'This PC'.
- [#199](https://github.com/ChrisTitusTech/win10script/issues/199) [#216](https://github.com/ChrisTitusTech/win10script/issues/216) [#233](https://github.com/ChrisTitusTech/win10script/issues/233) [#242](https://github.com/ChrisTitusTech/win10script/issues/242) [#208](https://github.com/ChrisTitusTech/win10script/issues/208) Script doesn't run/PowerShell crashes:
  1. Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11)
  2. Run:
  ```
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```
  3. Run:
  ```
  irm christitus.com/win | iex
  ```