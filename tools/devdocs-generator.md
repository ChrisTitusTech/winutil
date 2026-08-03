---
title: "Dev Docs Generator"
description: "How the devdocs-generator.ps1 script works"
---

# Dev Docs Generator

The `devdocs-generator.ps1` script automatically generates Astro/Starlight markdown (`.mdx`) files for the development documentation. It pulls content directly from the JSON config files and PowerShell function files so the docs never go out of sync.

## When Does it Run?

- Automatically runs as part of the `pre-release.yaml` GitHub Actions workflow (manually triggered via `workflow_dispatch`), which regenerates the `.mdx` files and updates the `"link"` properties in the JSON config files
- `pre-release.yaml` then opens a `docs-update` pull request with those changes; `auto-merge-docs.yaml` auto-approves and merges it into `main`
- That merge pushes changes under `docs/**`, which triggers `docs.yaml` — but `docs.yaml` only builds and deploys the Astro site, it does not run the generator itself
- Can also be run manually/locally from `tools/` (`./devdocs-generator.ps1`)

## What Does It Do?

### 1. Loads the Data

- Reads `config/tweaks.json` and `config/feature.json`
- Reads all `.ps1` function files from `functions/public/` and `functions/private/`
- Parses `Invoke-WPFButton.ps1` to build a mapping of button names to their function names

### 2. Updates Links in JSON

- Adds or updates a `"link"` property on every entry in both JSON config files
- Each link points to that entry's documentation page on the Astro/Starlight site
- The updated links are automatically committed back to the JSON config files as part of the pre-release workflow

### 3. Cleans Up Old Docs

- Deletes all `.mdx` files from `docs/src/content/docs/code-reference/tweaks/` and `docs/src/content/docs/code-reference/features/`
- This prevents duplicate or orphaned files from previous runs
- No category `index.mdx` landing pages exist yet; if one is added later, the matching exclusion in the script is left commented out ready to re-enable

### 4. Generates Tweak Documentation

For each entry in `tweaks.json` that belongs to a documented category:

- **Button type** entries get the mapped PowerShell function file embedded
- **All other types** get the raw JSON snippet embedded with correct line numbers from the source file
- Entries with **registry changes** get a Registry Changes section added

### 5. Generates Feature Documentation

For each entry in `feature.json` that belongs to a documented category:

- **Fixes and Legacy Windows Panels** get the mapped PowerShell function file embedded
- **Features** get the raw JSON snippet embedded with correct line numbers

### 6. Output Format

- Every `.mdx` file gets Starlight frontmatter with `title` and `description` (description comes from the entry's `Description` field when present)
- A `:::note` aside points back at the source file (JSON config or PowerShell function) it was generated from
- Code blocks use Starlight/Expressive Code syntax with a `title` attribute naming the source file
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
docs/src/content/docs/code-reference/
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

The Starlight sidebar picks these up automatically via `autogenerate` entries in `docs/astro.config.mjs` for the `code-reference/tweaks` and `code-reference/features` directories, so no sidebar edits are needed when new entries are added.

## How File Names Are Derived

The script strips common prefixes from the JSON key names using the pattern `WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?`. For example:

| JSON Key            | Generated File |
| ------------------- | -------------- |
| `WPFTweaksHiber`    | `Hiber.mdx`     |
| `WPFTweaksDeBloat`  | `DeBloat.mdx`   |
| `WPFFeatureshyperv` | `hyperv.mdx`    |
| `WPFPanelDISM`      | `DISM.mdx`      |

## Key Points

- The JSON config files are the single source of truth
- Manual edits to generated `.mdx` files will be overwritten on the next run
- The script only touches `docs/src/content/docs/code-reference/tweaks/` and `.../features/` — `architecture.mdx` and any other hand-written page under `code-reference/` are untouched
  — if a category `index.mdx` landing page is added inside `tweaks/` or `features/`, uncomment the exclusion in the cleanup step first, or it will be deleted on the next run
- Category directories are created automatically if they don't exist
- The `"link"` property added to JSON entries is excluded from the displayed code blocks
- The `pre-release` workflow generates both the `.mdx` files and the `"link"` properties, and commits them back to the repo via the `docs-update` PR
- The `docs` workflow never runs the generator — it only builds and deploys the already-committed Astro site
