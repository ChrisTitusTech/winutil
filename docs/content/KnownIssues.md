---
title: Known Issues
toc: true
---

### Download not working

If `https://christitus.com/win` is not working, or you want to download the code from GitHub directly, you can use the direct download link:

```
irm https://github.com/ChrisTitusTech/Winutil/releases/latest/download/Winutil.ps1 | iex
```

If it still isn't working in your region, it may be due to temporary ISP or network filtering of GitHub content domains. This has been reported by some users in India in the past. See: [Times of India](https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms).

If you are still having issues, try using a **VPN**, or changing your **DNS provider** to one of the following two providers:

|  Provider  | Primary DNS | Secondary DNS |
| :--------: | :---------: | :-----------: |
| Cloudflare |  `1.1.1.1`  |   `1.0.0.1`   |
|   Google   |  `8.8.8.8`  |   `8.8.4.4`   |

### Script Won't Run

If your PowerShell session is running in **Constrained Language Mode**, some scripts and commands may fail to execute. To check the current language mode, run:
```powershell
$ExecutionContext.SessionState.LanguageMode
```
If it returns `ConstrainedLanguage`, you may need to switch to `FullLanguage` mode or run the script in a session with administrative privileges. Be aware that some security policies may enforce Constrained Language Mode, especially in corporate or managed environments.

**If the download fails**:

1. Try the direct GitHub link:

```powershell
irm https://github.com/ChrisTitusTech/Winutil/releases/latest/download/Winutil.ps1 | iex
```

2. Force TLS 1.2:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm "https://christitus.com/win" | iex
```

> [!NOTE]
> On Windows 11, you usually do not need the TLS 1.2 command. Use it only if you encounter download or security protocol errors.

### Execution Policy Error

If you see an execution policy error when running the downloaded script, you can allow the current session to run unsigned scripts with this command:

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force
irm "https://christitus.com/win" | iex
```

This only changes the policy for the current PowerShell process and is safe for one-off runs.

### Interface Doesn't Appear

If Winutil downloads, but the GUI does not open or appear, try these steps:

1. Check if your antivirus or Windows Defender is blocking the script — add an exclusion if necessary.
2. Ensure you launched PowerShell / Terminal as **Administrator**.
3. Close and reopen PowerShell, then run the launch command again.
4. If the script still doesn't show, try running the script in a visible PowerShell window (avoid background/silent shells) to observe output and errors.
