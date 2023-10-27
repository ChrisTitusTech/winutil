function Invoke-WPFGetIso {
    <#
    .DESCRIPTION
    Function to get the path to Iso file for MicroWin, unpack that isom=, read basic information and populate the UI Options
    #>

    Write-Host "Invoking WPFGetIso"

    if($sync.ProcessRunning){
        $msg = "GetIso process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Write-Host "         _                     __    __  _         "
	Write-Host "  /\/\  (_)  ___  _ __   ___  / / /\ \ \(_) _ __   "
	Write-Host " /    \ | | / __|| '__| / _ \ \ \/  \/ /| || '_ \  "
	Write-Host "/ /\/\ \| || (__ | |   | (_) | \  /\  / | || | | | "
	Write-Host "\/    \/|_| \___||_|    \___/   \/  \/  |_||_| |_| "

    Get-IsoInfo
    Write-Host "Done reading and unpacking ISO..."
    $sync.ProcessRunning = $false
}

function Get-IsoInfo
{
    
    $oscdImgFound = [bool] (Get-Command -ErrorAction Ignore -Type Application oscdimg)
    Write-Verbose -vb "oscdimge.exe found? $oscdImgFound"
    
    if (!$oscdImgFound) {
        [System.Windows.MessageBox]::Show("oscdimge.exe is not found on the system, you need to download it first before running this function!")
        Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "choco install windows-adk-oscdimg"
        [System.Windows.MessageBox]::Show("oscdimg is installed, now close, reopen PowerShell terminal and re-launch winutil.ps1 !!!")
        return
    }


	New-FirstRun
	New-Unattend

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.initialDirectory = $initialDirectory
    $openFileDialog.filter = "ISO files (*.iso)| *.iso"
    $openFileDialog.ShowDialog() | Out-Null
    $filePath = $openFileDialog.FileName

    Write-Host "File path $($filePath)"
    #$sync.MicrowinIsoLocation.Text = "Iso Location: $($filePath)"
    Write-Host "MicroWin: Mounting Iso"

    $mountedISO = Mount-DiskImage -PassThru $filePath
    $driveLetter = (Get-Volume -DiskImage $mountedISO).DriveLetter
    $sync.MicrowinIsoDrive.Text = $driveLetter

    $data = @($driveLetter,$filePath)
    Invoke-WPFRunspace -ArgumentList $data -ScriptBlock {
        param($data)
        $sync.ProcessRunning = $true
        $sync.Form.Dispatcher.Invoke({
            $sync.MicrowinIsoDrive.Text = $data[0]
            $sync.MicrowinIsoLocation.Text = $data[1]
        })
    }

    Write-Host "MicroWin: ISO is mounted to $($driveLetter) Installed"
        
	Write-Host "Creating temp directories"
    $mountDir = "c:\microwin"
    $scratchDir = "c:\microwinscratch"
    $sync.MicrowinMountDir.Text = $mountDir
    $sync.MicrowinScratchDir.Text = $scratchDir
	New-Item -ItemType Directory -Force -Path "$($mountDir)" | Out-Null
	New-Item -ItemType Directory -Force -Path "$($scratchDir)" | Out-Null
	Write-Host "Copying Windows image..."
    
    # xcopy we can verify files and also not copy files that already exist, but hard to measure
	# xcopy.exe /E /I /H /R /Y /J $DriveLetter":" $mountDir >$null
	$totalTime = Measure-Command { Copy-Files "$($driveLetter):" $mountDir -Recurse -Force }
	Write-Host "Copy complete! Total Time: $($totalTime.Minutes)m$($totalTime.Seconds)s"

    $wimFile = "$mountDir\sources\install.wim"
    Write-Host "Getting image information $wimFile"
    Get-WindowsImage -ImagePath C:\microwin\sources\install.wim | ForEach-Object {
		$imageIdx = $_.ImageIndex
        $imageName = $_.ImageName
        $sync.MicrowinWindowsFlavors.Items.Add("$imageIdx : $imageName")
	}
    $sync.MicrowinWindowsFlavors.SelectedIndex = 0
    Get-Volume $driveLetter | Get-DiskImage | Dismount-DiskImage
    Write-Host "Selected value '$($sync.MicrowinWindowsFlavors.SelectedValue)'....."

    $sync.MicrowinOptionsPanel.Visibility = 'Visible'
}
