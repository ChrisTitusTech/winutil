---
title: Architecture & Design
weight: 1
toc: true
---

## Overview

Winutil is a PowerShell-based Windows utility with a WPF (Windows Presentation Foundation) GUI. This document explains the architecture, code structure, and how different components work together.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Winutil GUI                      │
│              (WPF XAML Interface)                   │
└──────────────────┬──────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
┌────────▼──────┐   ┌───────▼────────┐
│  Public APIs  │   │  Private APIs  │
│  (User-facing)│   │   (Internal)   │
└───────┬───────┘   └───────┬────────┘
        │                   │
        └────────┬──────────┘
                 │
    ┌────────────▼────────────┐
    │   Configuration Files   │
    │  (JSON definitions)     │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │   External Tools        │
    │  (WinGet, Chocolatey)   │
    └─────────────────────────┘
```

## Project Structure

### Directory Layout

```
winutil/
├── Compile.ps1                 # Build script that combines all files
├── winutil.ps1                 # Compiled output (generated)
├── scripts/
│   ├── main.ps1               # Entry point and GUI initialization
│   └── start.ps1              # Startup logic
├── functions/
│   ├── private/               # Internal helper functions
│   │   ├── Get-WinUtilVariables.ps1
│   │   ├── Install-WinUtilWinget.ps1
│   │   └── ...
│   ├── public/                # User-facing functions
│   │   ├── Initialize-WPFUI.ps1
│   │   └── ...
├── config/                    # JSON configuration files
│   ├── applications.json      # Application definitions
│   ├── tweaks.json           # Tweak definitions
│   ├── feature.json          # Windows feature definitions
│   └── preset.json           # Preset configurations
├── xaml/
│   └── inputXML.xaml         # GUI layout definition
└── docs/                     # Documentation
```

### Key Components

#### 1. Compile.ps1
**Purpose**: Combines all separate script files into a single `winutil.ps1` for distribution.

**Process**:
1. Reads all function files from `/functions/`
2. Includes configuration JSON files
3. Embeds XAML GUI definition
4. Combines into single script
5. Outputs `winutil.ps1`

**Why**: Makes distribution easier (single file) and improves load time.

#### 2. scripts/main.ps1
**Purpose**: Entry point that initializes the GUI and event system.

**Responsibilities**:
- Load XAML and create WPF window
- Initialize form elements
- Set up event handlers
- Load configurations
- Display the GUI

#### 3. functions/public/
**Purpose**: User-facing functions that implement main features.

**Key Functions**:
- `Initialize-WPFUI.ps1`: Sets up the GUI
- `Invoke-WPFTweak*`: Applies system tweaks
- `Invoke-WPFFeature*`: Enables Windows features
- `Install-WinUtilProgram*`: Installs applications

**Naming Convention**: Functions start with `WPF` or `Winutil` to be loaded into the runspace.

#### 4. functions/private/
**Purpose**: Internal helper functions not directly called by users.

**Key Functions**:
- `Get-WinUtilVariables.ps1`: Retrieves UI element references
- `Install-WinUtilWinget.ps1`: Ensures WinGet is installed
- `Get-WinUtilCheckBoxes.ps1`: Gets checkbox states
- `Invoke-WinUtilCurrentSystem.ps1`: Gets system information

#### 5. config/*.json
**Purpose**: Define available applications, tweaks, and features declaratively.

**Files**:
- `applications.json`: Application definitions with WinGet/Choco IDs
- `tweaks.json`: Registry tweaks and their undo actions
- `feature.json`: Windows features that can be enabled/disabled
- `preset.json`: Predefined tweak combinations
- `dns.json`: DNS provider configurations

#### 6. xaml/inputXML.xaml
**Purpose**: WPF GUI layout and design.

**Structure**:
- Buttons with event handlers
- TextBoxes for input
- CheckBoxes for options
- ListBoxes for selections

# Win11 Creator Architecture

A specialized subsystem within WinUtil that creates customized, debloated Windows 11 ISOs with automated setup. Operates independently from the main package installation and tweak system.

---

## Core Functions

All functions live in `functions/private/Invoke-WinUtilISO.ps1`.

### `Write-Win11ISOLog`
Thread-safe logging helper. Appends timestamped messages to the status log TextBox via Dispatcher.Invoke, ensuring UI updates from background runspaces are safe.

### `Invoke-WinUtilRunspace`
Generic runspace factory. Creates an STA runspace, injects the `$sync` hashtable, `$winutildir`, and the log function definition as a string (so it can be dot-sourced in the child runspace), then starts the script asynchronously via `BeginInvoke`.

### `Invoke-WinUtilISOBrowse`
Opens an OpenFileDialog filtered to `.iso` files. On confirmation, populates the path field, shows the file size, and reveals the Mount section. Resets downstream UI sections (verify, modify, output) to collapsed.

### `Invoke-WinUtilISOMount`
Runs in a background runspace. Mounts the ISO via `Mount-DiskImage`, resolves the drive letter, detects whether the image file is `install.wim` or `install.esd`, and enumerates all editions via `Get-WindowsImage`. Stores results in `$sync` and populates the edition ComboBox, auto-selecting Windows 11 Pro if present.

### `Invoke-WinUtilISOModify`
The main modification pipeline. Runs in a background runspace with these steps in order:

1. Creates the working directory at `$winutildir\Win11Creator\iso_contents`
2. Copies all ISO contents from the mounted drive letter to disk
3. Dismounts the source ISO
4. Writes `autounattend.xml` to the ISO root
5. Deletes the `\support` folder (removes telemetry components)
6. Optionally injects drivers (see Driver Injection below)
7. Exports only the selected edition via `Export-WindowsImage`, removing all others
8. Renames the exported WIM back to `install.wim`
9. Stores the contents directory in `$sync` and reveals the Output section

### `Invoke-WinUtilISOExport`
Opens a SaveFileDialog defaulting to `Win11Creator.iso`. Downloads `oscdimg.exe` from Microsoft's symbol server at runtime and uses it to build a UEFI-bootable ISO from the modified contents directory, using `efisys.bin` as the boot sector.

### `Invoke-WinUtilISOCheckExistingWork`
Called on tab load. Checks if `$winutildir\Win11Creator\iso_contents` exists on disk from a previous session. If so, restores the UI directly to Step 4 (output) without requiring Steps 1–3 to be re-run.

### `Invoke-WinUtilISOCleanAndReset`
Cleanup function. Dismounts any mounted Windows images and the source ISO, deletes the `Win11Creator` and `Driver` working directories, clears all `$sync` state keys, and resets the UI to its initial state.

---

## Data Flow

```
[Step 1] User selects ISO
    Invoke-WinUtilISOBrowse
    └─ OpenFileDialog → populate path, show file size, reveal Mount section

