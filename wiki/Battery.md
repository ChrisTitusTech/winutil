# Battery drains too fast.
When your battery on teh laptop drains too fast please perform these steps and report the results back to Winutil community.

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

By following these detailed instructions, you should be able to thoroughly diagnose and address battery drain issues on your Windows laptop. Adjust settings as needed to optimize power management and improve battery life.