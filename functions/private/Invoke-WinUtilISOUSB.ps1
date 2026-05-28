function Invoke-WinUtilISORefreshUSBDrives {
    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]
    $removable = @(Get-Disk | Where-Object BusType -eq "USB" | Sort-Object Number)

    $combo.Items.Clear()

    if ($removable.Count -eq 0) {
        $combo.Items.Add("No USB drives detected.")
        $combo.SelectedIndex = 0
        $sync["Win11ISOUSBDisks"] = @()
        Write-Win11ISOLog "No USB drives detected."
        return
    }

    foreach ($disk in $removable) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $combo.Items.Add("Disk $($disk.Number): $($disk.FriendlyName) [$sizeGB GB] - $($disk.PartitionStyle)")
    }

    $combo.SelectedIndex = 0
    Write-Win11ISOLog "Found $($removable.Count) USB drive(s)."
    $sync["Win11ISOUSBDisks"] = $removable
}


function Invoke-WinUtilISOWriteUSB {
    $contentsDir = $sync["Win11ISOContentsDir"]
    $usbDisks = @($sync["Win11ISOUSBDisks"])
    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]

    $disk =
        if ($combo.SelectedIndex -ge 0 -and $combo.SelectedIndex -lt $usbDisks.Count) {
            $usbDisks[$combo.SelectedIndex]
        }
        elseif ($combo.SelectedItem -match 'Disk\s+(\d+)') {
            $usbDisks | Where-Object Number -eq $matches[1] | Select-Object -First 1
        }

    if (-not $disk) {
        [System.Windows.MessageBox]::Show("Select USB drive.", "No Drive")
        return
    }

    $sizeGB = [math]::Round($disk.Size / 1GB, 1)

    $confirm = [System.Windows.MessageBox]::Show(
        "ALL data on Disk $($disk.Number) ($($disk.FriendlyName), $sizeGB GB) will be PERMANENTLY ERASED.`nContinue?",
        "Confirm USB Erase",
        "YesNo",
        "Warning"
    )

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        throw "Cancelled by user"
    }

    $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $false

    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.Open()

    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("diskNum", $disk.Number)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $contentsDir)

    $script = [PowerShell]::Create()
    $script.Runspace = $runspace

    $script.AddScript({

        function Write-Win11ISOLog ($Message) {
            $time = Get-Date -Format hh:mm:ss

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "[$time] $Message"
                $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
        }

        function Get-FreeLetter {
            $used = (Get-PSDrive -PSProvider FileSystem).Name
            foreach ($c in 68..90 | ForEach-Object { [char]$_ }) {
                if ($used -notcontains $c) { return $c }
            }
        }

        Clear-Disk -Number $diskNum -RemoveData -Confirm:$false
        Write-Win11ISOLog "Disk Wiped."

        Initialize-Disk -Number $diskNum -PartitionStyle GPT
        Write-Win11ISOLog "Initialized GPT Partition."

        $diskObj = Get-Disk $diskNum
        $maxMB = 32768
        $sizeMB = [math]::Floor($diskObj.Size / 1MB)

        $part =
            if ($sizeMB -gt $maxMB) {
                New-Partition -DiskNumber $diskNum -Size ($maxMB * 1MB) -AssignDriveLetter
            } else {
                New-Partition -DiskNumber $diskNum -UseMaximumSize -AssignDriveLetter
            }

        $letter = $part.DriveLetter

        if (-not $letter) {
            $letter = Get-FreeLetter
            Set-Partition -DiskNumber $diskNum -PartitionNumber $part.PartitionNumber -NewDriveLetter $letter
        }
        Write-Win11ISOLog "Created partition."

        Write-Win11ISOLog "Waiting for volume mount..."

        $ready = $false
        for ($i = 0; $i -lt 10; $i++) {
            if (Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue) {
                $ready = $true
                break
            }
            Start-Sleep -Milliseconds 500
        }

        $usb = "${letter}:"

        Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel ("W11-" + (Get-Date -Format "yyMMdd")) -Force
        Write-Win11ISOLog "Formatted FAT32 Partition."

        Write-Win11ISOLog "Checking size..."

        $srcSize = (Get-ChildItem $contentsDir -Recurse -File | Measure-Object Length -Sum).Sum
        $vol = Get-Volume $letter

        if ($srcSize -gt $vol.Size) {
            throw "Insufficient space"
        }

        Write-Win11ISOLog "Splitting install.wim This will take a while..."

        New-Item -Path "$usb\sources" -ItemType Directory
        Split-WindowsImage -ImagePath "$contentsDir\sources\install.wim" -SplitImagePath "$usb\sources\install.swm" -FileSize 3800

        Write-Win11ISOLog "Copying remaining files This will take a while..."
        Copy-Item -Path "$contentsDir\*" $usb -Recurse -Force -Exclude install.wim

        Write-Win11ISOLog "USB creation completed successfully."

        $sync["WPFWin11ISOWriteUSBButton"].Dispatcher.Invoke([action]{
            [System.Windows.MessageBox]::Show(
                "USB creation completed successfully.",
                "Done",
                "OK",
                "Information"
            )
        })
        
        $sync["WPFWin11ISOWriteUSBButton"].Dispatcher.Invoke([action]{
            $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true
        })
    })

    $script.BeginInvoke()
}
