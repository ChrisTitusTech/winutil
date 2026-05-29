# Chris Titus Tech's Windows Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/winutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/winutil/releases/latest)
![Downloads](https://img.shields.io/github/downloads/ChrisTitusTech/winutil/winutil.ps1?label=Total%20Downloads&style=for-the-badge)
[![Discord](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)
[![Docs](https://img.shields.io/badge/Documentation-_?style=for-the-badge&logo=bookstack&color=grey)](https://winutil.christitus.com/)

A curated compilation of Windows system tasks streamline **installs**, debloat with **tweaks**, troubleshoot with **config**, and fix **Windows updates**. Run it fresh on every new Windows setup.

![Title Screen](/docs/assets/images/Title-Screen.png)

---

## Quick Start

> **WinUtil must be run as Administrator** — it performs system-wide changes.

Open PowerShell or Terminal as admin, then run:

**Stable Branch (recommended)**
```ps1
irm "https://christitus.com/win" | iex
```

**Development Branch**
```ps1
irm "https://christitus.com/windev" | iex
```

### How to open an admin terminal

- **Start menu:** Right-click Start → *Windows PowerShell (Admin)* or *Terminal (Admin)*
- **Search:** Press `Win`, type `PowerShell` or `Terminal`, then `Ctrl + Shift + Enter`

---

## Automation / Presets

Apply a predefined configuration without manual selection:

```powershell
& ([ScriptBlock]::Create((irm "https://christitus.com/win"))) -Preset Standard
```

| Preset | Description |
|--------|-------------|
| `Standard` | Balanced defaults for most users |
| `Minimal` | Strips down the bare minimum |
| `Advanced` | Deep tweaks for power users |

Full preset config: [`config/preset.json`](https://github.com/ChrisTitusTech/winutil/blob/main/config/preset.json)

---

## Build & Develop

See [CONTRIBUTING.md](https://github.com/ChrisTitusTech/winutil/blob/main/.github/CONTRIBUTING.md).

---

## 📚 Resources

- [Official Documentation](https://winutil.christitus.com/)
- [YouTube Tutorial](https://www.youtube.com/watch?v=6UQZ5oQg8XA)
- [ChrisTitus.com Article](https://christitus.com/windows-tool/)
- [Known Issues](https://winutil.christitus.com/knownissues/)
- [Report an Issue](https://github.com/ChrisTitusTech/winutil/issues)

---

## 💖 Support

- Leave a ⭐ to show support!
- EXE Wrapper for $10 @ https://www.cttstore.com/windows-toolbox

---

## 🏅 Contributors

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/winutil)](https://github.com/ChrisTitusTech/winutil/graphs/contributors)

Thanks to everyone who has contributed time and effort to this project. Keep rocking 🍻
