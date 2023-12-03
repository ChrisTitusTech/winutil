# Chris Titus Tech's Windows Utility

This utility is a compilation of Windows tasks I perform on each Windows system I use. It is meant to streamline *installs*, debloat with *tweaks*, troubleshoot with *config*, and fix Windows *updates*. I am extremely picky about any contributions to keep this project clean and efficient. 

![screen-install](screen-install.png)

## Usage:

Requires you to launch PowerShell or Windows Terminal As **ADMINISTRATOR!** 
The recommended way is to right-click on the start menu and select (PowerShell As Admin *Windows 10* - Windows Terminal As Admin *Windows 11*)

Launch Command:

```
iwr -useb https://christitus.com/win | iex
```
or by executing: 
```
irm https://christitus.com/win | iex
```
Courtesy of the issue raised at: [#144](/../../issues/144)

<details>
  <summary>Known issues</summary>

- If WINGET says "Program Installed" but it was not, there is a bug in new Windows versions where winget is installed by default, but NOT functional. Run the toolbox and click the "Winget Reinstall" Button.
  ![image](https://github.com/ChrisTitusTech/winutil/assets/7896101/f16b0f74-870d-4827-87e1-38ad119e6b3f)


- If you are unable to resolve https://christitus.com/win and are getting  errors launching the tool, it might be due to India blocking GitHub's content domain and preventing downloads. You'll be required to use a VPN to tunnel out of India.

Source: <https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms>

- Windows Security (formerly Defender) and other anti-virus software are known to block the script. The script gets flagged due to the fact that it requires administrator privileges & makes drastic system changes.

- If you are having TLS 1.2 issues, or are having trouble resolving `christitus.com/win` then run with the following command:

```PowerShell
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1')
```

If you are still having issues try changing your DNS provider to Cloudflare's:  <kbd>1.1.1.1</kbd> || <kbd>1.0.0.1</kbd> or Google's: <kbd>8.8.8.8</kbd> || <kbd>8.8.4.4</kbd>


### Running winutil offline (.ps1 file)

winutil features breaking with no internet connection:

* ``Install`` tab won't be able to download anything, same for the ``Config`` tab's "features" section.
* ADK and other dependencies for ``Microwin`` will not be able to be downloaded.

If running it remotely (in a `iex <url> | iex` fashion) fails or you do not have an internet connection on the computer you wish to use winutil on:

You can save the compiled [`winutil.ps1`](https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winget.ps1) as a .ps1 file on your computer.

Do note some browsers will download it as ``.ps1.txt`` (see [showing file extensions](https://www.thewindowsclub.com/show-file-extensions-in-windowshttps://www.thewindowsclub.com/show-file-extensions-in-windows) to be able to rename it as PowerShell won't support running it)

Open PowerShell (as an Administrator) in that directory, you'll most likely need to set the execution policy (per default PowerShell disallows running .ps1 files for "security measures")

```
Set-ExecutionPolicy Bypass -Scope Process -Force
```
(This will allow you running scripts for only this session, see [about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1))

I won't be explaining the many ways to [`cd`](https://learn.microsoft.com/en-us/powershell/scripting/samples/managing-current-location?view=powershell-5.1) to a folder, the safest way is to simply get the absolute path of the file:

* Open the File Explorer
* Navigate to where you saved `winutil.ps1` (most likely Downloads)
* <kbd>SHIFT+Right click</kbd> the `winutil.ps1` file
* Click `Copy as Path`, the full path will be copied to your clipboard.

Then back to your PowerShell window, type the `&` character, a <kbd>SPACE</kbd> and paste with <kbd>CTRL+V</kbd>, example:

```
& "C:\Users\notchris\Downloads\winutil.ps1"
```

Then to run winutil.ps1, shift right click the file 

See also the [winutil.ps1 execution video guide](https://i.imgur.com/keJSiMS.mp4)

</details>

## Support
- To morally and mentally support the project, make sure to leave a ⭐️!
- EXE Wrapper for $10 @ https://www.cttstore.com/windows-toolbox

## Tutorial

[![Watch the video](https://i.ytimg.com/vi/XQAIYCT4f8Q/maxresdefault.jpg)](https://www.youtube.com/watch?v=XQAIYCT4f8Q)

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

- MicroWin:
  - This is an minimal ISO creation tool like NTLite, MSMG Toolkit, and others. It does NOT download the ISO for you but uses the official Microsoft Windows ISO you can obtain from <https://www.microsoft.com/software-download/windows11>
  - Supports multiple versions and languages. 
  - Options include removing built-in Microsoft Store (APPX) packages, Edge, and Defender. 

Video and Written Article walkthrough @ <https://christitus.com/windows-tool/>

## Issues

If you encounter any challenges or problems with the script, I kindly request that you submit them via the "Issues" tab on the GitHub repository. By filling out the provided template, you can provide specific details about the issue, allowing me to promptly address any bugs or consider feature requests.

## Contribute Code

To contribute new code, please ensure that it is submitted to the `test-yyyy-mm-dd` branch. Please note that all pull requests will be closed if done on the `main` branch.

When creating pull requests, it is essential to thoroughly document all changes made. This includes documenting any additions made to the tweaks section and ensuring that corresponding undo measures are in place to remove the newly added tweaks if necessary. Failure to adhere to this format may result in denial of the pull request. Additionally, comprehensive documentation is required for all code changes. Any code lacking sufficient documentation may also be denied.

By following these guidelines, we can maintain a high standard of quality and ensure that the codebase remains organized and well-documented.

You can learn more about contributing on Git and GitHub [here](https://github.com/firstcontributions/first-contributions#readme)

## Thanks to all Contributors
Thanks a lot for spending your time helping Winutil grow. Thanks a lot! Keep rocking 🍻.

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/winutil)](https://github.com/ChrisTitusTech/winutil/graphs/contributors)

## GitHub Stats

![Alt](https://repobeats.axiom.co/api/embed/aad37eec9114c507f109d34ff8d38a59adc9503f.svg "Repobeats analytics image")
