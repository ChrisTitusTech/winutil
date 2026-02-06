---
title: Frequently Asked Questions
toc: true
---

## General Questions

### How do I uninstall Winutil?
You do not have to uninstall Winutil. As it is a script you run from PowerShell, it only loads into your RAM. This means as soon as you close Winutil, it will be cleared from your system. Winutil doesn't install itself permanently on your computer.

### Is Winutil safe to use?
Yes, Winutil is open source and the code is publicly available on GitHub. Thousands of users run it daily. However, like any system modification tool, you should:
- Run it as Administrator (required)
- Create a restore point before major changes
- Understand what tweaks you're applying
- Download only from official sources

### Do I need to keep running Winutil?
No. Once you've applied tweaks or installed applications, you can close Winutil. Changes persist after closing. You only need to run Winutil again when you want to make additional changes or undo tweaks.

### Does Winutil require internet access?
- **For downloading**: Yes, installing applications requires internet
- **For tweaks**: No, most tweaks work offline
- **Initial run**: Yes, to download the latest script

### How often is Winutil updated?
Winutil is actively maintained with frequent updates. New features, bug fixes, and application additions are released regularly. The script auto-downloads the latest version each time you run it.

## Installation & Running

### How do I run Winutil?
1. Open PowerShell as Administrator
2. Run: `irm "https://christitus.com/win" | iex`
3. Wait for the GUI to appear

### Why do I need Administrator rights?
Winutil makes system-level changes (registry edits, service modifications, software installation) that require elevated permissions. Without admin rights, most features won't work.

### The script won't download. What do I do?
Try these solutions in order:

1. **Use the direct GitHub link**:
   ```powershell
   irm https://github.com/ChrisTitusTech/Winutil/releases/latest/download/Winutil.ps1 | iex
   ```

