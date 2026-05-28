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

> [!IMPORTANT]
> An active internet connection is required at first logon so Winutil automation can complete successfully. Internet may also be required during ISO export if `oscdimg.exe` is not already installed.

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

### Step 3 — Run the Modification

Click **Run Windows ISO Modification and Creator** to start the customization process.
Winutil will:

> [!IMPORTANT]
> Keep the PC connected to the internet through first logon so Winutil automation can complete successfully. Internet may also be required during ISO export if `oscdimg.exe` is not already installed.

**ISO Build Actions:**
- **Copy and prepare ISO contents** in a temporary working directory
- **Mount your selected edition** from `install.wim`/`install.esd`
- **Inject `autounattend.xml`** into the ISO root for setup automation
- **Disable hardware checks** — TPM, Secure Boot, CPU requirement checks are disabled during setup
- **Enable local account setup** — skips Microsoft account requirement during OOBE
- **Strip unused editions** — keeps only your selected edition, saving 1-2 GB per removed edition
- **Clean the component store** — runs DISM cleanup (`/StartComponentCleanup /ResetBase`) to reduce image size
- **Remove ISO support files** — deletes the ISO `support` folder

**Post-OOBE Configuration (First Logon):**
- **Run Winutil automation script at first logon** during setup finalization
- **Apply Winutil's advanced preset after installation** during first-logon setup
- **Complete setup with an automatic reboot** into a preconfigured desktop

>[!NOTE]
> To view exactly what advance preset does, see:
https://github.com/ChrisTitusTech/winutil/blob/main/config/preset.json

**Optional: Driver Injection**
- If enabled, it injects drivers from your current system into `install.wim` — useful for offline installations on machines with missing drivers. This is an optional checkbox in Step 3.

---

### Step 4 — Export Your Result

Once the modification is complete, choose how to save your image:

{{< tabs >}}

  {{< tab name="Save as ISO" selected=true >}}
  1. Click **Save as an ISO File**.
  2. Choose a save location (defaults to your Desktop as `Win11_Modified_yyyyMMdd.iso`).
  3. Winutil builds a UEFI bootable ISO.


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

### Step 5 — Clean Up (Optional)

Click **Clean & Reset** to delete the temporary working directory (~10–15 GB) and return the tool to its initial state, ready for a new ISO. You will be asked to confirm before anything is deleted.

---

## Additional Resources

- Download official Windows 11 media from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11).
- If you prefer to write a finished ISO with another tool, common choices include [Rufus](https://rufus.ie/) or [Ventoy](https://www.ventoy.net/).



> [!NOTE]
> Always download Windows ISOs from official Microsoft sources or trusted tools like Rufus/UUP Dump to avoid tampered images.

> [!NOTE]
> Newer Windows 11 ISOs may not boot correctly on older versions of Ventoy — make sure Ventoy is up to date before use. If issues persist after updating, this is a Ventoy compatibility limitation outside of Winutil's control.
