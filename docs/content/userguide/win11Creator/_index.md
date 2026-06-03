---
title: Win11 Creator
weight: 8
prev: /userguide/automation/
---

## Using Winutil's Win11 Creator

Winutil includes a built-in **Win11 Creator** tool that lets you take an official Windows 11 ISO and produce a customized, debloated version. The resulting image can remove telemetry, bypass hardware requirement checks, and enable local account setup out of the box. You can export the result as a new ISO file or write it directly to a USB drive.

{{< image src="images/win11creator-tab-new" alt="Win11 Creator tab in Winutil" >}}

> [!IMPORTANT]
> You need an **official Windows 11 ISO** from [Microsoft's website](https://www.microsoft.com/en-us/software-download/windows11) before starting. Custom, modified, or non-official ISOs are not supported. The process uses ~12 GB of temporary disk space, so make sure you have room.

> [!NOTE]
> This workflow is intended for fresh Windows installs, not in-place upgrades of an existing installation.

---

### Step 1 — Select Your Official Windows 11 ISO

1. Open Winutil and go to the **Win11 Creator** tab.
2. Click **Browse** and select your **Windows 11 ISO file**.
3. The file path and size will appear on screen once selected.

---

### Step 2 — Mount The ISO

1. Click **Mount The ISO**.
2. Winutil mounts the ISO and reads the available editions (Home, Pro, Enterprise, etc.).
3. Optionally, check **Inject current system drivers** to include your current machine's drivers, and choose the specific edition you want to modify.

---

### Step 3 — Build Modified ISO

Click **Run Windows ISO Build** to start the customization process. Winutil will:

* **Inject an `autounattend.xml` file:** Bypasses TPM, Secure Boot, CPU requirements, and Microsoft Account enforcement during the Out-of-Box Experience (OOBE).
* **Configure first logon tasks:** Applies a `firstlogon.ps1` script during setup, which automatically runs the Winutil advanced preset, applies selected toggles, and installs security updates from the Updates tab.

**Optional: Driver Injection**
* If enabled, it injects all drivers from your current system into `install.wim`/`install.esd` and `boot.wim` useful for display drivers and disk drives not showing up on modern laptops

---

### Step 4 — Export Your Result

Once the modification is complete, choose how to save your image:

{{< tabs >}}
  {{< tab name="Save as ISO" selected=true >}}
  1. Click **Save as an ISO File**.
  2. Choose a save location (defaults to your Documents folder as `Win11Creator.iso`).
  3. Winutil builds a UEFI-bootable ISO using native PowerShell/C# code.
  {{< /tab >}}

  {{< tab name="Write to USB" >}}
  1. Click **Write Directly to a USB Drive**.
  2. Select your USB drive from the dropdown menu (click **Refresh** if it doesn't appear).
  3. Click **Erase & Write to USB** and confirm the warning—**all data on the drive will be permanently erased**.
  4. Winutil formats the drive as GPT with a 512 MB EFI partition and copies the modified Windows files.

  > [!WARNING]
  > Double-check that you have selected the correct drive before confirming. This operation cannot be undone.

  **Minimum USB size:** 8 GB recommended.
  {{< /tab >}}
{{< /tabs >}}

---

### Step 5 — Clean Up (Optional)

Click **Clean & Reset** to delete the temporary working directory and return the tool to its initial state, ready for a new ISO creation.

---

## Additional Resources

* Download official Windows 11 media from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11).
* If you prefer to write a finished ISO using another utility, popular choices include [Rufus](https://rufus.ie/) or [Ventoy](https://www.net/net/).
