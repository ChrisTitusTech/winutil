function Invoke-MicrowinGetIso {
    <#
    .DESCRIPTION
    Function to get the path to Iso file for MicroWin, unpack that isom=, read basic information and populate the UI Options
    #>

    Write-Debug "Invoking WPFGetIso"

    if($sync.ProcessRunning) {
        $msg = "GetIso process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # Provide immediate feedback to user
    Invoke-MicrowinBusyInfo -action "wip" -message "Initializing MicroWin process..." -interactive $false

    Write-Host "         _                     __    __  _         "
    Write-Host "  /\/\  (_)  ___  _ __   ___  / / /\ \ \(_) _ __   "
    Write-Host " /    \ | | / __|| '__| / _ \ \ \/  \/ /| || '_ \  "
    Write-Host "/ /\/\ \| || (__ | |   | (_) | \  /\  / | || | | | "
    Write-Host "\/    \/|_| \___||_|    \___/   \/  \/  |_||_| |_| "

    if ($sync["ISOmanual"].IsChecked) {
        # Open file dialog to let user choose the ISO file
        Invoke-MicrowinBusyInfo -action "wip" -message "Please select an ISO file..." -interactive $true
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.initialDirectory = $initialDirectory
        $openFileDialog.filter = "ISO files (*.iso)| *.iso"
        $openFileDialog.ShowDialog() | Out-Null
        $filePath = $openFileDialog.FileName

        if ([string]::IsNullOrEmpty($filePath)) {
            Write-Host "No ISO is chosen"
            Invoke-MicrowinBusyInfo -action "hide" -message " "
            return
        }

    } elseif ($sync["ISOdownloader"].IsChecked) {
        # Create folder browsers for user-specified locations
        Invoke-MicrowinBusyInfo -action "wip" -message "Please select download location..." -interactive $true
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        $isoDownloaderFBD = New-Object System.Windows.Forms.FolderBrowserDialog
        $isoDownloaderFBD.Description = "Please specify the path to download the ISO file to:"
        $isoDownloaderFBD.ShowNewFolderButton = $true
        if ($isoDownloaderFBD.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK)
        {
            Invoke-MicrowinBusyInfo -action "hide" -message " "
            return
        }

        Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
        Invoke-MicrowinBusyInfo -action "wip" -message "Preparing to download ISO..." -interactive $false

        # Grab the location of the selected path
        $targetFolder = $isoDownloaderFBD.SelectedPath

        # Auto download newest ISO
        # Credit: https://github.com/pbatard/Fido
        $fidopath = "$env:temp\Fido.ps1"
        $originalLocation = $PSScriptRoot

        Invoke-MicrowinBusyInfo -action "wip" -message "Downloading Fido script..." -interactive $false
        Invoke-WebRequest "https://github.com/pbatard/Fido/raw/master/Fido.ps1" -OutFile $fidopath

        Set-Location -Path $env:temp
        # Detect if the first option ("System language") has been selected and get a Fido-approved language from the current culture
        $lang = if ($sync["ISOLanguage"].SelectedIndex -eq 0) {
            Microwin-GetLangFromCulture -langName (Get-Culture).Name
        } else {
            $sync["ISOLanguage"].SelectedItem
        }

        Invoke-MicrowinBusyInfo -action "wip" -message "Downloading Windows ISO... (This may take a long time)" -interactive $false
        & $fidopath -Win 'Windows 11' -Rel Latest -Arch "x64" -Lang $lang
        if (-not $?)
        {
            Write-Host "Could not download the ISO file. Look at the output of the console for more information."
            Write-Host "If you get an error about scripts is disabled on this system please close WinUtil and run - 'Set-ExecutionPolicy -ExecutionPolicy Unrestricted' and select 'A' and retry using MicroWin again."
            $msg = "The ISO file could not be downloaded"
            Invoke-MicrowinBusyInfo -action "warning" -message $msg
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        Set-Location $originalLocation
        # Use the FullName property to only grab the file names. Using this property is necessary as, without it, you're passing the usual output of Get-ChildItem
        # to the variable, and let's be honest, that does NOT exist in the file system
        $filePath = (Get-ChildItem -Path "$env:temp" -Filter "Win11*.iso").FullName | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $fileName = [IO.Path]::GetFileName("$filePath")

        if (($targetFolder -ne "") -and (Test-Path "$targetFolder"))
        {
            try
            {
                # "Let it download to $env:TEMP and then we **move** it to the file path." - CodingWonders
                $destinationFilePath = "$targetFolder\$fileName"
                Write-Host "Moving ISO file. Please wait..."
                Move-Item -Path "$filePath" -Destination "$destinationFilePath" -Force
                $filePath = $destinationFilePath
            }
            catch
            {
                $msg = "Unable to move the ISO file to the location you specified. The downloaded ISO is in the `"$env:TEMP`" folder"
                Write-Host $msg
                Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
                Invoke-MicrowinBusyInfo -action "warning" -message $msg
                return
            }
        }
    }

    Write-Host "File path $($filePath)"
    if (-not (Test-Path -Path "$filePath" -PathType Leaf)) {
        $msg = "File you've chosen doesn't exist"
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
    Invoke-MicrowinBusyInfo -action "wip" -message "Checking system requirements..." -interactive $false

    $adkKitsRoot = Microwin-GetKitsRoot -wow64environment $false
    $adkKitsRoot_WOW64Environ = Microwin-GetKitsRoot -wow64environment $true

    $expectedADKPath = "$($adkKitsRoot)Assessment and Deployment Kit"
    $expectedADKPath_WOW64Environ = "$($adkKitsRoot_WOW64Environ)Assessment and Deployment Kit"

    $oscdimgPath = Join-Path $env:TEMP 'oscdimg.exe'
    $oscdImgFound = [bool] (Microwin-TestKitsRootPaths -adkKitsRootPath "$expectedADKPath" -adkKitsRootPath_WOW64Environ "$expectedADKPath_WOW64Environ") -or (Test-Path $oscdimgPath -PathType Leaf)
    Write-Host "oscdimg.exe on system: $oscdImgFound"

    if (-not ($oscdImgFound)) {
        # First we try to grab it from github, if not, run the ADK installer.
        if ((Microwin-GetOscdimg -oscdimgPath $oscdimgPath) -eq $true) {
            Write-Host "OSCDIMG download succeeded."
        } else {
            Write-Host "OSCDIMG could not be downloaded from GitHub. Downloading deployment tools..."
            if (-not (Microwin-GetAdkDeploymentTools)) {
                Invoke-MicrowinBusyInfo -action "warning" -message "Neither OSCDIMG nor ADK could be downloaded."
                Write-Host "Neither OSCDIMG nor ADK could be downloaded."
                return
            } else {
                $msg = "ADK/OSCDIMG is installed, now restart this process."
                Invoke-MicrowinBusyInfo -action "done" -message $msg        # We set it to done because it immediately returns from this function
                [System.Windows.MessageBox]::Show($msg)
                Remove-Item -Path "$env:TEMP\adksetup.exe" -Force -ErrorAction SilentlyContinue
                return
            }
        }
    } elseif (Microwin-TestKitsRootPaths -adkKitsRootPath "$expectedADKPath" -adkKitsRootPath_WOW64Environ "$expectedADKPath_WOW64Environ") {
        # We have to guess where oscdimg is. We'll check both values...
        $peToolsPath = ""

        if ($expectedADKPath -ne "Assessment and Deployment Kit") { $peToolsPath = $expectedADKPath }
        if (($peToolsPath -eq "") -and ($expectedADKPath_WOW64Environ -ne "Assessment and Deployment Kit")) { $peToolsPath = $expectedADKPath_WOW64Environ }

        Write-Host "Using $peToolsPath as the Preinstallation Environment tools path..."
        # Paths change depending on platform
        if ([Environment]::Is64BitOperatingSystem) {
            $oscdimgPath = "$peToolsPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        } else {
            $oscdimgPath = "$peToolsPath\Deployment Tools\x86\Oscdimg\oscdimg.exe"
        }

        # If it's a non-existent file, we won't continue.
        if (-not (Test-Path -Path "$oscdimgPath" -PathType Leaf)) {
            $oscdimgFound = $false
        }
    }

    $oscdImgFound = [bool] (Microwin-TestKitsRootPaths -adkKitsRootPath "$expectedADKPath" -adkKitsRootPath_WOW64Environ "$expectedADKPath_WOW64Environ") -or (Test-Path $oscdimgPath -PathType Leaf)

    if (-not ($oscdimgFound)) {
        [System.Windows.MessageBox]::Show("oscdimg.exe is not found on the system. Cannot continue.")
        return
    }

    Invoke-MicrowinBusyInfo -action "wip" -message "Checking disk space..." -interactive $false

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
        $msg = "You don't have enough space for this operation. You need at least $([Math]::Round(($isoSize / ([Math]::Pow(1024, 2))) * 2, 2)) MB of free space to copy the ISO files to a temp directory and to be able to perform additional operations."
        Write-Host $msg
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        return
    } else {
        Write-Host "You have enough space for this operation."
    }

    try {
        Invoke-MicrowinBusyInfo -action "wip" -message "Mounting ISO file..." -interactive $false
        Write-Host "Mounting Iso. Please wait."
        $mountedISO = Mount-DiskImage -PassThru "$filePath"
        Write-Host "Done mounting Iso `"$($mountedISO.ImagePath)`""
        $driveLetter = (Get-Volume -DiskImage $mountedISO).DriveLetter
        Write-Host "Iso mounted to '$driveLetter'"
    } catch {
        # @ChrisTitusTech  please copy this wiki and change the link below to your copy of the wiki
        $msg = "Failed to mount the image. Error: $($_.Exception.Message)"
        Write-Error $msg
        Write-Error "This is NOT winutil's problem, your ISO might be corrupt, or there is a problem on the system"
        Write-Host "Please refer to this wiki for more details: https://winutil.christitus.com/knownissues/" -ForegroundColor Red
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
        Invoke-MicrowinBusyInfo -action "warning" -message $msg
        return
    }
    # storing off values in hidden fields for further steps
    # there is probably a better way of doing this, I don't have time to figure this out
    $sync.MicrowinIsoDrive.Text = $driveLetter

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
    $mountDir = Join-Path $env:TEMP $randomMicrowin
    $scratchDir = Join-Path $env:TEMP $randomMicrowinScratch

    $sync.MicrowinMountDir.Text = $mountDir
    $sync.MicrowinScratchDir.Text = $scratchDir
    Write-Host "Done setting up mount dir and scratch dirs"
    Write-Host "Scratch dir is $scratchDir"
    Write-Host "Image dir is $mountDir"

    try {

        #$data = @($driveLetter, $filePath)
        Invoke-MicrowinBusyInfo -action "wip" -message "Creating directories..." -interactive $false
        New-Item -ItemType Directory -Force -Path "$($mountDir)" | Out-Null
        New-Item -ItemType Directory -Force -Path "$($scratchDir)" | Out-Null

        Invoke-MicrowinBusyInfo -action "wip" -message "Copying Windows files... (This may take several minutes)" -interactive $false
        Write-Host "Copying Windows image. This will take awhile, please don't use UI or cancel this step!"

        # xcopy we can verify files and also not copy files that already exist, but hard to measure
        # xcopy.exe /E /I /H /R /Y /J $DriveLetter":" $mountDir >$null
        $totalTime = Measure-Command {
            Copy-Files "$($driveLetter):" "$mountDir" -Recurse -Force
            # Force UI update during long operation
            [System.Windows.Forms.Application]::DoEvents()
        }
        Write-Host "Copy complete! Total Time: $($totalTime.Minutes) minutes, $($totalTime.Seconds) seconds"

        Invoke-MicrowinBusyInfo -action "wip" -message "Processing Windows image..." -interactive $false
        $wimFile = "$mountDir\sources\install.wim"
        Write-Host "Getting image information $wimFile"

        if ((-not (Test-Path -Path "$wimFile" -PathType Leaf)) -and (-not (Test-Path -Path "$($wimFile.Replace(".wim", ".esd").Trim())" -PathType Leaf))) {
            $msg = "Neither install.wim nor install.esd exist in the image, this could happen if you use unofficial Windows images. Please don't use shady images from the internet."
            Write-Host "$($msg) Only use official images. Here are instructions how to download ISO images if the Microsoft website is not showing the link to download and ISO. https://www.techrepublic.com/article/how-to-download-a-windows-10-iso-file-without-using-the-media-creation-tool/"
            Invoke-MicrowinBusyInfo -action "warning" -message $msg
            Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"
            [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
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
        [System.Windows.Forms.Application]::DoEvents()

        $sync.MicrowinWindowsFlavors.SelectedIndex = 0
        Write-Host "Finding suitable Pro edition. This can take some time. Do note that this is an automatic process that might not select the edition you want."
        Invoke-MicrowinBusyInfo -action "wip" -message "Finding suitable Pro edition..." -interactive $false

        Get-WindowsImage -ImagePath $wimFile | ForEach-Object {
            if ((Get-WindowsImage -ImagePath $wimFile -Index $_.ImageIndex).EditionId -eq "Professional") {
                # We have found the Pro edition
                $sync.MicrowinWindowsFlavors.SelectedIndex = $_.ImageIndex - 1
            }
            # Allow UI updates during this loop
            [System.Windows.Forms.Application]::DoEvents()
        }

        Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
        Write-Host "Selected value '$($sync.MicrowinWindowsFlavors.SelectedValue)'....."

        Toggle-MicrowinPanel 2

    } catch {
        Write-Host "Dismounting bad image..."
        Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
        Remove-Item -Recurse -Force "$($scratchDir)"
        Remove-Item -Recurse -Force "$($mountDir)"
        Invoke-MicrowinBusyInfo -action "warning" -message "Failed to read and unpack ISO"
        Set-WinUtilTaskbaritem -state "Error" -value 1 -overlay "warning"

    }

    Write-Host "Done reading and unpacking ISO"
    Write-Host ""
    Write-Host "*********************************"
    Write-Host "Check the UI for further steps!!!"

    Invoke-MicrowinBusyInfo -action "done" -message "Done! Proceed with customization."
    $sync.ProcessRunning = $false
    Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
}