[Step 2] Mount & Inspect
    Invoke-WinUtilISOMount  (background runspace)
    ├─ Mount-DiskImage → resolve drive letter
    ├─ Detect install.wim or install.esd
    ├─ Get-WindowsImage → enumerate editions
    └─ Populate ComboBox, auto-select Pro, reveal Modify section
        $sync keys set: Win11ISOImagePath, Win11ISODriveLetter,
                        Win11ISOWimPath, Win11ISOImageInfo

[Step 3] Modify
    Invoke-WinUtilISOModify  (background runspace)
    ├─ Create $winutildir\Win11Creator\iso_contents
    ├─ Copy-Item from drive letter → iso_contents
    ├─ Dismount source ISO
    ├─ Write autounattend.xml → iso root
    ├─ Remove \support folder
    ├─ [optional] Driver injection (see below)
    ├─ Export-WindowsImage → single edition install.wim
    └─ Reveal Output section
        $sync key set: Win11ISOContentsDir

[Step 4] Export
    Invoke-WinUtilISOExport
    ├─ SaveFileDialog → output path
    ├─ Download oscdimg.exe from msdl.microsoft.com
    └─ Build bootable ISO: oscdimg -o -u2 -b<efisys.bin> <contentsDir> <output>

[Optional] Clean & Reset
    Invoke-WinUtilISOCleanAndReset
    ├─ Dismount-WindowsImage (all mounted)
    ├─ Dismount-DiskImage (source ISO)
    ├─ Remove-Item Win11Creator\ and Driver\
    └─ Reset all $sync state and UI
