---
title: "Dev Docs Generator"
description: "How the devdocs-generator.ps1 script works"
---

# Dev Docs Generator

The `devdocs-generator.ps1` script automatically generates Hugo-compatible markdown files for the development documentation. It pulls content directly from the JSON config files and PowerShell function files so the docs never go out of sync.

## When Does it Run?

- Automatically triggered by the `docs.yaml` GitHub Actions workflow, which generates the `.md` files, commits them back to the repo, and then triggers Hugo to build the site
- Automatically runs during the pre-release workflow, committing the updated `"link"` properties back to the JSON config files
- Watches `docs/**`, `config/tweaks.json`, `config/feature.json`, and `functions/**` for changes
- Supports manual runs via `workflow_dispatch`

## What Does It Do?

### 1. Loads the Data

- Reads `config/tweaks.json` and `config/feature.json`
- Reads all `.ps1` function files from `functions/public/` and `functions/private/`
- Parses `Invoke-WPFButton.ps1` to build a mapping of button names to their function names

### 2. Updates Links in JSON

- Adds or updates a `"link"` property on every entry in both JSON config files
- Each link points to that entry's documentation page on the Hugo site
- The updated links are automatically committed back to the JSON config files as part of the pre-release workflow

### 3. Cleans Up Old Docs

- Deletes all `.md` files (except `_index.md`) from `docs/content/dev/tweaks/` and `docs/content/dev/features/`
- This prevents duplicate or orphaned files from previous runs

### 4. Generates Tweak Documentation

For each entry in `tweaks.json` that belongs to a documented category:

- **Button type** entries get the mapped PowerShell function file embedded
- **All other types** get the raw JSON snippet embedded with correct line numbers from the source file
- Entries with **registry changes** get a Registry Changes section added
- Entries with **services** get the `Set-WinUtilService.ps1` function appended

### 5. Generates Feature Documentation

For each entry in `feature.json` that belongs to a documented category:

- **Fixes and Legacy Windows Panels** get the mapped PowerShell function file embedded
- **Features** get the raw JSON snippet embedded with correct line numbers

### 6. Output Format

- Every `.md` file gets Hugo frontmatter with `title` and `description`
- Code blocks use Hugo syntax with filename labels and line numbers
- Files are organized into category subdirectories matching the JSON `category` field

## Documented Categories

The script generates docs for entries in these categories:

- Essential Tweaks
- z--Advanced-Tweaks---CAUTION
- Customize Preferences
- Performance Plans
- Features
- Fixes
- Legacy Windows Panels

## File Structure

```
docs/content/dev/
  tweaks/
    Essential-Tweaks/
    z--Advanced-Tweaks---CAUTION/
    Customize-Preferences/
    Performance-Plans/
  features/
    Features/
    Fixes/
    Legacy-Windows-Panels/
```

## How File Names Are Derived

The script strips common prefixes from the JSON key names using the pattern `WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?`. For example:

| JSON Key            | Generated File |
| ------------------- | -------------- |
| `WPFTweaksHiber`    | `Hiber.md`     |
| `WPFTweaksDeBloat`  | `DeBloat.md`   |
| `WPFFeatureshyperv` | `hyperv.md`    |
| `WPFPanelDISM`      | `DISM.md`      |

## Key Points

- The JSON config files are the single source of truth
- Manual edits to generated `.md` files will be overwritten on the next run
- The script does not modify `_index.md` or `architecture.md`
  — do not delete `_index.md` or `architecture.md`, as they will need to be recreated manually.
- Category directories are created automatically if they don't exist
- The `"link"` property added to JSON entries is excluded from the displayed code blocks
- The `docs` workflow generates the `.md` files and commits them back to the repo before Hugo builds the site
- The `pre-release` workflow generates the `"link"` properties and commits them back to the repo
