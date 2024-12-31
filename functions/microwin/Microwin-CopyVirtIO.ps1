function Microwin-CopyVirtIO {
    <#
        .SYNOPSIS
            Downloads and copies the VirtIO Guest Tools drivers to the target MicroWin ISO
        .NOTES
            A network connection must be available and the servers of Fedora People must be up. Automatic driver installation will not be added yet - I want this implementation to be reliable.
    #>

    try {
        Write-Host "Checking existing files..."
        if (Test-Path -Path "$($env:TEMP)\virtio.iso" -PathType Leaf) {
            Write-Host "VirtIO ISO has been detected. Deleting..."
            Remove-Item -Path "$($env:TEMP)\virtio.iso" -Force
        }
        Write-Host "Getting latest VirtIO drivers. Please wait. This can take some time, depending on your network connection speed and the speed of the servers..."
        Start-BitsTransfer -Source "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" -Destination "$($env:TEMP)\virtio.iso" -DisplayName "Downloading VirtIO drivers..."
        # Do everything else if the VirtIO ISO exists
        if (Test-Path -Path "$($env:TEMP)\virtio.iso" -PathType Leaf) {
            Write-Host "Mounting ISO. Please wait."
            $virtIO_ISO = Mount-DiskImage -PassThru "$($env:TEMP)\virtio.iso"
            $driveLetter = (Get-Volume -DiskImage $virtIO_ISO).DriveLetter
            # Create new directory for VirtIO on ISO
            New-Item -Path "$mountDir\VirtIO" -ItemType Directory | Out-Null
            $totalTime = Measure-Command { Copy-Files "$($driveLetter):" "$mountDir\VirtIO" -Recurse -Force }
            Write-Host "VirtIO contents have been successfully copied. Time taken: $($totalTime.Minutes) minutes, $($totalTime.Seconds) seconds`n"
            Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
            Remove-Item -Path "$($env:TEMP)\virtio.iso" -Force -ErrorAction SilentlyContinue
            Write-Host "To proceed with installation of the MicroWin image in QEMU/Proxmox VE:"
            Write-Host "1. Proceed with Setup until you reach the disk selection screen, in which you won't see any drives"
            Write-Host "2. Click `"Load Driver`" and click Browse"
            Write-Host "3. In the folder selection dialog, point to this path:`n`n    `"D:\VirtIO\vioscsi\w11\amd64`" (replace amd64 with ARM64 if you are using Windows on ARM, and `"D:`" with the drive letter of the ISO)`n"
            Write-Host "4. Select all drivers that will appear in the list box and click OK"
        } else {
            throw "Could not download VirtIO drivers"
        }
    } catch {
        Write-Host "We could not download and/or prepare the VirtIO drivers. Error information: $_`n"
        Write-Host "You will need to download these drivers manually. Location: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
    }
}