2. **Force TLS 1.2** (for older Windows):
   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   irm "https://christitus.com/win" | iex
   ```

3. **Change DNS** to Cloudflare (1.1.1.1) or Google (8.8.8.8)

4. **Use a VPN** if GitHub is blocked in your region

### I get an "Execution Policy" error. How do I fix it?
Run this command first to allow script execution:
```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force
irm "https://christitus.com/win" | iex
```

This only affects the current PowerShell session and is safe.

## Tweaks & Modifications

### I applied a tweak and now something doesn't work. What do I do?
If you applied a tweak and it breaks something, you can revert it:
1. Open Winutil again
2. Go to the **Tweaks** tab
3. Select the same tweak you applied
4. Click **"Undo Selected Tweaks"**
5. The system will revert to the previous state

Alternatively, use System Restore if you created a restore point.

### Which tweaks are safe to apply?
**Safe for everyone (Essential Tweaks)**:
- Disable Telemetry
- Disable Activity History
- Disable Location Tracking
- Delete Temporary Files
- Run Disk Cleanup
- Create Restore Point

**Caution needed (Advanced Tweaks)**:
- Remove Microsoft Store
- Disable Windows Defender
- Remove all bloatware
- Disable system services

Start with Essential Tweaks. Only use Advanced Tweaks if you understand the implications.

### Will tweaks survive Windows Updates?
Most tweaks persist through updates, but some may be reset by major Windows updates (feature updates). You may need to reapply certain tweaks after major updates.

### Can I create my own tweak presets?
Currently, Winutil uses predefined presets (Desktop, Laptop, Minimal, Standard). Custom presets aren't directly supported in the GUI, but you can script your preferred configuration.

### What's the difference between Essential and Advanced tweaks?
- **Essential Tweaks**: Safe for most users, improve performance/privacy with minimal risk
- **Advanced Tweaks**: More aggressive changes that may break functionality or compatibility. Use with caution.

## Application Installation

### How does Winutil install applications?
Winutil uses Windows Package Manager (WinGet) and Chocolatey to automate installations. It downloads applications from official sources and installs them silently without bloatware.

### Can I install multiple applications at once?
Yes! Check the boxes for all applications you want, then click "Install Selected". They'll install sequentially.

### WinGet isn't working. How do I fix it?
1. Go to the **Config** tab
2. Find **Fixes** section
3. Click **"WinGet Reinstall"**
4. Wait for completion
5. Try installing applications again

### Do installed applications have bloatware or bundled software?
No. WinGet and Chocolatey install clean versions of applications without bundled offers, toolbars, or bloatware.

### Can I uninstall applications through Winutil?
Winutil focuses on installation. To uninstall:
- Use Windows Settings > Apps > Installed Apps
- Or use the application's built-in uninstaller

### Will installed apps auto-update?
Applications with built-in update mechanisms will auto-update. You can also update them via WinGet/Chocolatey commands or through Winutil's "Upgrade Selected" feature.

## Updates & Maintenance

### Should I disable Windows Updates?
Generally, **no**. Security updates are important. However, you might:
- Use "Security Updates Only" to avoid feature updates
- Pause updates temporarily for stability
- Disable only during critical work periods

### How do I re-enable updates after disabling them?
1. Open Winutil
2. Go to **Updates** tab
3. Click **"Enable Updates"**
4. Updates will resume normally

### What's the difference between "Security Updates Only" and "Disable Updates"?
- **Security Updates Only**: Installs critical security patches, blocks feature updates (major versions)
- **Disable Updates**: Blocks ALL updates including security (not recommended)

## Troubleshooting

### Winutil won't open after running the command
Possible causes:
1. **Antivirus blocking**: Add PowerShell exception
2. **Not run as Admin**: Restart PowerShell as Administrator
3. **Corrupted download**: Close PowerShell, reopen, try again
4. **Windows Defender**: Allow the script

### My antivirus flags Winutil as malicious
This is a false positive. Winutil makes system changes that antivirus programs may flag. The code is open source and audited. Add an exception if needed.

### An application failed to install
Troubleshooting steps:
1. Check your internet connection
2. Try installing just that one application
3. Review error messages in the output panel
4. Check if antivirus is blocking
5. Try the WinGet Reinstall fix

### Network tweaks broke my internet connection
1. Open Winutil
2. Go to **Config** > **Fixes**
3. Click **"Reset Network"**
4. Restart your computer
5. Connection should be restored

### I can't access certain Windows features after applying tweaks
Undo the tweaks that might have affected those features:
1. Reopen Winutil
2. Select the tweaks you applied
3. Click "Undo Selected Tweaks"

If that doesn't work, use System Restore to revert to a previous state.

## Advanced Topics

### Can I run Winutil on Windows Server?
Yes, Winutil works on Windows Server editions, though some features may not be applicable or may behave differently.

### Does Winutil work with Windows LTSC?
Yes, Winutil works with Windows 10/11 LTSC editions. Some applications may not be available depending on your configuration.

### Can I use Winutil in a corporate/enterprise environment?
Yes, but check your organization's policies first. Some tweaks may conflict with group policies or corporate requirements.

### How do I automate Winutil for multiple PCs?
See the [Automation Guide](userguide/automation/) for details on:
- Configuration files
- PowerShell parameters
- Batch deployment
- Silent installation

### Can I contribute to Winutil?
Yes! Contributions are welcome:
- Report bugs on GitHub Issues
- Submit pull requests for fixes/features
- Improve documentation
- Help others in Discord

See the [Contributing Guide](contributing/) for details.

## Privacy & Security

### Does Winutil collect any data?
No, Winutil itself doesn't collect or transmit any user data. It's a local PowerShell script.

### What telemetry does the Disable Telemetry tweak block?
It disables:
- Windows diagnostic data collection
- Activity history tracking
- Feedback requests
- Usage statistics
- Error reporting (optional)

### Is it safe to disable Windows Defender?
**Generally not recommended**. Only disable Defender if:
- You have alternative antivirus installed
- You understand the security risks
- You're in a controlled/isolated environment

### Will removing Microsoft Store affect security updates?
No, Windows security updates are independent of the Microsoft Store.

## Performance

### Will Winutil make my PC faster?
Tweaks can improve performance by:
- Reducing background processes
- Disabling unnecessary services
- Cleaning temporary files
- Optimizing startup programs

Results vary based on your system and which tweaks you apply.

### What's the best preset for gaming?
Use the **Desktop** preset, then additionally apply:
- Disable GameDVR
- Ultimate Performance power plan
- Disable fullscreen optimizations (Advanced)
- Set display for performance (Advanced)

### How much RAM does Winutil use?
Winutil itself uses ~50-100MB while running. Once closed, it's removed from memory.

## Error Messages

### "Access Denied" errors
- Ensure PowerShell is running as Administrator
- Check if antivirus is blocking changes
- Verify you have ownership of files/registry keys

### WinGet configuration prompt won't go away
Type `Y` and press Enter in the PowerShell window. This only happens on first use and configures WinGet for your system.

## Still Need Help?

Can't find your answer? Try these resources:

- **[Known Issues](knownissues/)** - Check if it's a known problem
- **[User Guide](userguide/)** - Comprehensive documentation
- **[Discord Community](https://discord.gg/RUbZUZyByQ)** - Get help from other users
- **[GitHub Issues](https://github.com/ChrisTitusTech/winutil/issues)** - Report bugs
- **[YouTube Tutorial](https://www.youtube.com/watch?v=6UQZ5oQg8XA)** - Video walkthrough

---

**Last Updated**: January 2026
**Found this helpful?** Consider starring the project on [GitHub](https://github.com/ChrisTitusTech/winutil)!
