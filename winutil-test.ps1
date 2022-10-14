<#
.NOTES
   Author      : @DeveloperDurp
   GitHub      : https://github.com/DeveloperDurp
   Version 0.0.1
#>

#region Variables
    $sync = [Hashtable]::Synchronized(@{})
    $sync.tempfolder = "$env:userprofile\AppData\Local\Temp"
    $sync.logfile = "$($sync.tempfolder)\winutil.log"

    $VerbosePreference = "Continue"

    #WinForms dependancies 
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

    #Test for admin credentials
    #if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    #    [System.Windows.MessageBox]::Show("This application needs to be run as Admin",'Administrative privileges required',"OK","Info")
    #    Return
    #}

    #List of config files to import
    $configs = (
        "applications", 
        "tweaks",
        "preset", 
        "feature",
        "updates"
    )

    #To use local files run $env:environment = "dev" before starting the ps1 file
    if($env:environment -eq "dev"){
        $confirm = [System.Windows.MessageBox]::Show('$ENV:Evnronment is set to dev. Do you wish to load the dev environment?','Dev Environment tag detected',"YesNo","Info")
    }
    if($env:environment -eq "exe"){$confirm = "yes"}
    if($confirm -eq "yes"){
        $inputXML = Get-Content "MainWindow.xaml"
        $configs | ForEach-Object {
            $sync["$PSItem"] = Get-Content .\config\$PSItem.json | ConvertFrom-Json
        }        
    }
    else{

        #Select the working branch
        if($env:branch){
            $branch = $env:branch
        }
        Else {$branch = "main"}

        $inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/$branch/MainWindow.xaml")
        $configs | ForEach-Object {
            $sync["$_"] = Invoke-RestMethod "https://raw.githubusercontent.com/ChrisTitusTech/winutil/$branch/config/$_.json"
        }
    }
        
    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
    [xml]$XAML = $inputXML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    
    try{$sync["Form"]=[Windows.Markup.XamlReader]::Load( $reader )}
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
        write-host $error[0].Exception.Message -ForegroundColor Red
        if ($error[0].Exception.Message -like "*button*"){
            write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
    }
    catch{#if it broke some other way <img draggable="false" role="img" class="emoji" alt="ðŸ˜€" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
        Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
    }

#endregion Variables
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($_.Name)")"] = $sync["Form"].FindName($_.Name)}
 
