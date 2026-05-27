---
title: Win11 Creator
weight: 8
prev: /userguide/automation/
---

## Using Winutil's Win11 Creator

Winutil includes a built-in **Win11 Creator** tool that lets you take an official Windows 11 ISO and produce a customized, debloated version. The resulting image can remove telemetry, bypass hardware requirement checks, and enable local account setup out of the box. You can export the result as a new ISO file or write it directly to a USB drive.

{{< image src="images/win11creator-tab-new" alt="Win11 Creator tab in Winutil" >}}

> [!IMPORTANT]
> You need an **official Windows 11 ISO** from [Microsoft's website](https://www.microsoft.com/en-us/software-download/windows11) before starting. Custom, modified, or non-official ISOs are not supported. The process uses ~10–15 GB of temporary disk space, so make sure you have room.

> [!NOTE]
> This workflow is intended for fresh Windows installs, not in-place upgrades of an existing installation.

---

### Step 1 — Select Your Official Windows 11 ISO

1. Open Winutil and go to the **Win11 Creator** tab.
2. Click **Browse** and select your **official Windows 11 ISO file** from Microsoft.
3. The file path and size will appear on screen once selected.

> [!NOTE]
> Custom or modified ISOs are not supported.

---

### Step 2 — Mount & Verify

1. Click **Mount & Verify ISO**.
2. Winutil mounts the ISO, checks for a valid `install.wim` or `install.esd`, and reads the available editions (Home, Pro, Enterprise, etc.).
3. Once verified, select your desired **edition** from the dropdown — Pro is selected by default if available.

---


### Step 3 — Export Your Result

Once the modification is complete, choose how to save your image:

{{< tabs >}}

  {{< tab name="Save as ISO" selected=true >}}
  1. Click **Save as an ISO File**.
  2. Choose a save location (defaults to your Desktop as `Win11_Modified_yyyyMMdd.iso`).
  3. Winutil builds a dual BIOS/UEFI bootable ISO using `oscdimg.exe`.


  {{< /tab >}}

  {{< tab name="Write to USB" >}}
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

### Step 4 — Clean Up (Optional)

Click **Clean & Reset** to delete the temporary working directory (~10–15 GB) and return the tool to its initial state, ready for a new ISO. You will be asked to confirm before anything is deleted.

---

### What the Modified ISO Does Differently

When you install Windows 11 from your modified ISO:

- **No Microsoft account required** — create a local account directly during setup
- **No hardware checks** — installs on machines without TPM 2.0, Secure Boot, or supported CPUs
- **Dark mode enabled by default**
- **Empty taskbar and Start Menu** — no pinned apps, Chat icon removed

---

## Additional Resources

- Download official Windows 11 media from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11).
- If you prefer to write a finished ISO with another tool, common choices include [Rufus](https://rufus.ie/) or [Ventoy](https://www.ventoy.net/).

> [!NOTE]
> Always download Windows ISOs from official Microsoft sources or trusted tools like Rufus/UUP Dump to avoid tampered images.

> [!NOTE]
> Newer Windows 11 ISOs may not boot correctly on older versions of Ventoy — make sure Ventoy is up to date before use. If issues persist after updating, this is a Ventoy compatibility limitation outside of Winutil's control.