```

---

## Driver Injection (Optional)

When the "Inject Drivers" checkbox is enabled, the modify step performs additional operations before the WIM export:

1. `Export-WindowsDriver -Online` — exports all drivers from the currently running system to `$winutildir\Driver`
2. Mounts `install.wim` at the selected index → `Add-WindowsDriver` recursively → saves and dismounts
3. Mounts `boot.wim` Index 1 → injects drivers → saves
4. Mounts `boot.wim` Index 2 → injects drivers → saves
5. Deletes the exported driver staging directory

This ensures the target system can boot into Windows PE and complete installation without missing drivers.

---

## autounattend.xml

Injected into the ISO root during Step 3. Applied automatically by Windows Setup on boot.

### windowsPE pass
Hardware requirement bypasses applied via synchronous registry commands during setup:

| Registry Value | Purpose |
|---|---|
| `BypassTPMCheck` | Skip TPM 2.0 requirement |
| `BypassSecureBootCheck` | Skip Secure Boot requirement |
| `BypassCPUCheck` | Skip CPU compatibility check |
| `BypassRAMCheck` | Skip RAM minimum check |
| `BypassStorageCheck` | Skip storage size check |

All written to `HKLM\SYSTEM\Setup\LabConfig`.

### specialize pass
Deletes the `wuauserv` ImagePath registry value, disabling Windows Update during setup to prevent driver or update interference before first logon.

### oobeSystem pass
Configures out-of-box experience:

- `HideEULAPage` — skips license agreement screen
- `HideOnlineAccountScreens` — enables local account creation without a Microsoft account
- `HideOEMRegistrationScreen` — skips OEM registration
- `ProtectYourPC: 3` — disables automatic protection settings

Runs `FirstLogon.ps1` as the first synchronous command at first user logon (see First Logon Script below).

---

## First Logon Script (`FirstLogon.ps1`)

Downloaded and executed at first logon via `Invoke-RestMethod | Invoke-Expression`. Applies system configuration after setup completes.

### App Removal
- Removes MSTeams via `Remove-AppxPackage -AllUsers`
- Schedules OneDrive uninstall via `RunOnce`

### Taskbar & Explorer
- Clears taskbar pins via RunOnce (deletes `Taskband` registry key, restarts Explorer)
- Disables Task View button (`ShowTaskViewButton = 0`)
- Shows file extensions (`HideFileExt = 0`)
- Sets Explorer default location to This PC (`LaunchTo = 1`)
- Left-aligns taskbar (`TaskbarAl = 0`)
- Hides search box (`SearchboxTaskbarMode = 0`)

### Visual Settings
- Sets wallpaper to `img19.jpg` (default dark wallpaper)
- Enables dark mode for apps and system (`AppsUseLightTheme = 0`, `SystemUsesLightTheme = 0`)
- Clears Start Menu pins by replacing `start2.bin` from Win11Debloat

### Start Menu
- Hides Recommended section via three registry paths:
  - `PolicyManager\current\device\Education` — `IsEducationEnvironment = 1`
  - `Policies\Microsoft\Windows\Explorer` — `HideRecommendedSection = 1`
  - `PolicyManager\current\device\Start` — `HideRecommendedSection = 1`

### Windows Update Policy
- Disables auto-update (`NoAutoUpdate = 1`)
- Excludes drivers from quality updates (`ExcludeWUDriversInQualityUpdate = 1`)
- Defers feature updates 365 days
- Defers quality updates 4 days
- Re-enables the `wuauserv` service ImagePath (was deleted during specialize pass; security updates are still delivered manually)

### Cleanup
- Removes Microsoft Edge desktop shortcut
- Removes `Windows.old` if empty
- Restarts the computer

---

## Work Session Recovery

On tab load, `Invoke-WinUtilISOCheckExistingWork` checks for an existing `iso_contents` directory. If found, it skips Steps 1–3 and restores the UI to Step 4 directly. This allows export to continue after an application restart without re-running the full modification pipeline.

To start over, click **Clean & Reset** which runs `Invoke-WinUtilISOCleanAndReset`.

---

## $sync State Keys

| Key | Set by | Contains |
|---|---|---|
| `Win11ISOImagePath` | Mount | Path to source `.iso` file |
| `Win11ISODriveLetter` | Mount | Drive letter of mounted ISO (e.g. `D:`) |
| `Win11ISOWimPath` | Mount | Full path to `install.wim` or `install.esd` on mounted drive |
| `Win11ISOImageInfo` | Mount | Array of `{ImageIndex, ImageName}` objects |
| `Win11ISOContentsDir` | Modify | Path to `iso_contents` working directory |
| `Win11ISOModifying` | Modify | Boolean flag preventing concurrent modifications |
| `Win11ISOUSBDisks` | USB flow | Available USB disk list |

---

## Disk Space Requirements

Ensure at least **15 GB of free storage** before starting. The working directory at `$winutildir\Win11Creator` holds a full copy of the ISO contents plus mounted WIM images during driver injection.

## Data Flow

### Application Installation Flow

```
User clicks "Install"
    ↓
