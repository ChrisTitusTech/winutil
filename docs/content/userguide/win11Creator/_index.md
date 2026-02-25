---
title: Win 11 Creator
weight: 5
---

## Using Winutil's Win11 Creator

Winutil includes a built-in **Win11 Creator** tool that lets you take any official Windows 11 ISO and produce a customized, debloated version — with telemetry removed, hardware requirement checks bypassed, and local account setup enabled out of the box. You can export the result as a new ISO file or write it directly to a USB drive.

> [!IMPORTANT]
> You need a valid Windows 11 ISO before starting. Download one from [Microsoft's official site](https://www.microsoft.com/en-us/software-download/windows11) or use [UUP Dump](https://uupdump.net/). The process uses ~10–15 GB of temporary disk space, so make sure you have room.

---

### Step 1 — Select Your ISO

1. Open Winutil and go to the **Win11 Creator** tab.
2. Click **Browse** and select your Windows 11 ISO file (must be 4 GB or larger).
3. The file path and size will appear on screen once selected.

---

### Step 2 — Mount & Verify

1. Click **Mount & Verify ISO**.
2. Winutil mounts the ISO, checks for a valid `install.wim` or `install.esd`, and reads the available editions (Home, Pro, Enterprise, etc.).
3. Once verified, select your desired **edition** from the dropdown — Pro is selected by default if available.

> [!NOTE]
> This step takes around 10–30 seconds depending on your drive speed.

---

### Step 3 — Run the Modification

Click **Run Windows ISO Modification and Creator** to start the customization process. Winutil will:

- **Remove 40+ bloat apps** — Clipchamp, Teams, Copilot, Dev Home, new Outlook, Bing apps, Solitaire, and more
- **Delete OneDrive setup** from the image
- **Apply registry tweaks** — disables telemetry, advertising ID, tailored experiences, and cloud content features
- **Bypass hardware checks** — removes TPM, Secure Boot, CPU, and RAM requirement enforcement so the ISO installs on unsupported hardware
- **Enable local account setup** — injects an `autounattend.xml` that skips the Microsoft account screen during OOBE
- **Strip unused editions** — keeps only your selected edition, saving 1–2 GB per removed edition
- **Clean the component store** — runs DISM cleanup to reclaim another 300–800 MB
- **Remove telemetry scheduled tasks** — CEIP, Appraiser, WaaSMedic, and others

A live log shows progress as each step completes. This stage takes **10–30 minutes** depending on your disk speed — the WIM dismount near the end is the slowest part, so don't close Winutil while it's running.

---

### Step 4 — Export Your Result

Once modification is complete, choose how to save your image:

{{< tabs items="Save as ISO,Write to USB" defaultIndex="0" >}}

  {{< tab >}}
  1. Click **Save as an ISO File**.
  2. Choose a save location (defaults to your Desktop as `Win11_Modified_yyyyMMdd.iso`).
  3. Winutil builds a dual BIOS/UEFI bootable ISO using `oscdimg.exe`.

  > [!NOTE]
  > `oscdimg.exe` (part of the Windows ADK) is required. If it's not found, Winutil will attempt to install it automatically via winget. If that fails, install it manually: `winget install -e --id Microsoft.OSCDIMG`

  **Typical output size:** 2.5–3.5 GB (down from 5–6 GB original)
  {{< /tab >}}

  {{< tab >}}
  1. Click **Write Directly to a USB Drive**.
  2. Select your USB drive from the dropdown (click **Refresh** if it doesn't appear).
  3. Click **Erase & Write to USB** and confirm the warning — **all data on the drive will be permanently erased**.
  4. Winutil formats the drive as GPT with a 512 MB EFI partition and copies the modified Windows files.

  > [!WARNING]
  > Double-check you have selected the correct drive before confirming. This operation cannot be undone.

  **Minimum USB size:** 8 GB recommended. Writing takes 10–20 minutes.
  {{< /tab >}}

{{< /tabs >}}

---

### Step 5 — Clean Up (Optional)

Click **Clean & Reset** to delete the temporary working directory (~10–15 GB) and reset the tool back to its initial state, ready for a new ISO. You'll be asked to confirm before anything is deleted.

---

### What the Modified ISO Does Differently

When you install Windows 11 from your modified ISO:

- **No Microsoft account required** — create a local account directly during setup
- **No hardware checks** — installs on machines without TPM 2.0, Secure Boot, or supported CPUs
- **Dark mode enabled by default**
- **Empty taskbar and Start Menu** — no pinned apps
- **Windows Update re-enabled automatically** after first login (it's paused during OOBE to prevent interruption)
- **BitLocker disabled**, Recall disabled, desktop shortcuts removed

---

### Troubleshooting

| Problem | Fix |
|---------|-----|
| "install.wim not found" | Not a valid Windows 11 ISO — download a fresh one from Microsoft |
| "oscdimg.exe not found" | Run `winget install -e --id Microsoft.OSCDIMG` then retry |
| USB drive not showing up | Plug it in, wait a few seconds, then click **Refresh** |
| Modification seems stuck | The WIM dismount step is slow — wait at least 10 minutes before assuming it's frozen |
| "Access Denied" error | Make sure Winutil is running as Administrator |

---

A list of the best free and open source tools for downloading, creating and flashing Windows ISOs.

## Download Windows ISOs

| Tool | Description | Website |
|------|-------------|---------|
| **[UUP Dump](https://uupdump.net/)** | Download Windows UUP files directly from Microsoft's servers and convert them into a clean ISO — great for getting the latest builds | [uupdump.net](https://uupdump.net/) |
| **[Microsoft Media Creation Tool](https://www.microsoft.com/en-us/software-download/windows11)** | Microsoft's official tool for downloading and creating Windows 10/11 installation media | [microsoft.com](https://www.microsoft.com/en-us/software-download/windows11) |


## Customize Windows ISOs

| Tool | Description | Website |
|------|-------------|---------|
| **[MicroWin](https://github.com/CodingWonders/microwin)** | A C# desktop app for building stripped-down, customized Windows ISOs — the original predecessor to Winutil's old MicroWin feature | [github.com](https://github.com/CodingWonders/microwin) |
| **[Tiny11 Builder](https://github.com/ntdevlabs/tiny11builder)** | PowerShell script that strips a Windows 11 ISO down to the bare minimum — removes bloatware and bypasses hardware requirements | [github.com](https://github.com/ntdevlabs/tiny11builder) |
| **[NTLite](https://www.ntlite.com/)** | Remove Windows components, integrate drivers and updates, and build a custom ISO before installation | [ntlite.com](https://www.ntlite.com/) |


## Flash ISOs to USB

| Tool | Description | Website |
|------|-------------|---------|
| **[Rufus](https://rufus.ie/)** | The go-to tool for creating bootable Windows USB drives. Supports bypassing Windows 11 TPM/Secure Boot requirements and downloading ISOs directly | [rufus.ie](https://rufus.ie/) |
| **[Ventoy](https://www.ventoy.net/)** | Install once, then just copy any ISO files onto the USB — supports booting multiple ISOs from a single drive without re-flashing | [ventoy.net](https://www.ventoy.net/) |
| **[balenaEtcher](https://etcher.balena.io/)** | Simple, beginner-friendly ISO flasher with a clean interface | [etcher.balena.io](https://etcher.balena.io/) |



---

> [!TIP]
> Already have a Windows 11 ISO? Skip the third-party tools and use Winutil's built-in **[Win11 Creator](#using-winutilss-win11-creator)** at the top of this page.

> [!NOTE]
> Always download Windows ISOs from official Microsoft sources or trusted tools like Rufus/UUP Dump to avoid tampered images.

> [!NOTE]
> Newer Windows 11 ISOs may not boot correctly on older versions of Ventoy — make sure Ventoy is up to date before use. If issues persist after updating, this is a Ventoy compatibility limitation outside of Winutil's control.