---
title: Known Issues
toc: true
---

### Download not working

If `https://christitus.com/win` is not working, or you want to download the code from GitHub directly, you can use the direct download link:

```
irm https://github.com/ChrisTitusTech/Winutil/releases/latest/download/Winutil.ps1 | iex
```

If you are seeing errors referencing TLS or security, you may be running an older version of Windows where TLS 1.2 is not the default security protocol used for network connections. The following commands will force .NET to use TLS 1.2, and download the script directly using .NET instead of PowerShell:

```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex https://christitus.com/win | iex
```

If it still isn't working and you live in India, it might be due to India blocking GitHub's content domain and preventing downloads. See more on [Times of India](https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms).

If you are still having issues, try using a **VPN**, or changing your **DNS provider** to one of following two providers:

|  Provider  | Primary DNS | Secondary DNS |
| :--------: | :---------: | :-----------: |
| Cloudflare |  `1.1.1.1`  |   `1.0.0.1`   |
|   Google   |  `8.8.8.8`  |   `8.8.4.4`   |

### Script Won't Run

If your PowerShell session is running in **Constrained Language Mode**, some scripts and commands may fail to execute. To check the current language mode, run:
```powershell
$ExecutionContext.SessionState.LanguageMode
```
If it returns `ConstrainedLanguage`, you may need to switch to `FullLanguage` mode or run the script in a session with administrative privileges. Be aware that some security policies may enforce Constrained Language Mode, especially in corporate or managed environments.

### Script blocked by Execution Policy

1. Ensure you are running PowerShell as admin: Press `Windows Key`+`X` and select _PowerShell (Admin)_ in Windows 10, or `Windows Terminal (Admin)` in Windows 11.
2. In the PowerShell window, type this to allow unsigned code to execute and run the installation script:

   ```
   Set-ExecutionPolicy Unrestricted -Scope Process -Force
   irm https://christitus.com/win | iex
   ```

## Runtime Issues

### WinGet configuration

If you have not installed anything using PowerShell before, you may be prompted to configure WinGet. This requires user interaction on first run. You will need to manually type `y` into the PowerShell console and press enter to continue. Once you do it the first time, you will not be prompted again.

## Windows Issues

### Windows takes longer to shut down

This could be for a number of reasons:

- Turn on fast startup: Press `Windows key`+`R`, then type:

  ```bat
  control /name Microsoft.PowerOptions /page pageGlobalSettings
  ```

If that doesn't work, disable Hibernation:

- Press `Windows Key`+`X` and select _PowerShell (Admin)_ in Windows 10, or `Windows Terminal (Admin)` in Windows 11. then type:

  ```bat
  powercfg /H off
  ```

