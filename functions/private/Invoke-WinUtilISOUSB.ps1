function Invoke-WinUtilISORefreshUSBDrives {
    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]
    $disks = @(Get-Disk | Where-Object BusType -eq "USB" | Sort-Object Number)
    $combo.Items.Clear()

    if (-not $disks.Count) {
        $combo.Items.Add("No USB drives detected.")
        $combo.SelectedIndex = 0
        $sync["Win11ISOUSBDisks"] = @()
        Write-Win11ISOLog "No USB drives detected."
        return
    }

    $disks | ForEach-Object {
        $combo.Items.Add("Disk $($_.Number): $($_.FriendlyName) [$([math]::Round($_.Size/1GB,1)) GB] - $($_.PartitionStyle)")
    }
    $combo.SelectedIndex = 0
    $sync["Win11ISOUSBDisks"] = $disks
    Write-Win11ISOLog "Found $($disks.Count) USB drive(s)."
}

function Invoke-WinUtilISOWriteUSB {
    $disks = @($sync["Win11ISOUSBDisks"])
    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]
    $disk  = $disks[$combo.SelectedIndex]

    if (-not $disk) {
        [System.Windows.MessageBox]::Show("Select a USB drive.", "No Drive")
        return
    }

    $confirm = [System.Windows.MessageBox]::Show(
        "ALL data on Disk $($disk.Number) ($($disk.FriendlyName), $([math]::Round($disk.Size/1GB,1)) GB) will be PERMANENTLY ERASED.`nContinue?",
        "Confirm", "YesNo", "Warning"
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $false

    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("diskNum", $disk.Number)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $sync["Win11ISOContentsDir"])

    $script = [PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        function Write-Win11ISOLog ($Message) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text = "[$(Get-Date -f hh:mm:ss)] $Message"
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
        }

        function Get-FreeLetter {
            $used = (Get-PSDrive -PSProvider FileSystem).Name
            68..90 | ForEach-Object { [char]$_ } | Where-Object { $used -notcontains $_ } | Select-Object -First 1
        }

        Clear-Disk -Number $diskNum -RemoveData -Confirm:$false
        Initialize-Disk -Number $diskNum -PartitionStyle GPT
        Write-Win11ISOLog "Disk wiped and initialized (GPT)."

        $part = if ([math]::Floor((Get-Disk $diskNum).Size / 1MB) -gt 32768) {
            New-Partition -DiskNumber $diskNum -Size (32768MB) -AssignDriveLetter
        } else {
            New-Partition -DiskNumber $diskNum -UseMaximumSize -AssignDriveLetter
        }

        $letter = $part.DriveLetter
        if (-not $letter) {
            $letter = Get-FreeLetter
            Set-Partition -DiskNumber $diskNum -PartitionNumber $part.PartitionNumber -NewDriveLetter $letter
        }

        for ($i = 0; $i -lt 10 -and -not (Get-Volume -DriveLetter $letter); $i++) {
            Start-Sleep -Milliseconds 500
        }

        Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel win11creator -Force
        Write-Win11ISOLog "Formatted FAT32."

        $usb = "${letter}:"
        $srcSize = (Get-ChildItem $contentsDir -Recurse -File | Measure-Object Length -Sum).Sum
        if ($srcSize -gt (Get-Volume $letter).Size) { throw "Insufficient space on USB drive." }

        Write-Win11ISOLog "Splitting install.wim (this will take a while)..."
        New-Item "$usb\sources" -ItemType Directory -Force | Out-Null
        Split-WindowsImage -ImagePath "$contentsDir\sources\install.wim" -SplitImagePath "$usb\sources\install.swm" -FileSize 3800

        Write-Win11ISOLog "Copying files (this will take a while)..."
        Copy-Item -Path "$contentsDir\*" -Destination $usb -Recurse -Force -Exclude install.wim

        Write-Win11ISOLog "USB creation completed successfully."
        $sync["WPFWin11ISOWriteUSBButton"].Dispatcher.Invoke([action]{
            [System.Windows.MessageBox]::Show("USB creation completed successfully.", "Done", "OK", "Information")
            $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true
        })
    })

    $script.BeginInvoke()
}
