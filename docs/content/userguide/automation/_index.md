---
title: Automation
weight: 7
---

Use Automation to run Winutil from an exported configuration file.

To create a config file:

1. Open Winutil.
2. Click the gear icon in the top-right corner.
3. Choose **Export**.
4. Save the exported JSON file.

Once you have exported a config, launch Winutil with it using this command:
```powershell
& ([ScriptBlock]::Create((irm "https://christitus.com/win"))) -Config "C:\Path\To\Config.json" -Run
```

This is useful for:

- Applying the same Winutil configuration across multiple Windows 11 PCs
- Reusing a known-good baseline after reinstalling Windows
- Standardizing deployments for labs, workstations, or personal setups

> [!NOTE]
> Run the command in an elevated PowerShell session so Winutil can apply system-level changes.
