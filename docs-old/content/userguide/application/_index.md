---
title: Applications
weight: 3
prev: /userguide/getting-started/
next: /userguide/tweaks/
---

Use the Applications tab to install, upgrade, uninstall, and review supported apps from one place. WinUtil relies on package manager support for these actions, so the available results depend on what WinGet can detect and manage on your system.

{{< tabs >}}

  {{< tab name="Installation & Updates" selected=true >}}
    * Choose the applications you want to install or upgrade.
        * For programs not currently installed, this action will install them.
        * For programs already installed, this action will update them to the latest version.
    * Click the `Install/Upgrade Selected` button to start the installation or upgrade process.

    {{< image src="images/install-pics/installation" alt="Install or upgrade selected applications" >}}
  {{< /tab >}}

  {{< tab name="Upgrade All" >}}
    * Simply press the `Upgrade All` button.
    * This upgrades every supported installed program without individual selection.

    {{< image src="images/install-pics/install-apps" alt="Upgrade all applications" >}}
  {{< /tab >}}

  {{< tab name="Uninstall" >}}
    * Select the programs you wish to uninstall.
    * Click the `Uninstall Selected` button to remove them.

    {{< image src="images/install-pics/uninstall-apps" alt="Uninstall selected applications" >}}
  {{< /tab >}}

  {{< tab name="Show Installed Apps" >}}
    * Click the `Show Installed Apps` button.
    * This scans for and selects installed applications supported by WinGet.

    {{< image src="images/install-pics/show-installed-apps" alt="Show installed apps" >}}
  {{< /tab >}}

  {{< tab name="Clear Selection" >}}
    * Click the `Clear Selection` button.
    * This clears all current selections.

    {{< image src="images/install-pics/clear-selection-apps" alt="Clear app selections" >}}
  {{< /tab >}}
{{< /tabs >}}

> [!TIP]
> If you have trouble finding an application, press `Ctrl + F` and search for its name. The list filters as you type.

> [!NOTE]
> `Show Installed Apps` only selects software that WinGet can identify. Apps installed outside supported package sources may not appear.

> [!IMPORTANT]
> Before uninstalling or upgrading apps, close any running programs first. Some packages may still prompt for input or fail if their source is unavailable.
