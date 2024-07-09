#### Automation

Some features are available through automation. This allows you to save your config file pass it to Winutil walk away and come back to a finished system. Here is how you can set it up currently with Winutil >24.01.15

1. On the Install Tab, click "Get Installed", this will get all installed apps **supported by Winutil** on the system
  ![GetInstalled](/wiki/Get-Installed.png)
2. Click on the Settings cog in the upper right corner and chose Export, chose file file and location, this will export the setting file.
  ![SettingsExport](/wiki/Settings-Export.png)
3. Copy this file to a USB or somewhere you can use after Windows installation.
4. Use Microwin tab to create a custom Windows image.
5. Install the Windows image.
6. In the new Windows, Open PowerShell in the admin mode and run command to automatically apply tweaks and install apps from the config file.
```ps1
iex "& { $(irm christitus.com/win) } -Config [path-to-your-config] -Run"
```
7. Have a cup of coffee! Come back when it's done.