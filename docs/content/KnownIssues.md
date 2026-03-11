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

If you are still having issues, try using a **VPN**, or changing your **DNS provider** to one of following two providers:

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
