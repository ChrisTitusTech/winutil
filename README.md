# Chris Titus Tech's Windows Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/winutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/winutil/releases/latest)
![Downloads](https://img.shields.io/github/downloads/ChrisTitusTech/winutil/winutil.ps1?label=Total%20Downloads&style=for-the-badge)
[![Discord](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)

A curated compilation of Windows system tasks streamline **installs**, debloat with **tweaks**, troubleshoot with **config**, and configure **Windows updates**. Run it fresh on every new Windows install.

![Title Screen](/docs/assets/images/Title-Screen.png)

---

## Quick Start

> **WinUtil must be run as Administrator** Because it performs system-wide changes.

Open PowerShell or Terminal as admin, then run:

**Stable Branch (recommended)**
```ps1
irm https://christitus.com/win | iex
```

**Development Branch**
```ps1
irm https://christitus.com/windev | iex
```

### How to open an admin terminal

- **Start menu:** Right-click Start → *Windows PowerShell (Admin)* or *Terminal (Admin)*
- **Search:** Press the `Windows key`, and type `PowerShell` or `Terminal`, then `Ctrl + Shift + Enter`

---

## Automation / Presets

Apply a predefined configuration without manual selection:

```powershell
& ([ScriptBlock]::Create((irm https://christitus.com/win))) -Preset Standard
```

| Preset | Description |
|--------|-------------|
| `Standard` | Balanced defaults for most users |
| `Minimal` | Minimal changes to suit every user |
| `Advanced` | Deep tweaks for power users |

To view exactly what each preset does, see:
https://github.com/ChrisTitusTech/winutil/blob/main/config/preset.json

---

## Build & Develop

See https://github.com/ChrisTitusTech/winutil/blob/main/.github/CONTRIBUTING.md

---

## Resources

- [Official Documentation](https://winutil.christitus.com/)
- [YouTube Tutorial](https://www.youtube.com/watch?v=6UQZ5oQg8XA)
- [ChrisTitus.com Article](https://christitus.com/windows-tool/)
- [Known Issues](https://winutil.christitus.com/knownissues/)
- [Report an Issue](https://github.com/ChrisTitusTech/winutil/issues)

---

## Support

- Leave a ⭐ to show support!
- EXE Wrapper for $10 @ https://www.cttstore.com/windows-toolbox

## Sponsors

These are the sponsors that help keep this project alive with monthly contributions.

<!-- sponsors --><a href="https://github.com/ysaito8015"><img src="https:&#x2F;&#x2F;github.com&#x2F;ysaito8015.png" width="60px" alt="User avatar: Yusuke Saito" /></a><a href="https://github.com/dwelfusius"><img src="https:&#x2F;&#x2F;github.com&#x2F;dwelfusius.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/mews-se"><img src="https:&#x2F;&#x2F;github.com&#x2F;mews-se.png" width="60px" alt="User avatar: Martin Stockzell" /></a><a href="https://github.com/jdiegmueller"><img src="https:&#x2F;&#x2F;github.com&#x2F;jdiegmueller.png" width="60px" alt="User avatar: Jason A. Diegmueller" /></a><a href="https://github.com/robertsandrock"><img src="https:&#x2F;&#x2F;github.com&#x2F;robertsandrock.png" width="60px" alt="User avatar: RMS" /></a><a href="https://github.com/paulsheets"><img src="https:&#x2F;&#x2F;github.com&#x2F;paulsheets.png" width="60px" alt="User avatar: Paul" /></a><a href="https://github.com/djones369"><img src="https:&#x2F;&#x2F;github.com&#x2F;djones369.png" width="60px" alt="User avatar: Dave J  (WhamGeek)" /></a><a href="https://github.com/anthonymendez"><img src="https:&#x2F;&#x2F;github.com&#x2F;anthonymendez.png" width="60px" alt="User avatar: Anthony Mendez" /></a><a href="https://github.com/FatBastard0"><img src="https:&#x2F;&#x2F;github.com&#x2F;FatBastard0.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/DursleyGuy"><img src="https:&#x2F;&#x2F;github.com&#x2F;DursleyGuy.png" width="60px" alt="User avatar: DursleyGuy" /></a><a href="https://github.com/DwayneTheRockLobster1"><img src="https:&#x2F;&#x2F;github.com&#x2F;DwayneTheRockLobster1.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/KieraKujisawa"><img src="https:&#x2F;&#x2F;github.com&#x2F;KieraKujisawa.png" width="60px" alt="User avatar: Kiera Meredith" /></a><a href="https://github.com/andrewpayne68"><img src="https:&#x2F;&#x2F;github.com&#x2F;andrewpayne68.png" width="60px" alt="User avatar: Andrew P" /></a><a href="https://github.com/johanwildeboer"><img src="https:&#x2F;&#x2F;github.com&#x2F;johanwildeboer.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/lukas346"><img src="https:&#x2F;&#x2F;github.com&#x2F;lukas346.png" width="60px" alt="User avatar: Wook" /></a><a href="https://github.com/tsv31"><img src="https:&#x2F;&#x2F;github.com&#x2F;tsv31.png" width="60px" alt="User avatar: Sorin" /></a><a href="https://github.com/seanh1995"><img src="https:&#x2F;&#x2F;github.com&#x2F;seanh1995.png" width="60px" alt="User avatar: Sean (ANGRYxScotsman)" /></a><!-- sponsors -->

---

## Contributors

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/winutil)](https://github.com/ChrisTitusTech/winutil/graphs/contributors)

Thanks to everyone who has contributed time and effort to this project. Keep rocking 🍻
