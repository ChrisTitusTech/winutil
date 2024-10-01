# Walkthrough

## Install
---

=== "Installation & Updates"

    * Choose the programs you want to install or upgrade.
        * For programs not currently installed, this action will install them.
        * For programs already installed, this action will update them to the latest version.
    * Click the `Install/Upgrade Selected` button to start the installation or upgrade process.

=== "Upgrade All"

    * Simply press the `Upgrade All` button.
    * This will upgrade all applicable programs that are installed without the need for individual selection.

=== "Uninstall"

    * Select the programs you wish to uninstall.
    * Click the `Uninstall Selected` button to remove the selected programs.

=== "Get Installed"

    * Click the `Get Installed` button.
    * This will scan for and select all installed programs in WinUtil that WinGet supports.

=== "Clear Selection"
    * Click the `Clear Selection` button.
    * This will unselect all checked programs.

=== "prefer Chocolatey"
    * Check the `prefer Chocolatey` checkbox
    * By default Winutil will use winget to install/upgrade/remove packages and fallback to Chocolatey. This option reverses the preference.
    * This preference will be used for all Buttons on the Install page and persist across Winutil restarts

![Install Image](assets/Install-Tab-Dark.png#only-dark#gh-dark-mode-only)
![Install Image](assets/Install-Tab-Light.png#only-light#gh-light-mode-only)

!!! tip

     If you have trouble finding an application, press `ctrl + f` and search the name of it. Applications will filter depending on your input.

## Tweaks
---

![Tweaks Image](assets/Tweaks-Tab-Dark.png#only-dark#gh-dark-mode-only)
![Tweaks Image](assets/Tweaks-Tab-Light.png#only-light#gh-light-mode-only)

### Run Tweaks
* **Open Tweaks Tab**: Navigate to the 'Tweaks' tab in the application.
* **Select Tweaks**: Choose the tweaks you want to apply. You can use the presets available at the top for convenience.
* **Run Tweaks**: After selecting the desired tweaks, click the 'Run Tweaks' button at the bottom of the screen.

### Undo Tweaks
* **Open Tweaks Tab**: Go to the 'Tweaks' tab located next to 'Install'.
* **Select Tweaks to Remove**: Choose the tweaks you want to disable or remove.
* **Undo Tweaks**: Click the 'Undo Selected Tweaks' button at the bottom of the screen to apply the changes.

### Essential Tweaks
Essential Tweaks are modifications and optimizations that are generally safe for most users to implement. These tweaks are designed to enhance system performance, improve privacy, and reduce unnecessary system activities. They are considered low-risk and are recommended for users who want to ensure their system runs smoothly and efficiently without delving too deeply into complex configurations. The goal of Essential Tweaks is to provide noticeable improvements with minimal risk, making them suitable for a wide range of users, including those who may not have advanced technical knowledge.

### Advanced Tweaks - CAUTION
Advanced Tweaks are intended for experienced users who have a solid understanding of their system and the potential implications of making deep-level changes. These tweaks involve more significant alterations to the operating system and can provide substantial customization. However, they also carry a higher risk of causing system instability or unintended side effects if not implemented correctly. Users who choose to apply Advanced Tweaks should proceed with caution, ensuring they have adequate knowledge and backups in place to recover if something goes wrong. These tweaks are not recommended for novice users or those unfamiliar with the inner workings of their operating system.

### O&O Shutup


[O&O ShutUp10++](https://www.oo-software.com/en/shutup10) can be launched from WinUtil with only one button click. It is a free privacy tool for Windows that lets users easily manage their privacy settings. It disables telemetry, controls updates, and manages app permissions to enhance security and privacy. The tool offers recommended settings for optimal privacy with just a few clicks.

<iframe width="640" height="360" src="https://www.youtube.com/embed/3HvNr8eMcv0" title="O&O ShutUp10++: For Windows 10 & 11, with Dark Mode" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>


### DNS

The utility provides a convenient DNS selection feature, allowing users to choose between various DNS providers for both IPv4 and IPv6. This enables users to optimize their internet connection for speed, security, and privacy according to their specific needs. Here are the available options:

* **Default**: Uses the default DNS settings configured by your ISP or network.
* **DHCP**: Automatically acquires DNS settings from the DHCP server.
* [**Google**](https://developers.google.com/speed/public-dns?hl=de): A reliable and fast DNS service provided by Google.
* [**Cloudflare**](https://developers.cloudflare.com/1.1.1.1/): Known for speed and privacy, Cloudflare DNS is a popular choice for enhancing internet performance.
* [**Cloudflare_Malware**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malicious%20content%3A): Provides additional protection by blocking malware sites.
* [**Cloudflare_Malware_Adult**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malware%20and%20adult%20content%3A): Blocks both malware and adult content, offering more comprehensive filtering.
* [**Level3**](https://www.lumen.com/): Another fast and reliable DNS service option.
* [**Open_DNS**](https://www.opendns.com/setupguide/#familyshield): Offers customizable filtering and enhanced security features.
* [**Quad9**](https://quad9.net/): Focuses on security by blocking known malicious domains.

### Customize Preferences

The Customize Preferences section allows users to personalize their Windows experience by toggling various visual and functional features. These preferences are designed to enhance usability and tailor the system to the user’s specific needs and preferences.

### Performance Plans

The Performance Plans section allows users to manage the Ultimate Performance Profile on their system. This feature is designed to optimize the system for maximum performance.

#### Add and activate the Ultimate Performance Profile:
* Enables and activates the Ultimate Performance Profile to enhance system performance by minimizing latency and increasing efficiency.
#### Remove Ultimate Performance Profile:
* Deactivates the Ultimate Performance Profile, changing the system to the Balanced Profile.

### Shortcuts

The utility includes a feature to easily create a desktop shortcut, providing quick access to the script.

## Config
---

### Features
* Install the most used **Windows Features** by checking the checkbox and clicking "Install Features" to install them.

* All .Net Frameworks (2, 3, 4)
* HyperV Virtualization
* Legacy Media (WMP, DirectPlay)
* NFS - Network File System
* Enable Search Box Web Suggestions in Registry (explorer restart)
* Disables Search Box Web Suggestions in Registry (explorer restart)
* Enable Daily Registry Backup Task 12:30am
* Enable Legacy F8 Boot Recovery
* Disable Legacy F8 Boot Recovery
* Windows Subsystem for Linux
* Windows Sandbox

### Fixes
* Quick fixes for your system if you are having issues.

* Set Up Autologin
* Reset Windows Update
* Reset Network
* System Corruption Scan
* WinGet Reinstall
* Remove Adobe Creative Cloud

### Legacy Windows Panels

Open old-school Windows panels directly from WinUtil. Following Panels are available:

* Control Panel
* Network Connections
* Power Panel
* Region
* Sound Settings
* System Properties
* User Accounts

### Remote Access

Enables OpenSSH server on your windows machine.

## Updates
---

The utility provides three distinct settings for managing Windows updates: Default (Out of Box) Settings, Security (Recommended) Settings, and Disable ALL Updates (NOT RECOMMENDED!). Each setting offers a different approach to handling updates, catering to various user needs and preferences.

### Default (Out of Box) Settings
- **Description**: This setting retains the default configurations that come with Windows, ensuring no modifications are made.
- **Functionality**: It will remove any custom Windows update settings previously applied.
- **Note**: If update errors persist, reset all updates in the configuration tab to restore all Microsoft Update Services to their default settings, reinstalling them from their servers.

### Security (Recommended) Settings
- **Description**: This is the recommended setting for all computers.
- **Update Schedule**:
    - **Feature Updates**: Delays feature updates by 2 years to avoid potential bugs and instability.
    - **Security Updates**: Installs security updates 4 days after their release to ensure system protection against pressing security flaws.
- **Rationale**:
    - **Feature Updates**: Often introduce new features and bugs; delaying these updates minimizes the risk of system disruptions.
    - **Security Updates**: Essential for patching critical security vulnerabilities. Delaying them by a few days allows for verification of stability and compatibility without leaving the system exposed for extended periods.

### Disable ALL Updates (NOT RECOMMENDED!)
- **Description**: This setting completely disables all Windows updates.
- **Suitability**: May be appropriate for systems used for specific purposes that do not require active internet browsing.
- **Warning**: Disabling updates significantly increases the risk of the system being hacked or infected due to the lack of security patches.
- **Note**: It is strongly advised against using this setting due to the heightened security risks.

!!! bug

     The Updates tab is currently non-functional. We are actively working on a resolution to restore its functionality.

## MicroWin
---

* **MicroWin** lets you customize your Windows 10 and 11 installation images by debloating them however you want.

![Microwin](assets/Microwin-Dark.png#only-dark#gh-dark-mode-only)
![Microwin](assets/Microwin-Light.png#only-light#gh-light-mode-only)

#### Basic usage

1. Specify the source Windows ISO to customize.

    * If you don't have a Windows ISO file prepared, you can download it using the Media Creation Tool for the respective Windows version. [Here](https://go.microsoft.com/fwlink/?linkid=2156295) is the Windows 11 version, and [here](https://go.microsoft.com/fwlink/?LinkId=2265055) is the Windows 10 version

2. Configure the debloat process.
3. Specify the target location for the new ISO file.
4. Let the magic happen!

!!! warning "Heads-up"

     This feature is still in development, and you may encounter some issues with the generated images. If that happens, don't hesitate to report an issue!

#### Options

* **Download oscdimg.exe from the CTT GitHub repo** will grab an OSCDIMG executable from the GitHub repository instead of a Chocolatey package.

!!! info

     OSCDIMG is the tool that lets the program create ISO images. Typically, you would find this in the [Windows Assessment and Deployment Kit](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)

* Selecting a scratch directory will copy the contents of the ISO file to the directory you specify instead of an automatically generated folder in the `%TEMP%` directory.
* You can select an edition of Windows to debloat (**SKU**) using the convenient drop-down menu.

By default, MicroWin will debloat the Pro edition, but you can choose any edition you want.


##### Driver integration options

* **Inject drivers** will add the drivers in the folder that you specify to the target Windows image.
* **Import drivers from the current system** will add every third-party driver that is present in your active installation.

This makes the target image have the same hardware compatibility as the active installation. However, this means that you will only be able to install the target Windows image and take full advantage of it on computers with **the same hardware**. To avoid this, you'll need to customize the `install.wim` file of the target ISO in the 'sources` folder.

##### Custom user settings

With MicroWin, you can also configure your user before proceeding if you don't want to use the default `User` account. To do this, simply type the account name (20 characters maximum), and a password. Then, let MicroWin do the rest.

!!! info

     Please make sure that you remember your password. MicroWin will configure auto-login settings, so you won't have to enter your password. However, if you are required to enter your password, it's best that you don't forget it.


##### Ventoy options

* **Copy to Ventoy** will copy the target ISO file to any USB drive with [Ventoy](https://ventoy.net/en/index.html) installed
!!! info

     Ventoy is a solution that lets you boot to any ISO file stored on a drive. Think of it as having multiple bootable USBs in one. Do note, though, that your drive needs to have enough free space for the target ISO file.

## Automation

* Some features are available through automation. This allows you to save your config file, pass it to WinUtil, walk away and come back to a finished system. Here is how you can set it up currently with Winutil >24.01.15

* On the Install Tab, click "Get Installed", this will get all installed apps **supported by Winutil** on the system.
![GetInstalled](assets/Get-Installed-Dark.png#only-dark#gh-dark-mode-only)
![GetInstalled](assets/Get-Installed-Light.png#only-light#gh-light-mode-only)

* Click on the Settings cog in the upper right corner and choose Export. Choose file file and location; this will export the setting file.
![SettingsExport](assets/Settings-Export-Dark.png#only-dark#gh-dark-mode-only)
![SettingsExport](assets/Settings-Export-Light.png#only-light#gh-light-mode-only)

* Copy this file to a USB or somewhere you can use it after Windows installation.

!!! tip

     Use the Microwin tab to create a custom Windows image & install the Windows image.

* On any supported Windows machine, open PowerShell **as Admin** and run the following command to automatically apply tweaks and install apps from the config file.
    ```ps1
    iex "& { $(irm christitus.com/win) } -Config [path-to-your-config] -Run"
    ```
* Have a cup of coffee! Come back when it's done.
