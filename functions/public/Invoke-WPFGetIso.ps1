function Invoke-WPFGetIso {
    <#
    .DESCRIPTION
    Function to get the path to Iso file for MicroWin, unpack that isom=, read basic information and populate the UI Options
    #>

    Write-Host "Invoking WPFGetIso"

    if($sync.ProcessRunning) {
        $msg = "GetIso process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $sync.BusyMessage.Visibility="Visible"
    $sync.BusyText.Text="N Busy"



    Write-Host "         _                     __    __  _         "
    Write-Host "  /\/\  (_)  ___  _ __   ___  / / /\ \ \(_) _ __   "
    Write-Host " /    \ | | / __|| '__| / _ \ \ \/  \/ /| || '_ \  "
    Write-Host "/ /\/\ \| || (__ | |   | (_) | \  /\  / | || | | | "
    Write-Host "\/    \/|_| \___||_|    \___/   \/  \/  |_||_| |_| "

    $oscdimgPath = Join-Path $env:TEMP 'oscdimg.exe'
    $oscdImgFound = [bool] (Get-Command -ErrorAction Ignore -Type Application oscdimg.exe) -or (Test-Path $oscdimgPath -PathType Leaf)
    Write-Host "oscdimg.exe on system: $oscdImgFound"

    if (!$oscdImgFound) {
        $downloadFromGitHub = $sync.WPFMicrowinDownloadFromGitHub.IsChecked
        $sync.BusyMessage.Visibility="Hidden"

        if (!$downloadFromGitHub) {
            # only show the message to people who did check the box to download from github, if you check the box
            # you consent to downloading it, no need to show extra dialogs
            [System.Windows.MessageBox]::Show("oscdimge.exe is not found on the system, winutil will now attempt do download and install it using choco. This might take a long time.")
            # the step below needs choco to download oscdimg
            # Install Choco if not already present
            Install-WinUtilChoco
            $chocoFound = [bool] (Get-Command -ErrorAction Ignore -Type Application choco)
            Write-Host "choco on system: $chocoFound"
            if (!$chocoFound) {
                [System.Windows.MessageBox]::Show("choco.exe is not found on the system, you need choco to download oscdimg.exe")
                return
            }

            Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "choco install windows-adk-oscdimg"
            [System.Windows.MessageBox]::Show("oscdimg is installed, now close, reopen PowerShell terminal and re-launch winutil.ps1")
            return
        } else {
            [System.Windows.MessageBox]::Show("oscdimge.exe is not found on the system, winutil will now attempt do download and install it from github. This might take a long time.")
            Get-Oscdimg -oscdimgPath $oscdimgPath
            $oscdImgFound = Test-Path $oscdimgPath -PathType Leaf
            if (!$oscdImgFound) {
                $msg = "oscdimg was not downloaded can not proceed"
                [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                return
            } else {
                Write-Host "oscdimg.exe was successfully downloaded from github"
            }
        }
    }

    if ($sync["ISOmanual"].IsChecked) {
        # Open file dialog to let user choose the ISO file
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.initialDirectory = $initialDirectory
        $openFileDialog.filter = "ISO files (*.iso)| *.iso"
        $openFileDialog.ShowDialog() | Out-Null
        $filePath = $openFileDialog.FileName

        if ([string]::IsNullOrEmpty($filePath)) {
            Write-Host "No ISO is chosen"
            $sync.BusyMessage.Visibility="Hidden"
            return
        }
    } elseif ($sync["ISOdownloader"].IsChecked) {
        # Auto download newest ISO
        # Credit: https://github.com/pbatard/Fido
        $fidopath = "$env:temp\Fido.ps1"
        $originalLocation = Get-Location

        Invoke-WebRequest "https://github.com/pbatard/Fido/raw/master/Fido.ps1" -OutFile $fidopath

        Set-Location -Path $env:temp
        & $fidopath -Win 'Windows 11' -Rel $sync["ISORelease"].SelectedItem -Arch "x64" -Lang $sync["ISOLanguage"].SelectedItem -Ed "Windows 11 Home/Pro/Edu"
        Set-Location $originalLocation
        $filePath = Get-ChildItem -Path "$env:temp" -Filter "Win11*.iso" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }

    Write-Host "File path $($filePath)"
    if (-not (Test-Path -Path "$filePath" -PathType Leaf)) {
        $msg = "File you've chosen doesn't exist"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"

    # Detect the file size of the ISO and compare it with the free space of the system drive
    $isoSize = (Get-Item -Path "$filePath").Length
    Write-Debug "Size of ISO file: $($isoSize) bytes"
    # Use this procedure to get the free space of the drive depending on where the user profile folder is stored.
    # This is done to guarantee a dynamic solution, as the installation drive may be mounted to a letter different than C
    $driveSpace = (Get-Volume -DriveLetter ([IO.Path]::GetPathRoot([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)).Replace(":\", "").Trim())).SizeRemaining
    Write-Debug "Free space on installation drive: $($driveSpace) bytes"
    if ($driveSpace -lt ($isoSize * 2)) {
        # It's not critical and we _may_ continue. Output a warning
        Write-Warning "You may not have enough space for this operation. Proceed at your own risk."
    }
    elseif ($driveSpace -lt $isoSize) {
        # It's critical and we can't continue. Output an error
        Write-Host "You don't have enough space for this operation. You need at least $([Math]::Round(($isoSize / ([Math]::Pow(1024, 2))) * 2, 2)) MB of free space to copy the ISO files to a temp directory and to be able to perform additional operations."
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        return
    } else {
        Write-Host "You have enough space for this operation."
    }

    try {
        Write-Host "Mounting Iso. Please wait."
        $mountedISO = Mount-DiskImage -PassThru "$filePath"
        Write-Host "Done mounting Iso $mountedISO"
        $driveLetter = (Get-Volume -DiskImage $mountedISO).DriveLetter
        Write-Host "Iso mounted to '$driveLetter'"
    } catch {
        # @ChrisTitusTech  please copy this wiki and change the link below to your copy of the wiki
        Write-Error "Failed to mount the image. Error: $($_.Exception.Message)"
        Write-Error "This is NOT winutil's problem, your ISO might be corrupt, or there is a problem on the system"
        Write-Host "Please refer to this wiki for more details: https://christitustech.github.io/winutil/KnownIssues/#troubleshoot-errors-during-microwin-usage" -ForegroundColor Red
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        return
    }
    # storing off values in hidden fields for further steps
    # there is probably a better way of doing this, I don't have time to figure this out
    $sync.MicrowinIsoDrive.Text = $driveLetter

    $mountedISOPath = (Split-Path -Path "$filePath")
     if ($sync.MicrowinScratchDirBox.Text.Trim() -eq "Scratch") {
        $sync.MicrowinScratchDirBox.Text =""
    }

     $UseISOScratchDir = $sync.WPFMicrowinISOScratchDir.IsChecked

    if ($UseISOScratchDir) {
        $sync.MicrowinScratchDirBox.Text=$mountedISOPath
    }

    if( -Not $sync.MicrowinScratchDirBox.Text.EndsWith('\') -And  $sync.MicrowinScratchDirBox.Text.Length -gt 1) {

         $sync.MicrowinScratchDirBox.Text = Join-Path   $sync.MicrowinScratchDirBox.Text.Trim() '\'

    }

    # Detect if the folders already exist and remove them
    if (($sync.MicrowinMountDir.Text -ne "") -and (Test-Path -Path $sync.MicrowinMountDir.Text)) {
        try {
            Write-Host "Deleting temporary files from previous run. Please wait..."
            Remove-Item -Path $sync.MicrowinMountDir.Text -Recurse -Force
            Remove-Item -Path $sync.MicrowinScratchDir.Text -Recurse -Force
        } catch {
            Write-Host "Could not delete temporary files. You need to delete those manually."
        }
    }

    Write-Host "Setting up mount dir and scratch dirs"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $randomNumber = Get-Random -Minimum 1 -Maximum 9999
    $randomMicrowin = "Microwin_${timestamp}_${randomNumber}"
    $randomMicrowinScratch = "MicrowinScratch_${timestamp}_${randomNumber}"
    $sync.BusyText.Text=" - Mounting"
    Write-Host "Mounting Iso. Please wait."
    if ($sync.MicrowinScratchDirBox.Text -eq "") {
    $mountDir = Join-Path $env:TEMP $randomMicrowin
    $scratchDir = Join-Path $env:TEMP $randomMicrowinScratch
    } else {
        $scratchDir = $sync.MicrowinScratchDirBox.Text+"Scrach"
        $mountDir = $sync.MicrowinScratchDirBox.Text+"micro"
    }

    $sync.MicrowinMountDir.Text = $mountDir
    $sync.MicrowinScratchDir.Text = $scratchDir
    Write-Host "Done setting up mount dir and scratch dirs"
    Write-Host "Scratch dir is $scratchDir"
    Write-Host "Image dir is $mountDir"

    try {

        #$data = @($driveLetter, $filePath)
        New-Item -ItemType Directory -Force -Path "$($mountDir)" | Out-Null
        New-Item -ItemType Directory -Force -Path "$($scratchDir)" | Out-Null
        Write-Host "Copying Windows image. This will take awhile, please don't use UI or cancel this step!"

        # xcopy we can verify files and also not copy files that already exist, but hard to measure
        # xcopy.exe /E /I /H /R /Y /J $DriveLetter":" $mountDir >$null
        $totalTime = Measure-Command { Copy-Files "$($driveLetter):" $mountDir -Recurse -Force }
        Write-Host "Copy complete! Total Time: $($totalTime.Minutes)m$($totalTime.Seconds)s"

        $wimFile = "$mountDir\sources\install.wim"
        Write-Host "Getting image information $wimFile"

        if ((-not (Test-Path -Path "$wimFile" -PathType Leaf)) -and (-not (Test-Path -Path "$($wimFile.Replace(".wim", ".esd").Trim())" -PathType Leaf))) {
            $msg = "Neither install.wim nor install.esd exist in the image, this could happen if you use unofficial Windows images. Please don't use shady images from the internet, use only official images. Here are instructions how to download ISO images if the Microsoft website is not showing the link to download and ISO. https://www.techrepublic.com/article/how-to-download-a-windows-10-iso-file-without-using-the-media-creation-tool/"
            Write-Host $msg
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            throw
        }
        elseif ((-not (Test-Path -Path $wimFile -PathType Leaf)) -and (Test-Path -Path $wimFile.Replace(".wim", ".esd").Trim() -PathType Leaf)) {
            Write-Host "Install.esd found on the image. It needs to be converted to a WIM file in order to begin processing"
            $wimFile = $wimFile.Replace(".wim", ".esd").Trim()
        }
        $sync.MicrowinWindowsFlavors.Items.Clear()
        Get-WindowsImage -ImagePath $wimFile | ForEach-Object {
            $imageIdx = $_.ImageIndex
            $imageName = $_.ImageName
            $sync.MicrowinWindowsFlavors.Items.Add("$imageIdx : $imageName")
        }
        $sync.MicrowinWindowsFlavors.SelectedIndex = 0
        Write-Host "Finding suitable Pro edition. This can take some time. Do note that this is an automatic process that might not select the edition you want."
        Get-WindowsImage -ImagePath $wimFile | ForEach-Object {
            if ((Get-WindowsImage -ImagePath $wimFile -Index $_.ImageIndex).EditionId -eq "Professional") {
                # We have found the Pro edition
                $sync.MicrowinWindowsFlavors.SelectedIndex = $_.ImageIndex - 1
            }
        }
        Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
        Write-Host "Selected value '$($sync.MicrowinWindowsFlavors.SelectedValue)'....."

        $sync.MicrowinOptionsPanel.Visibility = 'Visible'
    } catch {
        Write-Host "Dismounting bad image..."
        Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
        Remove-Item -Recurse -Force "$($scratchDir)"
        Remove-Item -Recurse -Force "$($mountDir)"
    }

    Write-Host "Done reading and unpacking ISO"
    Write-Host ""
    Write-Host "*********************************"
    Write-Host "Check the UI for further steps!!!"

    $sync.BusyMessage.Visibility="Hidden"
    $sync.ProcessRunning = $false
    Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
}
