# Chris Titus Tech's Windows Utility

This Utility is a compilation of windows tasks I perform on each Windows system I use. It is meant to streamline *installs*, debloat with *tweaks*, troubleshoot with *config*, and fix Windows *updates*. I am extremely picky on any contributions to keep this project clean and efficient. 

![screen-install](screen-install.png)

Requires you to launch PowerShell or Windows Terminal As ADMINISTRATOR! 

The recommended way is to right click on the start menu and select (PowerShell As Admin *Windows 10* - Windows Terminal As Admin *Windows 11*)

Launch Command:

```
iwr -useb https://christitus.com/win | iex
```
Or shorter Thanks to [#144](/../../issues/144)
```
irm christitus.com/win | iex
```
If you are having TLS 1.2 Issues or You cannot find or resolve `christitus.com/win` then run with the following command:
```
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1')
```

EXE Wrapper for $10 @ https://www.cttstore.com/windows-toolbox

## Overview

- Install
  - Installs all selected programs
  - Has Upgrade ALL existing programs button
- Tweaks
  - Optimizes windows and reduces running processes
  - Has recommended settings for each type of system
- Config
  - Quick configurations for Windows Installs
  - Has old legacy panels from Windows 7
  - Reset Windows Update to factory settings
  - System Corruption Scan
- Updates
  - Fixes the default windows update scheme

Video and Written Article walkthrough @ <https://christitus.com/windows-tool/>

## Issues

If you have any issues with the script please submit them to Issues tab here on GitHub and fill out the template so I can fix any bugs or make feature requests. 

## Contribute Code

**Any new code must be submitted to TEST BRANCH! - No merges will be performed on MAIN branch**

For pull requests, be sure and document ALL changes. If you add something to the tweaks section the undo MUST also be applied to remove the new tweaks. Any tweak not following this format will be denied. Any code not well documented will be denied.