Get-WinUtilCheckBoxes → Retrieves selected apps
    ↓
For each selected app:
    ↓
Check if WinGet/Choco is installed
    ↓
Install-WinUtilWinget/Choco (if needed)
    ↓
Install-WinUtilProgramWinget/Choco → Install app
    ↓
Update UI with progress
    ↓
Display completion message
```

### Tweak Application Flow

```
User selects tweaks and clicks "Run Tweaks"
    ↓
Get-WinUtilCheckBoxes → Get selected tweaks
    ↓
For each selected tweak:
    ↓
Load tweak definition from tweaks.json
    ↓
Invoke-WPFTweak → Apply registry/service changes
    ↓
Log changes
    ↓
Store original values (for undo)
    ↓
Update UI
    ↓
Display completion
```

### Undo Tweak Flow

```
User selects tweaks and clicks "Undo"
    ↓
Get-WinUtilCheckBoxes → Get selected tweaks
    ↓
For each tweak:
    ↓
Retrieve "OriginalState" from tweak definition
    ↓
Invoke-WPFUndoTweak → Restore original values
    ↓
Remove from the applied tweaks log
    ↓
Update UI
```

## Configuration File Format

### applications.json Structure

```json {filename="config/applications.json"}
{
  "WPFInstall<AppName>": {
    "category": "Browsers",
    "choco": "googlechrome",
    "content": "Google Chrome",
    "description": "Google Chrome browser",
    "link": "https://chrome.google.com",
    "winget": "Google.Chrome"
  }
}
```

**Fields**:
- `category`: Which section in the Install tab
- `content`: Display name in GUI
- `description`: Tooltip/description text
- `winget`: WinGet package ID
- `choco`: Chocolatey package name
- `link`: Official website

### tweaks.json Structure

```json {filename="config/tweaks.json"}
{
  "WPFTweaksTelemetry": {
    "Content": "Disable Telemetry",
    "Description": "Disables Microsoft Telemetry",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
        "Name": "AllowTelemetry",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  }
}
```

**Fields**:
- `Content`: Display name
- `Description`: What it does
- `category`: Essential/Advanced/Customize
- `registry`: Registry changes to make
- `service`: Services to change
- `OriginalValue/State`: For undo functionality

## PowerShell Runspace

Winutil uses PowerShell runspaces for the GUI to remain responsive:

```powershell
# Create runspace
$sync.runspace = [runspacefactory]::CreateRunspace()
$sync.runspace.Open()
$sync.runspace.SessionStateProxy.SetVariable("sync", $sync)

# Run code in background
$powershell = [powershell]::Create().AddScript($scriptblock)
$powershell.Runspace = $sync.runspace
$handle = $powershell.BeginInvoke()
```

**Why**: Prevents UI freezing during long-running operations.

## WPF Event Handling

Events are wired up via XAML element names:

```powershell
# Get all named elements
$sync.keys | ForEach-Object {
    if($sync.$_.GetType().Name -eq "Button") {
        $sync.$_.Add_Click({
            $button = $sync.$($args[0].Name)
            & "Invoke-$($args[0].Name)"
        })
    }
}
```

**Convention**: Button named `WPFInstallButton` calls function `Invoke-WPFInstallButton`.

## Package Manager Integration

### WinGet Integration

```powershell
# Check if installed
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Install-WinUtilWinget
}

# Install package
winget install --id $app.winget --silent --accept-source-agreements
```

### Chocolatey Integration

```powershell
# Check if installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Install-WinUtilChoco
}

