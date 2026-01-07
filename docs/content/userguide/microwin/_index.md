---
title: Microwin
weight: 6
---

MicroWin is our in-house solution for customized and debloated Windows images. With MicroWin, you can create images that have minimal bloat and no interruptions. This has an upside: you can get more done and use Windows the way **you** want.

Due to MicroWin using standard Windows system administration tools, such as DISM (Deployment Image Servicing and Management), advanced Windows users (system administrators and tech enthusiasts) can continue making changes so that they can have their own set of customizations with their ISO files.

If you're excited to try this out, let's go through how to use it. You'll be done in a short time!

## Basic usage

To start with MicroWin, go to its tab. You will see the following:

{{< image src="images/microwin/microwin-screen" >}}

From this screen, you'll have to do one of the following:

- **Select the ISO file:** if you have already downloaded a Windows ISO file, select it and click OK
- **Get an ISO file automatically:** if you don't have an ISO file ready, and don't want to waste time going to the download page, you can grab the latest versions of Windows easily. Select your preferred version and the language of the ISO file, and its destination, and you will have an ISO file in no time.

{{< image src="images/microwin/microwin-downloader" >}}

> [!NOTE]
When downloading your ISO file, network conditions (such as speed and location) can affect the time you have to wait for the download to complete and the availability of such download.

### Compatibility

You may be wondering if your Windows image is compatible with the MicroWin process. Because of this, we present to you a compatibility list:

| Version | Compatible? |
|:--|:--|
| Windows 7 | ❌ Not supported |
| Windows 8 | ❌ Not supported |
| Windows 8.1 | ❌ Not supported |
| Windows 10 | ℹ️ Only the latest versions are supported, and you will not get the full experience |
| Windows 11 | 👍 Supported (21H2-24H2) |

After getting information about your ISO file, you will see the following screen:

{{< image src="images/microwin/microwin-screen-full" >}}

### Requirements

To successfully use MicroWin with your Windows image, you need the following:

- **The latest versions of Windows 10, or Windows 11**
- **Enough space**. We recommend having, at least, double the size of your ISO file. However, you may need more if you want to inject drivers

## Options

### Choosing your index

By default, MicroWin will target the Pro edition of Windows. The Pro edition is a good baseline for IT administrators **and** end-users, due to the inclusion of Group Policy, the ability to join domains, and more things that you can't find with the Home edition. For more information, check out [this comparison chart](https://en.wikipedia.org/wiki/Windows_10_editions#Comparison_chart).

Obviously, you should pick the edition of Windows for which you have a license. To change the edition to process, select the drop-down menu under "Choose Windows SKU" and select your edition.

{{< image src="images/microwin/microwin-skuselect" >}}

### Injecting drivers

If you want to use MicroWin on a real system, you may want to include the drivers for it, to avoid setting them up after OS installation. That's where the options to inject drivers come in handy.

- **Injecting drivers:** if you want to install MicroWin on another system, simply check this option. Prepare a folder with the drivers of your system and specify it in the UI. To learn more about how to export the drivers, read the section "Exporting drivers"
- **Importing drivers:** if you want to install MicroWin on **your** system, you can apply the drivers of your system to the image by importing them. Combine that with the former option, and you can have your driver files stored permanently on your preferred location
- **Injecting VirtIO drivers:** if you plan on using the target Windows image with QEMU/Proxmox VE, or any UI that uses it (like `virt-manager` on Linux), you can automatically download the VirtIO driver ISO and put its contents into your ISO file

> [!NOTE]
Injecting VirtIO drivers is only supported on v25.01.11 and later

Of course, you can continue without setting up drivers. Simply leave the options blank and continue with the process.

#### How do I export drivers?

To export the drivers, you can do the following on many utilities:

##### DISM

To export the drivers using DISM (via the command-line), do the following:

1. Launch the command-line interpreter you want (`cmd`, PowerShell...) **as an administrator**
2. Go to where you want to place the drivers with `cd`, and create a directory called "drivers" (`md drivers`)
3. Run the following command: `dism /online /export-driver /destination="<path-to-folder>"`
4. Wait for the drivers to be exported

##### Driver Store Explorer (RAPR)

To export the drivers using [Driver Store Explorer (RAPR)](https://github.com/lostindark/DriverStoreExplorer/), do the following:

1. Go to "File > Export All Drivers"

{{< image src="images/microwin/rapr_menu" >}}

2. Choose the folder to export all the drivers to and click OK

{{< image src="images/microwin/rapr_folderpicker" >}}

##### DISM++

To export the drivers using [DISM++](https://github.com/Chuyu-Team/Dism-Multi-language), do the following:

1. Select your active installation if you haven't (it's the first item)
2. Go to "Drivers", select "All" and select "Export"

{{< image src="images/microwin/dism++_drivercontrol" >}}

3. Choose the folder to export all the drivers to and click OK

{{< image src="images/microwin/dism++_driverexport" >}}

##### DISMTools

To export the drivers using [DISMTools](https://github.com/CodingWonders/DISMTools), do the following:

1. Select "Manage online installation" in the home screen and accept the warning

{{< image src="images/microwin/dt_activeinst" >}}

2. Go to "Commands > Drivers > Export driver packages..."

{{< image src="images/microwin/dt_exportdrvs" >}}

3. Choose the path to export the drivers to ("Export target") and click OK

{{< image src="images/microwin/dt_exporttarget" >}}

##### Other UIs

To export the drivers using another UI, read its documentation.

#### Using VirtIO drivers

After the drivers from the Ventoy ISO are copied, do the following if you can't see any drives on your QEMU VM:

1. In the disk selection screen, select "Load driver"
2. Click "Browse" and select `D:\VirtIO\vioscsi\w11\amd64` (replace `amd64` with `ARM64` if you want to use Windows on ARM)
3. Select all drivers in the list and click OK

You should be able to see your disks now.

### Copying to Ventoy

If you have a Ventoy drive, you can copy your ISO file to it quickly and easily. This is done after it has been created. To do this, simply check "Copy to Ventoy".

You can learn more about Ventoy drives [here](https://www.ventoy.net/en/index.html).

### Setting up a custom user

If you want to set up a custom user, effectively creating a completely unattended installation, you can set up a user name and password:

{{< image src="images/microwin/microwin-customuser" >}}

> [!NOTE]
To set up a custom user, you need to specify its name, which cannot surpass 20 characters. Otherwise, a user named "User" will be created. However, you don't need to set up a password. If you leave the password box blank, you can take advantage of auto-logons, but **do what you think it's best for your use case**.

After configuring all your desired settings, click "Start the process" and specify the location of your ISO file.

Now, you have to wait for the magic to happen. This can take between 5-10 minutes, but it depends on the performance of your computer.
