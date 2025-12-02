---
title: Automation
weight: 7
---

* Some features are available through automation. This allows you to save your config file, pass it to Winutil, walk away and come back to a finished system. Here is how you can set it up currently with Winutil >24.01.15

* On the Install Tab, click "Get Installed", this will get all installed apps **supported by Winutil** on the system.
{{< image src="images/Get-Installed" alt="GetInstalled" >}}

* Click on the Settings cog in the upper right corner and choose Export. Choose file file and location; this will export the setting file.
{{< image src="images/Settings-Export" alt="SettingsExport" >}}

* Copy this file to a USB or somewhere you can use it after Windows installation.

> [!TIP]
> Use the Microwin tab to create a custom Windows image & install the Windows image.

* On any supported Windows machine, open PowerShell **as Admin** and run the following command to automatically apply tweaks and install apps from the config file.
    ```
    iex "& { $(irm https://christitus.com/win) } -Config [path-to-your-config] -Run"
    ```
* Have a cup of coffee! Come back when it's done.
