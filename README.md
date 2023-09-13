# Chris Titus Tech's Windows Utility

This Utility is a compilation of Windows tasks I perform on each Windows system I use. It is meant to streamline *installs*, debloat with *tweaks*, troubleshoot with *config*, and fix Windows *updates*. I am extremely picky about any contributions to keep this project clean and efficient. 

![screen-install](screen-install.png)

## Usage:

Requires you to launch PowerShell or Windows Terminal As **ADMINISTRATOR!** 
The recommended way is to right-click on the start menu and select (PowerShell As Admin *Windows 10* - Windows Terminal As Admin *Windows 11*)

Launch Command:

```
iwr -useb https://christitus.com/win | iex
```
Or shorter Thanks to [#144](/../../issues/144)
```
irm https://christitus.com/win | iex
```
### Issues:

- If you can't resolve christitus.com/win and getting errors launching India Region is BLOCKING raw github files and you need to VPN outside India. 

Source: <https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms>

- AntiVirus is also blocking the script. You can disable it temporarily to run the script. The script is flagged for malware because it runs under the administrator and makes system changes.

- If you are having TLS 1.2 Issues or You cannot find or resolve `christitus.com/win` then run with the following command:

```
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1')
```

If you are still having issues try changing your DNS provider to 1.1.1.1 or 8.8.8.8

## Support
- This project needs a ⭐️ from you. Don't forget to leave a star ⭐️.
- EXE Wrapper for $10 @ https://www.cttstore.com/windows-toolbox

## Tutorial

[![Watch the video](https://img.youtube.com/vi/6UQZ5oQg8XA/hqdefault.jpg)](https://www.youtube.com/watch?v=6UQZ5oQg8XA)

## Overview

- Install
  - Install Selection: Organize programs by category and facilitate installation by enabling users to select programs and initiate the installation process with a single click.
  
  - Upgrade All: Upgrade all existing programs to their latest versions, ensuring users have the most up-to-date and feature-rich software. 
  
  - Uninstall Selection: Effortlessly uninstall selected programs, providing users with a streamlined way to remove unwanted software from their system.
  
  - Get Installed: Retrieve a comprehensive list of installed programs on the system, offering users visibility into the software currently installed on their computer.
  
  - Import / Export: Enable users to import or export the selection list of programs, allowing them to save their preferred program configurations or share them with others. This feature promotes convenience and flexibility in managing program selections across different systems.
 
- Tweaks
  - Recommended Selection: Provides pre-defined templates tailored for desktop, laptop, and minimal configurations, allowing users to select recommended settings and optimizations specific to their system type.

  - Essential Tweaks: Offers a collection of essential tweaks aimed at improving system performance, privacy, and resource utilization. These tweaks include creating a system restore point, disabling telemetry, Wi-Fi Sense, setting services to manual, disabling location tracking, and HomeGroup, among others.

  - Misc. Tweaks: Encompasses a range of various tweaks to further optimize the system. These tweaks include enabling/disabling power throttling, enabling num lock on startup, removing Cortana and Edge, disabling User Account Control (UAC), notification panel, and configuring TPM during updates, among others.

  - Additional Tweaks: Introduces various other tweaks such as enabling dark mode, changing DNS settings, adding an Ultimate Performance mode, and creating shortcuts for WinUtil tools. These tweaks provide users with additional customization options to tailor their system to their preferences.

- Config
  - Features: Allows users to easily install various essential components and features to enhance their Windows experience. These features include installing .NET Frameworks, enabling Hyper-V virtualization, enabling legacy media support for Windows Media Player and DirectPlay, enabling NFS (Network File System) for network file sharing, and enabling Windows Subsystem for Linux (WSL) for running Linux applications on Windows.

  - Fixes: Provides a range of helpful fixes to address common issues and improve system stability. This includes setting up autologon for seamless login experiences, resetting Windows updates to resolve update-related problems, performing a system corruption scan to detect and repair corrupted files, and resetting network settings to troubleshoot network connectivity issues.

  - Legacy Windows Panels: Includes access to legacy Windows panels from Windows 7, allowing users to access familiar and powerful tools. These panels include Control Panel for managing system settings, Network Connections for configuring network adapters and connections, Power Panel for adjusting power and sleep settings, Sound Settings for managing audio devices and settings, System Properties for viewing and modifying system information, and User Accounts for managing user profiles and account settings.


- Updates:
  - Default (Out of Box) Settings: Provides the default settings that come with Windows for updates.
  
  - Security (Recommended) Settings: Offers recommended settings, including a slight delay of feature updates by 2 years and installation of security updates 4 days after release.

  - Disable All Updates (Not Recommended!): Allows users to disable all Windows updates, but it's not recommended due to potential security risks.


Video and Written Article walkthrough @ <https://christitus.com/windows-tool/>

## Issues

If you encounter any challenges or problems with the script, I kindly request that you submit them via the "Issues" tab on the GitHub repository. By filling out the provided template, you can provide specific details about the issue, allowing me to promptly address any bugs or consider feature requests.

## Contribute Code

To contribute a new code, please ensure that it is submitted to the **TEST BRANCH**. Please note that merges will not be performed directly on the MAIN branch.

When creating pull requests, it is essential to thoroughly document all changes made. This includes documenting any additions made to the tweaks section and ensuring that corresponding undo measures are in place to remove the newly added tweaks if necessary. Failure to adhere to this format may result in denial of the pull request. Additionally, comprehensive documentation is required for all code changes. Any code lacking sufficient documentation may also be denied.

By following these guidelines, we can maintain a high standard of quality and ensure that the codebase remains organized and well-documented.

## Thanks to all Contributors
Thanks a lot for spending your time helping Winutil grow. Thanks a lot! Keep rocking 🍻.

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/winutil)](https://github.com/ChrisTitusTech/winutil/graphs/contributors)

