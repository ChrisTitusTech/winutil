---
title: Getting Started
weight: 2
---

## Welcome to Winutil!

Winutil is a powerful Windows utility that helps you optimize, customize, and maintain your Windows system. This guide will walk you through everything you need to get started.

## System Requirements

Before running Winutil, ensure your system meets these requirements:

- **Operating System**: Windows 10 (Latest Version) or Windows 11
- **PowerShell**: Version 5.1 or later (included by default in Windows 10/11)
- **Administrator Access**: Required for system-level changes
- **Internet Connection**: Required for downloading applications and updates
- **.NET Framework**: Version 4.5 or later (usually pre-installed)

## Installation

Winutil doesn't require traditional installation. It runs directly from PowerShell as a script.

### Step 1: Open PowerShell as Administrator

There are several ways to open PowerShell with admin rights:

**Method 1: Start Menu (Recommended)**

1. Right-click on the Windows Start button
2. Select "Windows PowerShell (Admin)" on Windows 10
3. Or select "Terminal (Admin)" on Windows 11

**Method 2: Search Method**

1. Press the `Windows` key
2. Type "PowerShell" or "Terminal"
3. Press `Ctrl + Shift + Enter` to launch as administrator
4. Or right-click and select "Run as administrator"

**Method 3: Run Dialog**

1. Press `Windows + R`
2. Type `powershell`
3. Press `Ctrl + Shift + Enter`

### Step 2: Run the Launch Command

Once PowerShell is open with administrator privileges, run one of these commands:

**Stable Release (Recommended for most users)**

```powershell
irm "https://christitus.com/win" | iex
```

**Development Branch (For testing latest features)**

```powershell
irm "https://christitus.com/windev" | iex
```

> [!NOTE]
> The `irm` command downloads the script, and `iex` executes it. This is safe when downloading from the official source.

### Step 3: Wait for Winutil to Load

The first time you run Winutil, it may take a few moments to:

- Download the latest version
- Initialize the interface
- Load all features and settings

## First Time Setup

### Configure WinGet (If Prompted)

On your first run, you may be prompted to configure WinGet (Windows Package Manager). This is normal.

1. When prompted, type `Y` and press Enter
2. Accept the terms and conditions
3. This only needs to be done once

### Understanding the Interface

Winutil opens with a clean, tabbed interface:

**Main Tabs**:

- **Install**: Browse and install applications
- **Tweaks**: Apply system optimizations and customizations
- **Config**: Access system tools and utilities
- **Updates**: Manage Windows updates

## Your First Actions

Here are some recommended first steps for new users:

### 1. Create a Restore Point

Before making any changes, create a system restore point:

1. Go to the **Tweaks** tab
2. Find "Create Restore Point" under Essential Tweaks
3. Check the box and click "Run Tweaks"

This allows you to undo changes if needed.

### 2. Install Essential Applications

1. Navigate to the **Install** tab
2. Browse categories or use the search bar
3. Check applications you want to install
4. Click "Install Selected" at the bottom

### 3. Apply Basic Tweaks

For a better Windows experience without risks:

1. Go to the **Tweaks** tab
2. Select the **"Desktop" preset** for a balanced configuration
3. Review the selected tweaks
4. Click "Run Tweaks"

## Common Tasks

### Installing Applications

**Single Application**:

1. Open **Install** tab
2. Search for the application name
3. Check the box next to it
4. Click "Install Selected"

**Multiple Applications**:

1. Check multiple application boxes
2. All checked apps will install in sequence
3. Progress is shown in the bottom panel

### Applying Tweaks

**Essential Tweaks** (Safe for all users):

1. Go to **Tweaks** tab
2. Select from Essential Tweaks section
3. Click "Run Tweaks"

**Advanced Tweaks** (Use with caution):

1. Only modify if you understand the implications
2. Always create a restore point first
3. Review documentation for each tweak

**Undoing Tweaks**:

1. Select the same tweaks you applied
2. Click "Undo Selected Tweaks"
3. System will revert to previous state

### Using Quick Fixes

For common Windows issues:

1. Go to **Config** tab
2. Navigate to **Fixes** section
3. Select the appropriate fix:
   - **Reset Network**: Fixes network connectivity issues
   - **Reset Windows Update**: Resolves update problems
   - **System Corruption Scan**: Repairs corrupted system files
   - **WinGet Reinstall**: Fixes package manager issues

### Changing DNS Servers

For improved privacy and speed:

1. Go to **Config** or **Tweaks** tab
2. Find the DNS section
3. Select a provider:
   - **Cloudflare**: Fast and privacy-focused
   - **Google**: Reliable and widely used
   - **Quad9**: Security-focused with malware blocking
   - **AdGuard**: Blocks ads and trackers
4. Click Apply

## Understanding Presets

Winutil offers several preset configurations:

- **Minimal**: Minimal changes, keeps most Windows features
- **Standard**: Good middle-ground for most users

## Safety Tips

✅ **DO**:

- Create restore points before major changes
- Read tweak descriptions before applying
- Start with Essential Tweaks
- Test changes on non-critical systems first
- Keep backups of important data

❌ **DON'T**:

- Apply all tweaks without understanding them
- Skip creating restore points
- Disable security features unnecessarily
- Use on production systems without testing