#region Functions

    #===========================================================================
    # Button clicks
    #===========================================================================
    
    #Gives every button the invoke-button function
    $sync.keys | ForEach-Object {
        if($sync.$psitem){
            if($($sync["$_"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
                $sync["$_"].Add_Click({
                    [System.Object]$Sender = $args[0]
                    Invoke-Button $Sender.name
                })
            }
        }
    }

    function Invoke-Button {
        Param ([string]$Button) 
        #[System.Windows.MessageBox]::Show("$button",'Button Value',"OK","Info")
        Switch -Wildcard ($Button){

            "*Tab*BT*" {switchtab $Button}
            "*InstallUpgrade*" {Invoke-command $sync.GUIInstallPrograms -ArgumentList "Upgrade"}
            "*desktop*" {Tweak-Buttons $Button}
            "*laptop*" {Tweak-Buttons $Button}
            "*minimal*" {Tweak-Buttons $Button}
            "*undoall*" {Invoke-command $Sync.GUIUndoTweaks}
            "install" {Invoke-command $sync.GUIInstallPrograms -ArgumentList "$(uncheckall "Install")"}
            "tweaksbutton" {Invoke-command $Sync.GUITweaks -ArgumentList "$(uncheckall "tweaks")"}
            "FeatureInstall" {Invoke-command $Sync.GUIFeatures -ArgumentList "$(uncheckall "feature")"}
            "Panelcontrol" {cmd /c control}
            "Panelnetwork" {cmd /c ncpa.cpl}
            "Panelpower" {cmd /c powercfg.cpl}
            "Panelsound" {cmd /c mmsys.cpl}
            "Panelsystem" {cmd /c sysdm.cpl}
            "Paneluser" {cmd /c "control userpasswords2"}
            "Updatesdefault" {Invoke-command $Updatesdefault}
            "Updatesdisable" {Invoke-command $Updatesdisable}
            "Updatessecurity" {Invoke-command $Updatessecurity}
        }
    }

    function uncheckall {
        param($group)
        $sync.keys | Where-Object {$_ -like "*$($group)?*" `
                                -and $_ -notlike "$($group)Install" `
                                -and $_ -notlike "*GUI*" `
                                -and $_ -notlike "*Script*"
                            } | ForEach-Object {
            if ($sync["$_"].IsChecked -eq $true){
                $output += ",$_"
                $sync["$_"].IsChecked = $false
            }
        }
        Write-Output $output.Substring(1)
    }

    function Invoke-Runspace {
        [CmdletBinding()]
        Param (
            $ScriptBlock,
            $ArgumentList
        ) 

        $Script = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($ArgumentList)

        $Script.Runspace = $runspace
        $Script.BeginInvoke()
    }

    #===========================================================================
    # Navigation Controls
    #===========================================================================

    function switchtab {
        Param ($button)
        $x = [int]($button -replace "Tab","" -replace "BT","") - 1

        0..3 | ForEach-Object {
            
            if ($x -eq $_){$sync["TabNav"].Items[$_].IsSelected = $true}
            else{$sync["TabNav"].Items[$_].IsSelected = $false}
        }
    }

    Function Tweak-Buttons {
        Param ($button)
        $preset = $sync.preset.$button

        $sync.keys | Where-Object {$_ -like "*tweaks?*" -and $_ -notlike "tweaksbutton"} | ForEach-Object {
            if ($preset -contains $_ ){$sync["$_"].IsChecked = $True}
            Else{$sync["$_"].IsChecked = $false} 
        }
    }

#endregion Functions

#===========================================================================
# Scritps to be ran inside a runspace
#===========================================================================

#region Scripts

    #===========================================================================
    # Generic Scripts
    #===========================================================================

    $sync.WriteLogs = {

        <#
        
            .DESCRIPTION
            Simple function to write logs to a temp directory.

            .EXAMPLE

            $Level = "INFO"
            $Message = "This is a test message!"
            $LogPath = "$ENV:TEMP\winutil.log"
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message,$LogPath)
        
        #>

        [cmdletbinding()]
        param(
            $Level = "Info", 
            $Message, 
            $LogPath = "$env:userprofile\AppData\Local\Temp\winutil.log"
        )

        $date = get-date
        $delimiter = '|'
        write-output "$date $delimiter $Level $delimiter $message" |  out-file -Append -Encoding ascii -FilePath $LogPath
        if($Level -eq "ERROR" -or $Level -eq "FAILURE"){
            write-Error "$date $delimiter $Level $delimiter $message"
            return
        }
        if($Level -eq "Warning"){
            Write-Warning "$date $delimiter $Level $delimiter $message"
            return
        }
        Write-Verbose "$date $delimiter $Level $delimiter $message"
    }

    #===========================================================================
    # Install Tab
    #===========================================================================

    <#

        This section is working as expected and logs output to console and $ENV:Temp\winutil.log

        TODO: Error Handling with winget. Currently it does not handle errors as expected.
    
    #>

    $Sync.GUIInstallPrograms = {

        <#

            .DESCRIPTION
            This Scriptblock is meant to be ran from inside the GUI and will prevent the user from starting another install task. 

            Input data will look like below and link with the name of the check box. This will then look to the config/applications.json file to find
            the winget install commands for the selected applications.

            Installadvancedip,Installbitwarden

            .EXAMPLE

            Invoke-command $sync.GUIInstallPrograms -ArgumentList "Installadvancedip,Installbitwarden"

        #>

        Param ($programstoinstall)
        $programstoinstall = $programstoinstall -split ","

        #Check if any check boxes have been checked and if a job is already running

            if($programstoinstall -eq $null){
                [System.Windows.MessageBox]::Show("Please check the applications you wish to install",'Nothing to do',"OK","Info")
                return
            }

            $sync.form.Dispatcher.Invoke([action]{$sync.installcheck = $sync.install.Content},"Normal")
            If($sync.installcheck -like "Running"){
                [System.Windows.MessageBox]::Show("Task is currently running",'Installs are in progress',"OK","Info")
                return
            }

            $sync.Form.Dispatcher.Invoke([action]{$sync.install.Content = "Running"},"Normal")
            $sync.Form.Dispatcher.Invoke([action]{$sync.InstallUpgrade.Content = "Running"},"Normal")

        #Section to see if winget will upgrade all installs or which winget commands to run from  config/applications.json

            if($programstoinstall -eq "Upgrade"){
                $winget = ",Upgrade"
            }
            else{
                foreach ($program in $programstoinstall){
                    $($sync.applications.install.$program.winget) -split ";" | ForEach-Object {
                        $winget += ",$_"
                    }
                }
            }

        #Invoke a runspace so that the GUI does not lock up

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "$($winget.substring(1))"
                Verbose = $true
            }
            Invoke-Runspace @params

    }

    <#

        Running $sync.ScriptsInstallPrograms in CLI format

        Make sure to set
        VerbosePreference = "Continue"

        $params = @{
            ScriptBlock = $sync.ScriptsInstallPrograms
            ArgumentList = "git.git,WinDirStat.WinDirStat"
            Verbose = $true
        }

        To upgrade

        $params = @{
            ScriptBlock = $sync.ScriptsInstallPrograms
            ArgumentList = "Upgrade"
            Verbose = $true
        }

        Invoke-Command @params

    #>

    $sync.ScriptsInstallPrograms = {

        <#

            .DESCRIPTION
            This scriptblock will detect if winget is installed and if not attempt to install it. Once ready it will then either upgrade any installs or attempt to install any applications provided.

            .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "git.git,WinDirStat.WinDirStat"
                Verbose = $true
            }
            VerbosePreference = "Continue"
            Invoke-Command @params

        .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "Upgrade"
                Verbose = $true
            }

            VerbosePreference = "Continue"
            Invoke-Command @params

        #>

        Param ($programstoinstall)
        $programstoinstall = $programstoinstall -split ","

        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message,$LogPath)
        }

        #region Check for WinGet and install if not present

            if (Test-Path $env:userprofile\AppData\Local\Microsoft\WindowsApps\winget.exe) {
                #Checks if winget executable exists and if the Windows Version is 1809 or higher
                Write-Logs -Level INFO -Message "WinGet was detected" -LogPath $sync.logfile
            }
            else {

                if (($sync.ComputerInfo.WindowsVersion) -lt "1809") {
                    #Checks if Windows Version is too old for winget
                    Write-Logs -Level Warning -Message "Winget is not supported on this version of Windows (Pre-1809). Stopping installs" -LogPath $sync.logfile
                    return
                }

                Write-Logs -Level INFO -Message "WinGet was not detected" -LogPath $sync.logfile

                if (((($sync.ComputerInfo.OSName.IndexOf("LTSC")) -ne -1) -or ($sync.ComputerInfo.OSName.IndexOf("Server") -ne -1)) -and (($sync.ComputerInfo.WindowsVersion) -ge "1809")) {
                    Try{
                        #Checks if Windows edition is LTSC/Server 2019+
                        #Manually Installing Winget
                        Write-Logs -Level INFO -Message "LTSC/Server Edition detected. Running Alternative Installer" -LogPath $sync.logfile
        
                        #Download Needed Files
                        $step = "Downloading the required files"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Start-BitsTransfer -Source "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -Destination "$($sync.tempfolder)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop
                        Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Destination "$($sync.tempfolder)/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ErrorAction Stop
                        Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/b0a0692da1034339b76dce1c298a1e42_License1.xml" -Destination "$($sync.tempfolder)/b0a0692da1034339b76dce1c298a1e42_License1.xml" -ErrorAction Stop
        
                        #Installing Packages
                        $step = "Installing Packages"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Add-AppxProvisionedPackage -Online -PackagePath "$($sync.tempfolder)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -SkipLicense -ErrorAction Stop
                        Add-AppxProvisionedPackage -Online -PackagePath "$($sync.tempfolder)\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -LicensePath "$($sync.tempfolder)\b0a0692da1034339b76dce1c298a1e42_License1.xml" -ErrorAction Stop
                        
                        #Sleep for 5 seconds to maximize chance that winget will work without reboot
                        Start-Sleep -s 5
        
                        #Removing no longer needed Files
                        $step = "Removing Files"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Remove-Item -Path "$($sync.tempfolder)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -Force
                        Remove-Item -Path "$($sync.tempfolder)\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force
                        Remove-Item -Path "$($sync.tempfolder)\b0a0692da1034339b76dce1c298a1e42_License1.xml" -Force

                        $step = "WinGet Sucessfully installed"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile

                    }Catch{Write-Logs -Level FAILURE -Message "WinGet Install failed at $step" -LogPath $sync.logfile}
                }
                else {
                    Try{
                        #Installing Winget from the Microsoft Store                       
                        $step = "Installing WinGet"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
                        $nid = (Get-Process AppInstaller).Id
                        Wait-Process -Id $nid

                        $step = "Winget Installed"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                    }Catch{Write-Logs -Level FAILURE -Message "WinGet Install failed at $step" -LogPath $sync.logfile}
                }
                Write-Logs -Level INFO -Message "WinGet has been installed" -LogPath $sync.logfile
                Start-Sleep -Seconds 15
            }

        #endregion Check for WinGet and install if not present

        $results = @()
        foreach ($program in $programstoinstall){
            if($programstoinstall -eq "Upgrade"){
                $Message = "Attempting to upgrade packages"
                $ErrorMessage = "Failed to upgrade packages"
                $SuccessMessage = "Upgardes have completed"
                $ArgumentList = "upgrade --all"
            }
            else{
                $Message = "$($program) was selected to be installed."
                $ErrorMessage = "$($program) failed to installed."
                $SuccessMessage = "$($program) has been installed"
                $ArgumentList = "install -e --accept-source-agreements --accept-package-agreements --silent $($program)"
            }

            try {
                Write-Logs -Level INFO -Message "$Message" -LogPath $sync.logfile
                Write-Host ""

                $installs = Start-Process -FilePath winget -ArgumentList $ArgumentList -ErrorAction Stop -Wait -PassThru -NoNewWindow
            }
            catch {
                Write-Logs -Level FAILURE -Message $ErrorMessage -LogPath $sync.logfile
                $results += $program
            }
        }

        Write-Logs -Level INFO -Message "Installs have completed" -LogPath $sync.logfile
        if($sync){
            $sync.Form.Dispatcher.Invoke([action]{$sync.install.Content = "Start Install"},"Normal")
            $sync.Form.Dispatcher.Invoke([action]{$sync.InstallUpgrade.Content = "Upgrade Installs"},"Normal")
        }
    }

    #===========================================================================
    # Tab 2 - Tweaks Buttons
    #===========================================================================

    $Sync.GUITweaks = {
        Param(
            $Tweakstorun
        )

        if($Tweakstorun -eq $null){
            [System.Windows.MessageBox]::Show("Please check the tweaks you wish to run",'Nothing to do',"OK","Info")
            return
        }

        $sync.form.Dispatcher.Invoke([action]{$sync.tweakcheck = $sync.tweaksbutton.Content},"Normal")
        If($sync.tweakcheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Tweaks are in progress',"OK","Info")
            return
        }

        $sync.Form.Dispatcher.Invoke([action]{$sync.tweaksbutton.Content = "Running"},"Normal")

        $params = @{
            ScriptBlock = $sync.ScriptTweaks
            ArgumentList = ("$Tweakstorun")
            ErrorAction = "Continue"
            ErrorVariable = "FAILURE"
            WarningAction = "Continue"
            WarningVariable = "WARNING"
        }
        
        Invoke-Runspace @params
        
        $sync.Form.Dispatcher.Invoke([action]{$sync.tweaksbutton.Content = "Run Tweaks"},"Normal")

        if($FAILURE -or $WARNING){
            [System.Windows.MessageBox]::Show("Unable to properly run installs, please investigate the logs located at $($sync.logfile)",'Installer ran into an issue!',"OK","Warning")
        }
        Else{
            [System.Windows.MessageBox]::Show("Tweaks haved completed!",'Installs are done!',"OK","Info")
        }
    }

    $Sync.ScriptTweaks = {
        Param(
            $Tweakstorun
        )
        if ($Tweakstorun -like "*,*"){$Tweakstorun = $Tweakstorun -split ","}
        else {$Tweakstorun = $Tweakstorun -split " "}

        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }
        
        Foreach($tweak in $tweakstorun){
            
            Write-Logs -Level INFO -Message "Running modifications for $tweak" -LogPath $sync.logfile

            #registry modification
            Foreach ($registries in $($sync.tweaks.$tweak.registry)){
                foreach($registry in $registries){
                    if(!(Test-Path $registry.path)){
                        Try{
                            Write-Logs -Level INFO -Message "$($registry.path) did not exist. Creating" -LogPath $sync.logfile
                            New-Item -Path $registry.path -ErrorAction stop -Force | Out-Null
                        }Catch{Write-Logs -Level ERROR -Message "$($registry.path) Failed to create" -LogPath $sync.logfile}
                    }
                    Try{
                        Write-Logs -Level INFO -Message "Setting $("$($registry.path)\$($registry.name)") to $($registry.value)" -LogPath $sync.logfile
                        Set-ItemProperty -Path $registry.path -Name $registry.name -Type $registry.type -Value $registry.value
                    }Catch{Write-Logs -Level ERROR -Message "$("$($registry.path)\$($registry.name)") was not set" -LogPath $sync.logfile}
                }
            }
            Write-Logs -Level INFO -Message "Finished setting registry" -LogPath $sync.logfile

            #Services modification 
            Foreach ($services in $($sync.tweaks.$tweak.service)){
                foreach($service in $services) {
                    Try{
                        Stop-Service "$($service.name)" -ErrorVariable serviceerror -ErrorAction stop
                        Set-Service "$($service.name)" -StartupType $($service.StartupType) -ErrorVariable serviceerror -ErrorAction stop
                        Write-Logs -Level INFO -Message "Service $($service.name) set to  $($service.StartupType)" -LogPath $sync.logfile
                    }Catch{
                        if($serviceerror -like "*Cannot find any service with service name*"){
                            Write-Logs -Level INFO -Message "Service $($service.name) not found" -LogPath $sync.logfile
                        }else{Write-Logs -Level ERROR -Message "Unable to modify Service $($service.name)" -LogPath $sync.logfile}
                    }
                }
            }
            Write-Logs -Level INFO -Message "Finished setting Services" -LogPath $sync.logfile

            #Scheduled Tasks Modification
            Foreach ($ScheduledTasks in $($sync.tweaks.$tweak.ScheduledTask)){
                foreach($ScheduledTask in $ScheduledTasks) {
                    Try{
                        if($($ScheduledTask.State) -eq "Disabled"){
                            Disable-ScheduledTask -TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                        }
                        if($($ScheduledTask.State) -eq "Enabled"){
                            Enable-TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                        }
                        Write-Logs -Level INFO -Message "Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.State)" -LogPath $sync.logfile
                    }Catch{Write-Logs -Level ERROR -Message "Unable to set Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.State)" -LogPath $sync.logfile}
                }
            }
            Write-Logs -Level INFO -Message "Finished setting Scheduled Tasks" -LogPath $sync.logfile            

            #Remove Bloatware
            Foreach ($apps in $($sync.tweaks.$tweak.appx)){
                foreach($app in $apps) {
                    Try{
                        Get-AppxPackage -Name $app| Remove-AppxPackage -ErrorAction Stop
                        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -ErrorAction stop -Online
                        Write-Logs -Level INFO -Message "Uninstalled $app" -LogPath $sync.logfile
                    }Catch{Write-Logs -Level ERROR -Message "Failed to uninstall $app" -LogPath $sync.logfile }
                }
            }
            Write-Logs -Level INFO -Message "Finished removing bloat apps" -LogPath $sync.logfile 

            #old code that didn't work inside json file cleanly. Will investigate ways to get around this
            if ($tweak -eq "EssTweaksOO"){
                Import-Module BitsTransfer
                Start-BitsTransfer -Source "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -Destination ooshutup10.cfg
                Start-BitsTransfer -Source "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -Destination OOSU10.exe
                ./OOSU10.exe ooshutup10.cfg /quiet
            }        
            if ($tweak -eq "EssTweaksRP"){
                Enable-ComputerRestore -Drive "C:\"
                Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
            }        
            if ($tweak -eq "EssTweaksStorage"){
                Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Recurse -ErrorAction SilentlyContinue
            }
            if ($tweak -eq "EssTweaksTele"){

                Write-Host "Enabling F8 boot menu options..."
                bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null
        
                # Task Manager Details
                If ((get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
                    Write-Host "Showing task manager details..."
                    $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
                    Do {
                        Start-Sleep -Milliseconds 100
                        $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
                    } Until ($preferences)
                    Stop-Process $taskmgr
                    $preferences.Preferences[28] = 0
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences
                } else {Write-Host "Task Manager patch not run in builds 22557+ due to bug"}

                Write-Host "Hiding 3D Objects icon from This PC..."
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue  
                
                # Group svchost.exe processes
                $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force                
        
                Write-Host "Removing AutoLogger file and restricting directory..."
                $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
                If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
                    Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
                }
                icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
            }
            if ($tweak -eq "MiscTweaksLapNum"){
                If (!(Test-Path "HKU:")) {
                    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
                }
                Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
            }
            if ($tweak -eq "MiscTweaksNum"){
                If (!(Test-Path "HKU:")) {
                    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
                }
                Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 2
            }
            if ($tweak -eq "MiscTweaksDisplay"){
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
            }
        }
        Write-Logs -Level INFO -Message "Finished setting tweaks" -LogPath $sync.logfile
    }

    $Sync.GUIUndoTweaks = {
        
        If($sync.undoall.Content -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Tweaks are in progress',"OK","Info")
            return
        }

        $sync.undoall.Content = "Running"

        Invoke-Runspace $sync.ScriptUndoTweaks
    }

    $sync.ScriptUndoTweaks = {
        
        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }

        Write-Logs -Level INFO -Message "Creating Restore Point incase something bad happens" -LogPath $sync.logfile
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"

        foreach ($tweak in $($sync.tweaks.psobject.properties)) {

                #registry reset
                Foreach ($registries in $($tweak.value.registry)){
                    foreach($registry in $registries){
                        Try{
                            Write-Logs -Level INFO -Message "Setting $("$($registry.path)\$($registry.name)") to $($registry.OriginalValue)" -LogPath $sync.logfile
                            Set-ItemProperty -Path $registry.path -Name $registry.name -Type $registry.type -Value $registry.OriginalValue
                        }Catch{Write-Logs -Level ERROR -Message "$("$($registry.path)\$($registry.name)") was not set" -LogPath $sync.logfile}
                    }
                }
                Write-Logs -Level INFO -Message "Finished reseting $($tweak.name) registries" -LogPath $sync.logfile

                #Services modification 
                Foreach ($services in $($tweak.value.service)){
                    foreach($service in $services) {
                        Try{
                            Stop-Service "$($service.name)" -ErrorVariable serviceerror -ErrorAction stop
                            Set-Service "$($service.name)" -StartupType $($service.OriginalType) -ErrorVariable serviceerror -ErrorAction stop
                            Write-Logs -Level INFO -Message "Service $($service.name) set to  $($service.OriginalType)" -LogPath $sync.logfile
                        }Catch{
                            if($serviceerror -like "*Cannot find any service with service name*"){
                                Write-Logs -Level INFO -Message "Service $($service.name) not found" -LogPath $sync.logfile
                            }else{Write-Logs -Level ERROR -Message "Unable to modify Service $($service.name)" -LogPath $sync.logfile}
                        }
                    }
                }
                Write-Logs -Level INFO -Message "Finished reseting $($tweak.name) Services" -LogPath $sync.logfile

                #Scheduled Tasks Modification
                Foreach ($ScheduledTasks in $($tweak.value.ScheduledTask)){
                    foreach($ScheduledTask in $ScheduledTasks) {
                        Try{
                            if($($ScheduledTask.OriginalState) -eq "Disabled"){
                                Disable-ScheduledTask -TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                            }
                            if($($ScheduledTask.OriginalState) -eq "Enabled"){
                                Enable-TaskName "$($ScheduledTask.name)" -ErrorAction Stop | Out-Null
                            }
                            Write-Logs -Level INFO -Message "Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.OriginalState)" -LogPath $sync.logfile
                        }Catch{Write-Logs -Level ERROR -Message "Unable to set Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.OriginalState)" -LogPath $sync.logfile}
                    }
                }
                Write-Logs -Level INFO -Message "Finished reseting $($tweak.name) Scheduled Tasks" -LogPath $sync.logfile                  
        }

        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 1
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -ErrorAction SilentlyContinue
        
        If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Recurse -ErrorAction SilentlyContinue
        }
        If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
        }
        If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Recurse -ErrorAction SilentlyContinue
        }
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
        }

        Write-Logs -Level INFO -Message "Unrestricting AutoLogger directory" -LogPath $sync.logfile
        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        icacls $autoLoggerDir /grant:r SYSTEM:`(OI`)`(CI`)F | Out-Null

        Write-Logs -Level INFO -Message "Reset Local Group Policies to Stock Defaults" -LogPath $sync.logfile        
        # cmd /c secedit /configure /cfg %windir%\inf\defltbase.inf /db defltbase.sdb /verbose
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicy"
        cmd /c gpupdate /force

        Write-Logs -Level INFO -Message "Restoring Clipboard History..." -LogPath $sync.logfile        
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158,30,7,128,18,0,0,0))

        if($sync.undoall){
            $sync.Form.Dispatcher.Invoke([action]{$sync.undoall.Content = "Undo All Tweaks"},"Normal") 
            [System.Windows.MessageBox]::Show("All tweaks have been removed",'Undo is done!',"OK","Info")
        }
    }

    #===========================================================================
    # Tab 3 - Config Buttons
    #===========================================================================

    $Sync.GUIFeatures = {
        Param($featuretoinstall)
        
        if($featuretoinstall -notlike "*feature*"){
            [System.Windows.MessageBox]::Show("Please check the features you wish to run",'Nothing to do',"OK","Info")
            return
        }

        #$sync.form.Dispatcher.Invoke([action]{$sync.featurecheck = $sync.FeatureInstall.Content},"Normal")
        If($sync.FeatureInstall.Content -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Tweaks are in progress',"OK","Info")
            return
        }

        $sync.FeatureInstall.Content = "Running"
        [System.Windows.MessageBox]::Show("$featuretoinstall",'Tweaks are in progress',"OK","Info")
        Invoke-Runspace $sync.ScriptInstallFeatures $featuretoinstall
    }

    $sync.ScriptFeatureInstall = {
        param ($featuretoinstall)
        if ($featuretoinstall -like "*,*"){$featuretoinstall = $featuretoinstall -split ","}
        else {$featuretoinstall = $featuretoinstall -split " "}
        [System.Windows.MessageBox]::Show("$featuretoinstall",'Tweaks are in progress',"OK","Info")
        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }
        
        Foreach ($feature in $featuretoinstall){

            $sync.feature.$feature | ForEach-Object {
                Try{
                    Write-Logs -Level INFO -Message "Installing Windows Feature $psitem" -LogPath $sync.logfile
                    Enable-WindowsOptionalFeature -Online -FeatureName "$psitem" -All -ErrorAction Stop
                    Write-output $psitem
                }Catch{Write-Logs -Level ERROR -Message "Failed to install $psitem" -LogPath $sync.logfile}

            }

        }

        Write-Logs -Level INFO -Message "Finished Installing features" -LogPath $sync.logfile

        if($sync.FeatureInstall){
            $sync.Form.Dispatcher.Invoke([action]{$sync.FeatureInstall.Content = "Install Features"},"Normal") 
            [System.Windows.MessageBox]::Show("Features have been installed",'Installs are done!',"OK","Info")
        }
        
    }

        <# TODO Make sure this works in a runspace/elevated shell

        If ( $Featuresdotnet.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx4-AdvSrvs" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All
        }
        If ( $Featureshyperv.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Tools-All" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-PowerShell" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Hypervisor" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Services" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-Clients" -All
            cmd /c bcdedit /set hypervisorschedulertype classic
            Write-Host "HyperV is now installed and configured. Please Reboot before using."
        } 
        If ( $Featureslegacymedia.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "MediaPlayback" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "LegacyComponents" -All
        }
        If ( $Featurewsl.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -All
            Write-Host "WSL is now installed and configured. Please Reboot before using."
        }
        If ( $Featurenfs.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All
            Enable-WindowsOptionalFeature -Online -FeatureName "NFS-Administration" -All
            nfsadmin client stop
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousUID" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousGID" -Type DWord -Value 0
            nfsadmin client start
            nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i
            Write-Host "NFS is now setup for user based NFS mounts"
        }

        
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "All features are now installed"
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)

        $sync.Form.Dispatcher.Invoke([action]{$sync.FeatureInstall.Content = "Install Features"},"Normal")
    }#>

    #===========================================================================
    # Tab 4 - Updates Buttons
    #===========================================================================
    
    $Updatesdefault = {

        $sync.form.Dispatcher.Invoke([action]{$sync.Updatesdefaultcheck = $sync.Updatesdefault.Content},"Normal")
        If($sync.Updatesdefaultcheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatesdefault.Content = "Running"},"Normal")
        [System.Windows.MessageBox]::Show("Updates Default",'I am going to install the defauly Updates',"OK","Info")

        <#TODO Make sure this works in runspace/elevate to admin shell
        # Source: https://github.com/rgl/windows-vagrant/blob/master/disable-windows-updates.ps1 reversed! 
        Set-StrictMode -Version Latest
        $ProgressPreference = 'SilentlyContinue'
        $ErrorActionPreference = 'Stop'
        trap {
            Write-Host
            Write-Host "ERROR: $_"
            Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
            Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
            Write-Host
            Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
            Start-Sleep -Seconds (60*60)
            Exit 1
        }

        # disable automatic updates.
        # XXX this does not seem to work anymore.
        # see How to configure automatic updates by using Group Policy or registry settings
        #     at https://support.microsoft.com/en-us/help/328010
        function New-Directory($path) {
            $p, $components = $path -split '[\\/]'
            $components | ForEach-Object {
                $p = "$p\$_"
                if (!(Test-Path $p)) {
                    New-Item -ItemType Directory $p | Out-Null
                }
            }
            $null
        }
        $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        New-Directory $auPath 
        # set NoAutoUpdate.
        # 0: Automatic Updates is enabled (default).
        # 1: Automatic Updates is disabled.
        New-ItemProperty `
            -Path $auPath `
            -Name NoAutoUpdate `
            -Value 0 `
            -PropertyType DWORD `
            -Force `
            | Out-Null
        # set AUOptions.
        # 1: Keep my computer up to date has been disabled in Automatic Updates.
        # 2: Notify of download and installation.
        # 3: Automatically download and notify of installation.
        # 4: Automatically download and scheduled installation.
        New-ItemProperty `
            -Path $auPath `
            -Name AUOptions `
            -Value 3 `
            -PropertyType DWORD `
            -Force `
            | Out-Null

        # disable Windows Update Delivery Optimization.
        # NB this applies to Windows 10.
        # 0: Disabled
        # 1: PCs on my local network
        # 3: PCs on my local network, and PCs on the Internet
        $deliveryOptimizationPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'
        if (Test-Path $deliveryOptimizationPath) {
            New-ItemProperty `
                -Path $deliveryOptimizationPath `
                -Name DODownloadMode `
                -Value 0 `
                -PropertyType DWORD `
                -Force `
                | Out-Null
        }
        # Service tweaks for Windows Update

        $services = @(
            "BITS"
            "wuauserv"
        )

        foreach ($service in $services) {
            # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist

            Write-Host "Setting $service StartupType to Automatic"
            Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Automatic
        }
        Write-Host "Enabling driver offering through Windows Update..."
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
        Write-Host "Enabling Windows Update automatic restart..."
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -ErrorAction SilentlyContinue
        Write-Host "Enabled driver offering through Windows Update"
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays " -ErrorAction SilentlyContinue
        
        ### Reset Windows Update Script - reregister dlls, services, and remove registry entires.
        Write-Host "1. Stopping Windows Update Services..." 
        Stop-Service -Name BITS 
        Stop-Service -Name wuauserv 
        Stop-Service -Name appidsvc 
        Stop-Service -Name cryptsvc 
        
        Write-Host "2. Remove QMGR Data file..." 
        Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue 
        
        Write-Host "3. Renaming the Software Distribution and CatRoot Folder..." 
        Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction SilentlyContinue 
        Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction SilentlyContinue 
        
        Write-Host "4. Removing old Windows Update log..." 
        Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue 
        
        Write-Host "5. Resetting the Windows Update Services to defualt settings..." 
        "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
        "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
        
        Set-Location $env:systemroot\system32 
        
        Write-Host "6. Registering some DLLs..." 
        regsvr32.exe /s atl.dll 
        regsvr32.exe /s urlmon.dll 
        regsvr32.exe /s mshtml.dll 
        regsvr32.exe /s shdocvw.dll 
        regsvr32.exe /s browseui.dll 
        regsvr32.exe /s jscript.dll 
        regsvr32.exe /s vbscript.dll 
        regsvr32.exe /s scrrun.dll 
        regsvr32.exe /s msxml.dll 
        regsvr32.exe /s msxml3.dll 
        regsvr32.exe /s msxml6.dll 
        regsvr32.exe /s actxprxy.dll 
        regsvr32.exe /s softpub.dll 
        regsvr32.exe /s wintrust.dll 
        regsvr32.exe /s dssenh.dll 
        regsvr32.exe /s rsaenh.dll 
        regsvr32.exe /s gpkcsp.dll 
        regsvr32.exe /s sccbase.dll 
        regsvr32.exe /s slbcsp.dll 
        regsvr32.exe /s cryptdlg.dll 
        regsvr32.exe /s oleaut32.dll 
        regsvr32.exe /s ole32.dll 
        regsvr32.exe /s shell32.dll 
        regsvr32.exe /s initpki.dll 
        regsvr32.exe /s wuapi.dll 
        regsvr32.exe /s wuaueng.dll 
        regsvr32.exe /s wuaueng1.dll 
        regsvr32.exe /s wucltui.dll 
        regsvr32.exe /s wups.dll 
        regsvr32.exe /s wups2.dll 
        regsvr32.exe /s wuweb.dll 
        regsvr32.exe /s qmgr.dll 
        regsvr32.exe /s qmgrprxy.dll 
        regsvr32.exe /s wucltux.dll 
        regsvr32.exe /s muweb.dll 
        regsvr32.exe /s wuwebv.dll 
        
        Write-Host "7) Removing WSUS client settings..." 
        REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
        REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
        REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 
        
        Write-Host "8) Resetting the WinSock..." 
        netsh winsock reset 
        netsh winhttp reset proxy 
        
        Write-Host "9) Delete all BITS jobs..." 
        Get-BitsTransfer | Remove-BitsTransfer 
        
        Write-Host "10) Attempting to install the Windows Update Agent..." 
        if($arch -eq 64){ 
            wusa Windows8-RT-KB2937636-x64 /quiet 
        } 
        else{ 
            wusa Windows8-RT-KB2937636-x86 /quiet 
        } 
        
        Write-Host "11) Starting Windows Update Services..." 
        Start-Service -Name BITS 
        Start-Service -Name wuauserv 
        Start-Service -Name appidsvc 
        Start-Service -Name cryptsvc 
        
        Write-Host "12) Forcing discovery..." 
        wuauclt /resetauthorization /detectnow 
        
        Write-Host "Process complete. Please reboot your computer."
        #>
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Reset Windows Update "
        $Messageboxbody = ("Stock settings loaded.`n Please reboot your computer")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
        
        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatesdefault.Content = "Default (Out of Box) Settings"},"Normal")
    }

    $Updatesdisable = {

        $sync.form.Dispatcher.Invoke([action]{$sync.Updatesdisablecheck = $sync.Updatesdisable.Content},"Normal")
        If($sync.Updatesdisablecheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatesdisable.Content = "Running"},"Normal")
        [System.Windows.MessageBox]::Show("Updates Disable",'I am going to install the disable Updates',"OK","Info")

        <#TODO Make sure this works in runspace/elevate to admin shell

        # Source: https://github.com/rgl/windows-vagrant/blob/master/disable-windows-updates.ps1
        Set-StrictMode -Version Latest
        $ProgressPreference = 'SilentlyContinue'
        $ErrorActionPreference = 'Stop'
        trap {
            Write-Host
            Write-Host "ERROR: $_"
            Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
            Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
            Write-Host
            Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
            Start-Sleep -Seconds (60*60)
            Exit 1
        }
        
        # disable automatic updates.
        # XXX this does not seem to work anymore.
        # see How to configure automatic updates by using Group Policy or registry settings
        #     at https://support.microsoft.com/en-us/help/328010
        function New-Directory($path) {
            $p, $components = $path -split '[\\/]'
            $components | ForEach-Object {
                $p = "$p\$_"
                if (!(Test-Path $p)) {
                    New-Item -ItemType Directory $p | Out-Null
                }
            }
            $null
        }
        $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        New-Directory $auPath 
        # set NoAutoUpdate.
        # 0: Automatic Updates is enabled (default).
        # 1: Automatic Updates is disabled.
        New-ItemProperty `
            -Path $auPath `
            -Name NoAutoUpdate `
            -Value 1 `
            -PropertyType DWORD `
            -Force `
            | Out-Null
        # set AUOptions.
        # 1: Keep my computer up to date has been disabled in Automatic Updates.
        # 2: Notify of download and installation.
        # 3: Automatically download and notify of installation.
        # 4: Automatically download and scheduled installation.
        New-ItemProperty `
            -Path $auPath `
            -Name AUOptions `
            -Value 1 `
            -PropertyType DWORD `
            -Force `
            | Out-Null
        
        # disable Windows Update Delivery Optimization.
        # NB this applies to Windows 10.
        # 0: Disabled
        # 1: PCs on my local network
        # 3: PCs on my local network, and PCs on the Internet
        $deliveryOptimizationPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'
        if (Test-Path $deliveryOptimizationPath) {
            New-ItemProperty `
                -Path $deliveryOptimizationPath `
                -Name DODownloadMode `
                -Value 0 `
                -PropertyType DWORD `
                -Force `
                | Out-Null
        }
        # Service tweaks for Windows Update
        
        $services = @(
            "BITS"
            "wuauserv"
        )
        
        foreach ($service in $services) {
            # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist
        
            Write-Host "Setting $service StartupType to Disabled"
            Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
        }

        #>
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Disable Windows Update "
        $Messageboxbody = ("Updates Disabled.`n Please reboot your computer")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
        
        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatesdisable.Content = "Disable ALL Updates (NOT RECOMMENDED!)"},"Normal")
    }

    $Updatessecurity = {

        $sync.form.Dispatcher.Invoke([action]{$sync.Updatessecuritycheck = $sync.Updatessecurity.Content},"Normal")
        If($sync.Updatessecuritycheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatessecurity.Content = "Running"},"Normal")
        [System.Windows.MessageBox]::Show("Updates Security",'I am going to install the Security Updates',"OK","Info")

        <#TODO Make sure this runs in a runspace and elevates to an admin prompt
        Write-Host "Disabling driver offering through Windows Update..."
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
        Write-Host "Disabling Windows Update automatic restart..."
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
        Write-Host "Disabled driver offering through Windows Update"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays " -Type DWord -Value 4

        #>

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Set Security Updates"
        $Messageboxbody = ("Recommended Update settings loaded")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
        
        $sync.Form.Dispatcher.Invoke([action]{$sync.Updatessecurity.Content = "Security (Recommended) Settings"},"Normal")

    }

#endregion Scripts

$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("sync", $sync)

#Get ComputerInfo in the background
Invoke-Runspace -ScriptBlock {$sync.ComputerInfo = Get-ComputerInfo} | Out-Null

write-host ""                                                                                                                             
write-host "    CCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT   "
write-host " CCC::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T   "
write-host "CC:::::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T  "
write-host "C:::::CCCCCCCC::::CT:::::TT:::::::TT:::::TT:::::TT:::::::TT:::::T "
write-host "C:::::C       CCCCCCTTTTTT  T:::::T  TTTTTTTTTTTT  T:::::T  TTTTTT"
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C                     T:::::T                T:::::T        "
write-host "C:::::C       CCCCCC        T:::::T                T:::::T        "
write-host "C:::::CCCCCCCC::::C      TT:::::::TT            TT:::::::TT       "
write-host "CC:::::::::::::::C       T:::::::::T            T:::::::::T       "
write-host "CCC::::::::::::C         T:::::::::T            T:::::::::T       "
write-host "  CCCCCCCCCCCCC          TTTTTTTTTTT            TTTTTTTTTTT       "
write-host ""
write-host "====Chris Titus Tech====="
write-host "=====Windows Toolbox====="

$sync["Form"].ShowDialog() | out-null