## Known Issues and Fixes

### Launch Issues:

- Windows Security (formerly Defender) and other anti-virus software are known to block the script. The script gets flagged due to the fact that it requires administrator privileges & makes drastic system changes.
  - If possible: Allow script in Anti-Virus software settings.

- If you are having TLS 1.2 issues, or are having trouble resolving `christitus.com/win` then run with the following command:

```
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1')
```

- If you are unable to resolve `christitus.com/win` and are getting  errors launching the tool, it might be due to India blocking GitHub's content domain and preventing downloads.
  - Source: <https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms>

If you are still having issues try using a **VPN**, or changing your **DNS provider** to:

| `1.1.1.1` | `1.0.0.1` | or  | `8.8.8.8` | `8.8.4.4` |
|---------|---------|-----|---------|---------|

- Script doesn't run/PowerShell crashes:
  1. Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11)
  2. Run:
  ```ps1
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```
  3. Run:
  ```
  irm christitus.com/win | iex
  ```

### Other Issues:

- Windows taking longer to shut down:
  - [#69](https://github.com/ChrisTitusTech/winutil/issues/69) Turn on fast startup: Press Windows key + R, then type:
  ```
  control /name Microsoft.PowerOptions /page pageGlobalSettings
  ```
  - If that doesn't work, Disable Hibernation: Press Windows Key+X and select 'PowerShell (Admin)' (Windows 10) or 'Windows Terminal (Admin)' (Windows 11) and enter:
  ```
  powercfg /H off
  ```
- [#69](https://github.com/ChrisTitusTech/winutil/issues/69) [95](https://github.com/ChrisTitusTech/winutil/issues/95) [#232](https://github.com/ChrisTitusTech/winutil/issues/232) Windows Search does not work: Enable Background Apps
- [#198](https://github.com/ChrisTitusTech/winutil/issues/198) Xbox Game Bar Activation Broken: Set the Xbox Accessory Management Service to Automatic
```
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```

- Winget requires interaction on first run: Manually type 'y' and 'enter' into the PowerShell console to continue
- (Windows 11) Quick Settings no longer works: Launch the Script and click 'Enable Action Center'

- Explorer no longer launches: Go to Control Panel, File Explorer Options, Change the 'Open File Explorer to' option to 'This PC'.
