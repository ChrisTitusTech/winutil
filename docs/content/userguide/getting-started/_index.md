---
title: Getting Started
weight: 2
---

## Welcome to Winutil!

Winutil is a powerful Windows utility that helps you optimize, customize, and maintain your system. This guide walks you through everything you need to get started.

## System Requirements

Before running Winutil, ensure your system meets these requirements:

> [!IMPORTANT]
> Windows 10 is not supported by Winutil. Windows 10 reached end of support on **October 14, 2025**.

- **Operating System**: Windows 11
- **PowerShell**: Version 5.1 or later (included by default in Windows 11)
- **Administrator Access**: Required for system-level changes
- **Internet Connection**: Required for downloading applications and updates

## Installation

Winutil doesn't require traditional installation. It runs directly from PowerShell as a script.

### Step 1: Open PowerShell as Administrator

There are several ways to open PowerShell with admin rights:

**Method 1: Start Menu (Recommended)**

1. Right-click the Windows Start button
2. Select "Terminal (Admin)"

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

### Understanding the Interface

Winutil opens with a clean, tabbed interface:

**Main Tabs**:

- **Install**: Browse and install applications
- **Tweaks**: Apply system optimizations and customizations
- **Config**: Access system tools and utilities
- **Updates**: Manage Windows updates
- **Win11 Creator**: Allows user to debloat iso files

## Your First Actions

Here are some recommended first steps for new users:

### 1. Create a Restore Point

Before making any changes, create a system restore point:

1. Go to the **Tweaks** tab
2. Find "Create Restore Point" under Essential Tweaks
3. Check the box and click **Run Tweaks**

This gives you a rollback point if needed.

### 2. Install Essential Applications

1. Navigate to the **Install** tab
2. Browse categories or use the search bar
3. Check applications you want to install
4. Click "Install/Upgrade Selected" at the bottom

### 3. Apply Basic Tweaks

For a better Windows experience with minimal risk:

1. Go to the **Tweaks** tab
2. Select the **"Desktop" preset** for a balanced configuration
3. Review the selected tweaks
4. Click **Run Tweaks**

## Common Tasks

### Installing Applications

**Single Application**:

1. Open the **Install** tab
2. Search for the application name
3. Check the box next to it
4. Click "Install/Upgrade Selected"

**Multiple Applications**:

1. Check multiple application boxes
2. All checked apps will install in sequence
3. Progress is shown in the bottom panel

### Applying Tweaks

**Essential Tweaks** (Safe for all users):

1. Go to the **Tweaks** tab
2. Select from the Essential Tweaks section
3. Click **Run Tweaks**

**Advanced Tweaks** (Use with caution):

1. Only modify if you understand the implications
2. Always create a restore point first
3. Review documentation for each tweak

**Undoing Tweaks**:

1. Select the same tweaks you applied
2. Click **Undo Selected Tweaks**
3. The system reverts to the previous state

### Using Quick Fixes

For common Windows issues:

1. Go to the **Config** tab
2. Navigate to the **Fixes** section
3. Select the appropriate fix:
   - **Reset Network**: Fixes network connectivity issues
   - **Reset Windows Update**: Resolves update problems
   - **System Corruption Scan**: Repairs corrupted system files
   - **WinGet Reinstall**: Fixes package manager issues

### Changing DNS Servers

For improved privacy and speed:

1. Go to the **Tweaks** tab
2. Find the DNS section
3. Select a provider:
   - **Cloudflare**: Fast and privacy-focused
   - **Google**: Reliable and widely used
   - **Quad9**: Security-focused with malware blocking
   - **AdGuard**: Blocks ads and trackers
4. Click **Apply**

## Understanding Presets

Winutil offers several preset configurations:

- **Minimal**: Minimal changes that keep most Windows features
- **Standard**: A good middle ground for most users

## Safety Tips

✅ **DO**:

- Create restore points before major changes
- Read tweak descriptions before applying
- Start with Essential Tweaks
- Keep Windows up to date

❌ **DON'T**:

- Apply all tweaks at once without understanding them
- Skip creating restore points
- Use Advanced Tweaks without research
- Disable security features unless necessary
- Run on production systems without testing

## Troubleshooting First Run

### Script Won't Download

If you get any errors when running winutil please refer to [Known Issues](/knownissues/) page

## Next Steps

Now that you're set up, explore these guides:

- [Applications Guide](../application/) - Learn about installing, upgrading, and uninstalling software
- [Tweaks Guide](../tweaks/) - Understand system optimizations
- [FAQ](/faq/) - Common questions and answers

## Getting Help

If you need assistance:

- **Documentation**: Browse this documentation site
- **Discord**: Join the [community Discord server](https://discord.gg/RUbZUZyByQ)
- **GitHub Issues**: Report bugs on [GitHub](https://github.com/ChrisTitusTech/winutil/issues)
- **YouTube**: Watch [video tutorials](https://www.youtube.com/watch?v=6UQZ5oQg8XA)

## Quick Reference Card

| Task | Location | Action |
| ---- | -------- | ------ |
| Install or upgrade apps | Install tab | Check boxes -> Install/Upgrade Selected |
| Uninstall apps | Install tab | Check boxes -> Uninstall Selected |
| Apply tweaks | Tweaks tab | Select tweaks -> Run Tweaks |
| Undo tweaks | Tweaks tab | Select tweaks -> Undo Selected Tweaks |
| Create restore point | Tweaks tab | Essential Tweaks section |
| Fix network | Config tab | Fixes -> Reset Network |
| Change DNS | Tweaks tab | DNS section |
| Open Control Panel | Config tab | Legacy Windows Panels |

Happy optimizing!