# Install package
choco install $app.choco -y
```

## Error Handling

Winutil uses PowerShell error handling:

```powershell
try {
    # Attempt operation
    Invoke-SomeOperation
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    # Log error
    Add-Content -Path $logfile -Value "ERROR: $_"
}
```

**Logging**: Errors and operations are logged for debugging.

## Configuration Loading

At startup, Winutil loads all configurations:

```powershell
# Load JSON configs
$sync.configs = @{}
$sync.configs.applications = Get-Content "config/applications.json" | ConvertFrom-Json
$sync.configs.tweaks = Get-Content "config/tweaks.json" | ConvertFrom-Json
$sync.configs.features = Get-Content "config/feature.json" | ConvertFrom-Json
```

**Sync Hash**: `$sync` hashtable shares state across runspaces.

## UI Update Pattern

UI updates must happen on the UI thread:

```powershell
$sync.form.Dispatcher.Invoke([action]{
    $sync.WPFStatusLabel.Content = "Installing..."
}, "Normal")
```

**Why**: WPF requires UI updates on the main thread.

## Adding New Features

### Adding a New Application

1. Edit `config/applications.json`:
```json {filename="config/applications.json"}
{
  "WPFInstallNewApp": {
    "category": "Utilities",
    "content": "New App",
    "description": "Description of new app",
    "winget": "Publisher.AppName",
    "choco": "appname"
  }
}
```

2. Recompile: `.\Compile.ps1`
3. The app appears automatically in the Install tab

### Adding a New Tweak

1. Edit `config/tweaks.json`:
```json {filename="config/tweaks.json"}
{
  "WPFTweaksNewTweak": {
    "Content": "New Tweak",
    "Description": "What it does",
    "category": "Essential Tweaks",
    "registry": [
      {
        "Path": "HKLM:\\Path\\To\\Key",
        "Name": "ValueName",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "0"
      }
    ]
  }
}
```

2. Recompile: `.\Compile.ps1`
3. Tweak appears in the Tweaks tab

### Adding a New Function

1. Create file in `functions/public/` or `functions/private/`:
```powershell
# functions/public/Invoke-WPFNewFeature.ps1
function Invoke-WPFNewFeature {
    <#
    .SYNOPSIS
    Does something new
    #>
    # Implementation
}
```

2. File naming must include "WPF" or "Winutil" to load
3. Recompile: `.\Compile.ps1`

## Testing

### Manual Testing

```powershell
# Compile and run with -run flag
.\Compile.ps1 -run
```

### Automated Tests

Tests are in `/pester/`:
- `configs.Tests.ps1`: Validates JSON configurations
- `functions.Tests.ps1`: Tests PowerShell functions

Run tests:
```powershell
Invoke-Pester
```

## Build Process

### Development Build

```powershell
.\Compile.ps1
```

Outputs `winutil.ps1` in the root directory.

### Production Release

1. Tag release in Git
2. GitHub Actions builds and uploads `winutil.ps1`
3. Release appears on GitHub Releases
4. Users download via `irm christitus.com/win`

## Dependencies

**Required**:
- PowerShell 5.1+
- .NET Framework 4.5+
- Windows 11

**Optional (auto-installed)**:
- WinGet (Windows Package Manager)
- Chocolatey

## Performance Considerations

**Optimization Strategies**:
- Lazy-load configurations (only when needed)
- Use runspaces for long operations
- Cache expensive lookups
- Minimize registry reads/writes
- Batch operations when possible

## Security Considerations

**Safety Measures**:
- All operations logged
- Registry backups for undo
- No credential storage
- Open source (auditable)
- Digitally signed (future)

## Contributing Guidelines

**Code Standards**:
- Use proper PowerShell cmdlet naming (Verb-Noun)
- Include comment-based help
- Follow existing code style
- Test thoroughly before PR
- Document significant changes

**File Naming**:
- Public functions: `Invoke-WPF*.ps1` or `Invoke-Winutil*.ps1`
- Private functions: `Get-WinUtil*.ps1` or verb-WinUtil*.ps1`
- Must include "WPF" or "Winutil" to load

## Future Architecture Plans

**Roadmap Considerations**:
- Plugin system for community extensions
- Config import/export
- Cloud sync for configurations
- Enhanced logging dashboard
- Modular compilation (choose features)

## Related Documentation

- [Contributing Guide](../../contributing/) - How to contribute code
- [User Guide](../../userguide/) - End-user documentation
- [Win11 Creator Guide](../../userguide/win11creator/) - Building customized Windows 11 ISOs
- [FAQ](../../faq/) - Common questions

## Additional Resources

- **GitHub Repository**: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil)
- **PowerShell Docs**: [Microsoft Docs](https://docs.microsoft.com/powershell/)
- **WPF Guide**: [WPF Documentation](https://docs.microsoft.com/dotnet/desktop/wpf/)

---

**Last Updated**: January 2026
**Maintainers**: Chris Titus Tech and contributors
