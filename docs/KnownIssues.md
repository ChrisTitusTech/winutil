### Launch Issues:

- Windows Security (formerly Defender) and other anti-virus software are known to block the script. The script gets flagged due to the fact that it requires administrator privileges & makes drastic system changes.
  - If possible: Allow script in Anti-Virus software settings.

- If you are having TLS 1.2 issues, or are having trouble resolving `christitus.com/win` then run with the following command:

```ps1
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1')
```

- If you are unable to resolve `christitus.com/win` and are getting  errors launching the tool, it might be due to India blocking GitHub's content domain and preventing downloads.
  - Source: <https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms>

If you are still having issues try using a **VPN**, or changing your **DNS provider** to one of following two providers:

|   Provider   | Primary DNS  | Secondary DNS |
|:------------:|:------------:|:-------------:|
| Cloudflare   | `1.1.1.1`    | `1.0.0.1`     |
| Google       | `8.8.8.8`    | `8.8.4.4`     |



- Script doesn't run/PowerShell crashes:
  1. Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11)
  2. Run:
  ```ps1
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```
  3. Run:
  ```ps1
  irm christitus.com/win | iex
  ```

### Other Issues:

- Windows taking longer to shut down:
  - [#69](https://github.com/ChrisTitusTech/winutil/issues/69) Turn on fast startup: Press Windows key + R, then type:
  ```
  control /name Microsoft.PowerOptions /page pageGlobalSettings
  ```
  - If that doesn't work, Disable Hibernation: Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11) and enter:
  ```ps1
  powercfg /H off
  ```
- [#69](https://github.com/ChrisTitusTech/winutil/issues/69) [95](https://github.com/ChrisTitusTech/winutil/issues/95) [#232](https://github.com/ChrisTitusTech/winutil/issues/232) Windows Search does not work: Enable Background Apps
- [#198](https://github.com/ChrisTitusTech/winutil/issues/198) Xbox Game Bar Activation Broken: Set the Xbox Accessory Management Service to Automatic
```ps1
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```

- Winget requires interaction on first run: Manually type 'y' and 'enter' into the PowerShell console to continue
- (Windows 11) Quick Settings no longer works: Launch the Script and click 'Enable Action Center'

- Explorer no longer launches: Go to Control Panel, File Explorer Options, Change the 'Open File Explorer to' option to 'This PC'.

### Battery drains too fast.
* When your battery on the laptop drains too fast, please perform these steps and report the results back to the Winutil community.

1. **Check Battery Health:**
   - Open a Command Prompt as an administrator.
   - Run the following command to generate a battery report:
     ```powershell
     powercfg /batteryreport /output "C:\battery_report.html"
     ```
   - Open the generated HTML report to review information about battery health and usage.

2. **Review Power Settings:**
   - Go to "Settings" > "System" > "Power & sleep."
   - Adjust power plan settings based on your preferences and usage patterns.
   - Click on "Additional power settings" to access advanced power settings.

3. **Identify Power-Hungry Apps:**
   - Right-click on the taskbar and select "Task Manager."
   - Navigate to the "Processes" tab to identify applications with high CPU or memory usage.
   - Consider closing unnecessary background applications.

4. **Update Drivers:**
   - Visit your laptop manufacturer's website or use Windows Update to check for driver updates.
   - Ensure graphics, chipset, and other essential drivers are up to date.

5. **Check for Windows Updates:**
   - Go to "Settings" > "Update & Security" > "Windows Update."
   - Check for and install any available updates for your operating system.

6. **Reduce Screen Brightness:**
   - Adjust screen brightness based on your preferences and lighting conditions.
   - Go to "Settings" > "System" > "Display" to adjust brightness.

7. **Battery Saver Mode:**
   - Go to "Settings" > "System" > "Battery."
   - Turn on "Battery saver" to limit background activity and conserve power.

8. **Check Power Usage in Settings:**
   - Go to "Settings" > "System" > "Battery" > "Battery usage by app."
   - Review the list of apps and their power usage.

9. **Check Background Apps:**
   - Go to "Settings" > "Privacy" > "Background apps."
   - Disable unnecessary apps running in the background.

10. **Use Powercfg for Analysis:**
    - Open a Command Prompt as an administrator.
    - Run the following command to analyze energy usage and generate a report:
      ```powershell
      powercfg /energy /output "C:\energy_report.html"
      ```
    - Open the generated HTML report to identify energy consumption patterns.

11. **Review Event Viewer:**
    - Open Event Viewer by searching for it in the Start menu.
    - Navigate to "Windows Logs" > "System."
    - Look for events with the source "Power-Troubleshooter" to identify power-related events.

12. **Check Wake-up Sources:**
    - Open a Command Prompt as an administrator.
    - Use the command `powercfg /requests` to identify processes preventing sleep.
    - Check Task Scheduler for tasks waking up the computer.
    - Use the command `powercfg /waketimers` to view active wake timers.

13. **Resource Monitor:**
    - Open Resource Monitor from the Start menu.
    - Navigate to the "CPU" tab and identify processes with high CPU usage.

14. **Windows Settings - Activity History:**
    - In "Settings," go to "Privacy" > "Activity history."
    - Turn off "Let Windows collect my activities from this PC."

15. **Network Adapters:**
    - Open Device Manager by searching for it in the Start menu.
    - Locate your network adapter, right-click, and go to "Properties."
    - Under the "Power Management" tab, uncheck the option that allows the device to wake the computer.

16. **Review Installed Applications:**
    - Manually review installed applications by searching for "Add or remove programs" in the Start menu.
    - Check settings/preferences of individual applications for power-related options.
    - Uninstall unnecessary or problematic software.

* By following these detailed instructions, you should be able to thoroughly diagnose and address battery drain issues on your Windows laptop. Adjust settings as needed to optimize power management and improve battery life.

### Troubleshoot errors during Microwin usage

#### Error `0x80041031`

* This error code typically indicates an issue related to Windows Management Instrumentation (WMI). Here are a few steps you can try to resolve the issue:

1. **Reboot Your Computer:**
   Sometimes, a simple reboot can resolve temporary issues. Restart your computer and try mounting the ISO again.

2. **Check for System Corruption:**
   Run the System File Checker (SFC) utility to scan and repair system files that may be corrupted.
   ```powershell
   sfc /scannow
   ```

3. **Update Your System:**
   Make sure your operating system is up-to-date. Check for Windows updates and install any pending updates.

4. **Check WMI Service:**
   Ensure that the Windows Management Instrumentation (WMI) service is running. You can do this through the Services application:
   - Press `Win + R` to open the Run dialog.
   - Type `services.msc` and press Enter.
   - Locate "Windows Management Instrumentation" in the list.
   - Make sure to set its status to "Running" and the startup type to "Automatic."

5. **Check for Security Software Interference:**
   Security software can sometimes interfere with WMI operations. Temporarily disable your antivirus or security software and check if the issue persists.

6. **Event Viewer:**
   Check the Event Viewer for more detailed error information. Look for entries related to the `80041031` error and check if there are any additional details that can help identify the cause.

   - Press `Win + X` and select "Event Viewer."
   - Navigate to "Windows Logs" -> "Application" or "System."
   - Look for entries with the source related to WMI or the application use to mount the ISO.

7. **ISO File Integrity:**
   Ensure that the ISO file you are trying to mount is uncorrupted. Try mounting a different ISO file to see if the issue persists.

* If the problem persists after trying these steps, additional troubleshooting is required. Consider seeking assistance from Microsoft support or community forums for more specific guidance based on your system configuration and the software you use to mount the ISO.