Related issue: [#69](https://github.com/ChrisTitusTech/Winutil/issues/69)

### Windows Search does not work

Enable Background Apps. Related issues: [#69](https://github.com/ChrisTitusTech/Winutil/issues/69) [#95](https://github.com/ChrisTitusTech/Winutil/issues/95) [#232](https://github.com/ChrisTitusTech/Winutil/issues/232)

### Xbox Game Bar Activation Broken

Set the Xbox Accessory Management Service to Automatic:

```powershell
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```

Related issue: [#198](https://github.com/ChrisTitusTech/Winutil/issues/198)

### Windows 11: Quick Settings no longer works

Launch the Script and click _Enable Action Center_.

### Explorer (file browser) no longer launches

- Press `Windows key`+`R` then type:

  ```bat
  control /name Microsoft.FolderOptions
  ```

- Change the _Open File Explorer to_ option to _This PC_.

### Battery drains too fast

If you're using a laptop or tablet and find your battery drains too fast, please try the below troubleshooting steps, and report the results back to the Winutil community.

1. **Check Battery Health:**
   - Press `Windows Key`+`X` and select _PowerShell (Admin)_ in Windows 10, or `Windows Terminal (Admin)` in Windows 11.
   - Run the following command to generate a battery report:
     ```powershell
     powercfg /batteryreport /output "C:\battery_report.html"
     ```
   - Open the generated HTML report to review information about battery health and usage. A battery with poor health may hold less charge, discharge faster, or cause other issues.

2. **Review Power Settings:**
   - Open the Settings app, and go to _System_ > _Power & sleep_.
   - Adjust power plan settings based on your preferences and usage patterns.
   - Click on _Additional power settings_ to access advanced power settings that may help.

3. **Identify Power-Hungry Apps:**
   - Right-click on the taskbar and select _Task Manager_.
   - Navigate to the _Processes_ tab to identify applications with high CPU or memory usage.
   - Consider reconfiguring, closing, disabling, or uninstalling applications that use a lot of resources.

4. **Update Drivers:**
   - Visit your device manufacturer's website or use Windows Update to check for driver updates.
   - Ensure graphics, chipset, and other essential drivers are up to date.

5. **Check for Windows Updates:**
   - Open the Settings app, and go to _Update & Security_ > _Windows Update_.
   - Check for and install any available updates for your operating system.

6. **Reduce Screen Brightness:**
   - Open the Settings app, and go to _System_ > _Display_.
   - Adjust screen brightness based on your preferences and lighting conditions.

7. **Enable Battery Saver:**
   - Open the Settings app, and go to _System_ > _Battery_.
   - Turn on _Battery saver_ to limit background activity and conserve power.

8. **Check Power Usage in Settings:**
   - Open the Settings app, and go to _System_ > _Battery_ > _Battery usage by app_.
   - Review the list of apps and their power usage. Disable or uninstall any you don't need.

9. **Check Background Apps:**
   - Open the Settings app, and go to _Privacy_ > _Background apps_.
   - Disable or uninstall unnecessary apps running in the background.

10. **Use `powercfg` for Analysis:**
    - Press `Windows Key`+`X` and select _PowerShell (Admin)_ in Windows 10, or `Windows Terminal (Admin)` in Windows 11.
    - Run the following command to analyze energy usage and generate a report:
      ```powershell
      powercfg /energy /output "C:\energy_report.html"
      ```
    - Open the generated HTML report to identify energy consumption patterns.

11. **Review Event Logs:**
    - Open Event Viewer by searching for it in the Start menu.
    - Navigate to _Windows Logs_ > _System_.
    - Look for events with the source _Power-Troubleshooter_ to identify power-related events. These may highlight battery, input power, and other issues.

12. **Check Wake-up Sources:**
    - Press `Windows Key`+`X` and select _PowerShell (Admin)_ in Windows 10, or `Windows Terminal (Admin)` in Windows 11.
    - Use the command `powercfg /requests` to identify processes preventing sleep.
    - Use the command `powercfg /waketimers` to view active wake timers.
    - Check Task Scheduler to see if any of the discovered processes are scheduled to start on boot or at regular intervals.

13. **Advanced Identification of Power-Hungry Apps:**
    - Open Resource Monitor from the Start menu.
    - Navigate to the _CPU_, _Memory_, _Network_, and other tabs to identify processes with high resource usage.
    - Consider reconfiguring, closing, disabling, or uninstalling applications that use a lot of resources.

14. **Disable Activity History:**
    - Open the Settings app, and go to _Privacy_ > _Activity history_.
    - Turn off _Let Windows collect my activities from this PC_.

15. **Prevent Network Adapters From Waking PC:**
    - Open Device Manager by searching for it in the Start menu.
    - Locate your network adapter, right-click, and go to _Properties_.
    - Under the _Power Management_ tab, uncheck the option that allows the device to wake the computer.

16. **Review Installed Applications:**
    - Manually review installed applications by searching for _Add or remove programs_ in the Start menu.
    - Check settings/preferences of individual applications for power-related options.
    - Uninstall unnecessary or problematic software.

These troubleshooting steps are generic, but should help in most situations. You should have these key takeaways:

- Battery health is the most significant limiter on your device's runtime. A battery in poor health usually cannot be made to last like it used to, simply by closing some applications. Consider replacing your battery.
- Background applications that use CPU and memory, make lots of or large network requests, read/write to disk frequently, or that keep your PC awake when it could be conserving energy are the next major concern. Avoid installing programs you don't need, only use programs you trust, and configure applications to use as little power and run as infrequently as possible.
- Windows performs a lot of tasks that may affect battery life by default. Changing settings, stopping scheduled tasks, and disabling features can help the system stay in lower power states to conserve battery.
- Bad chargers, inconsistent power input, and high temperatures will cause batteries to degrade and discharge faster. Use trusted high-quality chargers, ensure input power is steady, clean any fans or airflow ports, and keep the battery/PC cool.
