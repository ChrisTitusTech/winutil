<#
.NOTES$ENV:TEMP
   Author      : @DeveloperDurp
   GitHub      : https://github.com/DeveloperDurp
   Version 0.0.1
#>

#region Variables
    $sync = [Hashtable]::Synchronized(@{})
    $sync.logfile = "$env:TEMP\winutil.log"
    
    $sync.taskrunning = $false
    $sync.taskmessage = "There is currently a task running. Please try again once previous task is complete."
    $sync.tasktitle = "Task in progress"

    $VerbosePreference = "Continue"

    #WinForms dependancies 
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

    #List of config files to import
    $configs = (
        "applications", 
        "tweaks",
        "preset", 
        "feature"
    )

    #Test for admin credentials
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $IsAdmin = $false
    }

    #To use local files run $env:environment = "dev" before starting the ps1 file
    if($env:environment -eq "dev"){

        if($IsAdmin -eq $false){
            [System.Windows.MessageBox]::Show("This application needs to be run as Admin",'Administrative privileges required',"OK","Info")
            return
        }
        
        $confirm = [System.Windows.MessageBox]::Show('$ENV:Evnronment is set to dev. Do you wish to load the dev environment?','Dev Environment tag detected',"YesNo","Info")
    }
    if($env:environment -eq "exe"){
        
        if($IsAdmin -eq $false){
            [System.Windows.MessageBox]::Show("This application needs to be run as Admin",'Administrative privileges required',"OK","Info")
            return
        }
        
        $confirm = "yes"
    }
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

        if($IsAdmin -eq $false){
            Write-Output "This application needs to be run as an administrator. Attempting relaunch"
            Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://christitus.com/win | iex"
            break
        }

        $inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/$branch/MainWindow.xaml")
        $configs | ForEach-Object {
            $sync["$psitem"] = Invoke-RestMethod "https://raw.githubusercontent.com/ChrisTitusTech/winutil/$branch/config/$psitem.json"
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

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}
 
#region Functions

    #===========================================================================
    # Button clicks
    #===========================================================================
    
    #Gives every button the invoke-button function
    $sync.keys | ForEach-Object {
        if($sync.$psitem){
            if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
                $sync["$psitem"].Add_Click({
                    [System.Object]$Sender = $args[0]
                    Invoke-Button $Sender.name
                })
            }
        }
    }

    function Invoke-Button {

        <#
        
            .DESCRIPTION
            Meant to make creating buttons easier. The above section will assign this function and pass the name of the button
            This way you can dictate what each button does from this function. 
        
        #>
        
        Param ([string]$Button) 
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
            "Updates*" {Invoke-command $sync.GUIUpdates -ArgumentList "$button"}
        }
    }

    function uncheckall {

        <#
        
            .DESCRIPTION
            Function is meant to find all checkboxes that are checked on the specefic tab and input them into a script.

            Outputed data will be the names of the checkboxes comma seperated. 

            "Installadvancedip,Installbitwarden"

            .EXAMPLE

            uncheckall "Install"
        
        #>

        param($group)

        if ($sync.taskrunning -eq $true){
            return
        }

        $sync.keys | Where-Object {$psitem -like "*$($group)?*" `
                                -and $psitem -notlike "$($group)Install" `
                                -and $psitem -notlike "*GUI*" `
                                -and $psitem -notlike "*Script*"
                            } | ForEach-Object {
            if ($sync["$psitem"].IsChecked -eq $true){
                $output += ",$psitem"
                $sync["$psitem"].IsChecked = $false
            }
        }
        
        if($output){Write-Output $output.Substring(1)}
    }

    function Invoke-Runspace {

        <#
        
            .DESCRIPTION
            Simple function to make it easier to invoke a runspace from inside the script. 

            .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "Installadvancedip,Installbitwarden"
                Verbose = $true
            }

            Invoke-Runspace @params
        
        #>

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

        <#
        
            .DESCRIPTION
            Sole purpose of this fuction reduce duplicated code for switching between tabs. 
        
        #>

        Param ($button)
        $x = [int]($button -replace "Tab","" -replace "BT","") - 1

        0..3 | ForEach-Object {
            
            if ($x -eq $psitem){$sync["TabNav"].Items[$psitem].IsSelected = $true}
            else{$sync["TabNav"].Items[$psitem].IsSelected = $false}
        }
    }

    Function Tweak-Buttons {

        <#
        
            .DESCRIPTION
            Meant to make settings presets easier in the tweaks tab. Will pull the data from config/preset.json
        
        #>

        Param ($button)
        $preset = $sync.preset.$button

        $sync.keys | Where-Object {$psitem -like "*tweaks?*" -and $psitem -notlike "tweaksbutton"} | ForEach-Object {
            if ($preset -contains $psitem ){$sync["$psitem"].IsChecked = $True}
            Else{$sync["$psitem"].IsChecked = $false} 
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
            $LogPath = "$env:TEMP\winutil.log"
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

        #Check if any check boxes have been checked and if a task is currently running

            if ($sync.taskrunning -eq $true){
                [System.Windows.MessageBox]::Show($sync.taskmessage,$sync.tasktitle,"OK","Info")
                return
            }

            if($programstoinstall -notlike "*install*"){
                [System.Windows.MessageBox]::Show("Please check the applications you wish to install",'Nothing to do',"OK","Info")
                return
            }

            $sync.taskrunning = $true

        #Section to see if winget will upgrade all installs or which winget commands to run from  config/applications.json
        
            $programstoinstall = $programstoinstall -split ","

            if($programstoinstall -eq "Upgrade"){
                $winget = ",Upgrade"
            }
            else{
                foreach ($program in $programstoinstall){

                    $($sync.applications.install.$program.winget) -split ";" | ForEach-Object {
                        if($psitem){
                            $winget += ",$psitem"
                        }Else{
                            Invoke-command $sync.WriteLogs -ArgumentList ("WARNING","$Program Not found") 
                        }
                    }
                }
            }
            
            if($winget -eq $null){
                [System.Windows.MessageBox]::Show("No found applications to install",'Nothing to do',"OK","Info")
                return
            }            

        #Invoke a runspace so that the GUI does not lock up

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "$($winget.substring(1))"
                Verbose = $true
            }
            Invoke-Runspace @params

    }

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
                        Start-BitsTransfer -Source "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -Destination "$ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop
                        Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Destination "$ENV:TEMP/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ErrorAction Stop
                        Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/b0a0692da1034339b76dce1c298a1e42_License1.xml" -Destination "$ENV:TEMP/b0a0692da1034339b76dce1c298a1e42_License1.xml" -ErrorAction Stop
        
                        #Installing Packages
                        $step = "Installing Packages"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Add-AppxProvisionedPackage -Online -PackagePath "$ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx" -SkipLicense -ErrorAction Stop
                        Add-AppxProvisionedPackage -Online -PackagePath "$ENV:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -LicensePath "$ENV:TEMP\b0a0692da1034339b76dce1c298a1e42_License1.xml" -ErrorAction Stop
                        
                        #Sleep for 5 seconds to maximize chance that winget will work without reboot
                        Start-Sleep -s 5
        
                        #Removing no longer needed Files
                        $step = "Removing Files"
                        Write-Logs -Level INFO -Message $step -LogPath $sync.logfile
                        Remove-Item -Path "$ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx" -Force
                        Remove-Item -Path "$ENV:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force
                        Remove-Item -Path "$ENV:TEMP\b0a0692da1034339b76dce1c298a1e42_License1.xml" -Force

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
        if($sync["Form"]){
            $sync.taskrunning = $false
            [System.Windows.MessageBox]::Show("All applications have been installed",'Installs are done!',"OK","Info")
        }
    }

    #===========================================================================
    # Tab 2 - Tweaks Buttons
    #===========================================================================

    <#

        This section is working as expected and logs output to console and $ENV:Temp\winutil.log

        TODO: Error Handling as Try blocks and -erroraction stop causes runspace to lock up
    
    #>

    $Sync.GUITweaks = {

        <#

            .DESCRIPTION
            This Scriptblock is meant to be ran from inside the GUI and will prevent the user from starting another install task. 

            Input data will look like below and link with the name of the check box. This will then look to the config/applications.json file to find
            the modifications for the selected task.

            EssTweaksDeBloat,MiscTweaksUTC

            .EXAMPLE

            Invoke-command $sync.GUIInstallPrograms -ArgumentList "EssTweaksDeBloat,MiscTweaksUTC"

        #>

        Param($Tweakstorun)

        #Check if any check boxes have been checked and if a task is currently running

            if ($sync.taskrunning -eq $true){
                [System.Windows.MessageBox]::Show($sync.taskmessage,$sync.tasktitle,"OK","Info")
                return
            }

            if($Tweakstorun -notlike "*Tweaks*"){
                [System.Windows.MessageBox]::Show("Please check the applications you wish to install",'Nothing to do',"OK","Info")
                return
            }

            $sync.taskrunning = $true

        #Invoke a runspace so that the GUI does not lock up

            $params = @{
                ScriptBlock = $sync.ScriptTweaks
                ArgumentList = ("$Tweakstorun")
            }
            
            Invoke-Runspace @params
    
    }

    $Sync.ScriptTweaks = {

        <#

            .DESCRIPTION
            This scriptblock will run a series of modifications included in the config/tweaks.json file. 

            TODO: Figure out error handling as any errors in this runspace will crash the powershell session.

            .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptsInstallPrograms
                ArgumentList = "EssTweaksTele,EssTweaksServices"
                Verbose = $true
            }
            VerbosePreference = "Continue"
            Invoke-Command @params

        #>

        Param($Tweakstorun)
        $Tweakstorun = $Tweakstorun -split ","

        $ErrorActionPreference = "SilentlyContinue"

        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }

        Write-Logs -Level INFO -Message "Gathering required modifications" -LogPath $sync.logfile

        $RegistryToModify = $Tweakstorun | ForEach-Object {
            $sync.tweaks.$psitem.registry
        }

        $ServicesToModify = $Tweakstorun | ForEach-Object {
            $sync.tweaks.$psitem.service
        }

        $ScheduledTaskToModify = $Tweakstorun | ForEach-Object {
            $sync.tweaks.$psitem.ScheduledTask
        }

        $AppxToModify = $Tweakstorun | ForEach-Object {
            $sync.tweaks.$psitem.appx
        }
    
        $ScriptsToRun = $Tweakstorun | ForEach-Object {
            $sync.tweaks.$psitem.InvokeScript
        }

        if($RegistryToModify){
            Write-Logs -Level INFO -Message "Starting Registry Modification" -LogPath $sync.logfile

            $RegistryToModify | ForEach-Object {
                if(!(Test-Path $psitem.path)){
                    $Step = "create"
                    Write-Logs -Level INFO -Message "$($psitem.path) did not exist. Creating" -LogPath $sync.logfile
                    New-Item -Path $psitem.path -Force | Out-Null
                }

                $step = "set"
                Write-Logs -Level INFO -Message "Setting $("$($psitem.path)\$($psitem.name)") to $($psitem.value)" -LogPath $sync.logfile
                Set-ItemProperty -Path $psitem.path -Name $psitem.name -Type $psitem.type -Value $psitem.value
            }

            Write-Logs -Level INFO -Message "Finished setting registry" -LogPath $sync.logfile
        }

        if($ServicesToModify){
            Write-Logs -Level INFO -Message "Starting Services Modification" -LogPath $sync.logfile

            $ServicesToModify | ForEach-Object {
                    Stop-Service "$($psitem.name)" 
                    Set-Service "$($psitem.name)" -StartupType $($psitem.StartupType)
                    Write-Logs -Level INFO -Message "Service $($psitem.name) set to  $($psitem.StartupType)" -LogPath $sync.logfile
            }
    
            Write-Logs -Level INFO -Message "Finished setting Services" -LogPath $sync.logfile
        }
        
        if($ScheduledTaskToModify){
            Write-Logs -Level INFO -Message "Starting ScheduledTask Modification" -LogPath $sync.logfile

            $ScheduledTaskToModify | ForEach-Object {
                Try{
                    if($($psitem.State) -eq "Disabled"){
                        Disable-ScheduledTask -TaskName "$($psitem.name)" -ErrorAction Stop | Out-Null
                    }
                    if($($psitem.State) -eq "Enabled"){
                        Enable-TaskName "$($psitem.name)" -ErrorAction Stop | Out-Null
                    }
                    Write-Logs -Level INFO -Message "Scheduled Task $($psitem.name) set to  $($psitem.State)" -LogPath $sync.logfile
                }Catch{Write-Logs -Level ERROR -Message "Unable to set Scheduled Task $($psitem.name) set to  $($psitem.State)" -LogPath $sync.logfile}
            }
    
            Write-Logs -Level INFO -Message "Finished setting ScheduledTasks" -LogPath $sync.logfile
        }

        if($AppxToModify){
            Write-Logs -Level INFO -Message "Starting Appx Modification" -LogPath $sync.logfile

            $AppxToModify | ForEach-Object {
                Try{
                    Get-AppxPackage -Name $psitem| Remove-AppxPackage -ErrorAction Stop
                    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $psitem | Remove-AppxProvisionedPackage -ErrorAction stop -Online
                    Write-Logs -Level INFO -Message "Uninstalled $psitem" -LogPath $sync.logfile
                }Catch{Write-Logs -Level ERROR -Message "Failed to uninstall $psitem" -LogPath $sync.logfile }
            }
    
            Write-Logs -Level INFO -Message "Finished uninstalling Appx" -LogPath $sync.logfile
        }

        if($ScriptsToRun){
            Write-Logs -Level INFO -Message "Running Scripts" -LogPath $sync.logfile

            $ScriptsToRun | ForEach-Object {
                $Scriptblock = [scriptblock]::Create($psitem)
                #Invoke-Command -ScriptBlock $Scriptblock
                Start-Process $PSHOME\powershell.exe -Verb runas -ArgumentList "-Command  $scriptblock" -Wait
            }
    
            Write-Logs -Level INFO -Message "Finished Scripts" -LogPath $sync.logfile
        }

        Write-Logs -Level INFO -Message "Tweaks finished" -LogPath $sync.logfile
        
        if($sync["Form"]){
            $sync.taskrunning = $false
            [System.Windows.MessageBox]::Show("All modifications have finished",'Tweaks are done!',"OK","Info")
        }
    }

    $Sync.GUIUndoTweaks = {

        <#

            .DESCRIPTION
            This Scriptblock is meant to be ran from inside the GUI and will prevent the user from starting another tweak task. 

            .EXAMPLE

            Invoke-command $sync.GUIUndoTweaks

        #>

        #Check if any check boxes have been checked and if a task is currently running

            if ($sync.taskrunning -eq $true){
                [System.Windows.MessageBox]::Show($sync.taskmessage,$sync.tasktitle,"OK","Info")
                return
            }

            $sync.taskrunning = $true

        #Invoke a runspace so that the GUI does not lock up            

            Invoke-Runspace $sync.ScriptUndoTweaks
    }

    $sync.ScriptUndoTweaks = {
        
        <#

            .DESCRIPTION
            This scriptblock will undo all modifications from this script. 

            TODO: Figure out error handling as any errors in this runspace will crash the powershell session.

            .EXAMPLE

            VerbosePreference = "Continue"
            Invoke-Command -ScriptBlock $sync.ScriptUndoTweaks
        #>

        $ErrorActionPreference = "SilentlyContinue"

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
                        Write-Logs -Level INFO -Message "Setting $("$($registry.path)\$($registry.name)") to $($registry.OriginalValue)" -LogPath $sync.logfile
                        Set-ItemProperty -Path $registry.path -Name $registry.name -Type $registry.type -Value $registry.OriginalValue
                    }
                }
                Write-Logs -Level INFO -Message "Finished reseting $($tweak.name) registries" -LogPath $sync.logfile

                #Services modification 
                Foreach ($services in $($tweak.value.service)){
                    foreach($service in $services) {
                        Stop-Service "$($service.name)"
                        Set-Service "$($service.name)" -StartupType $($service.OriginalType)
                        Write-Logs -Level INFO -Message "Service $($service.name) set to  $($service.OriginalType)" -LogPath $sync.logfile
                    }
                }
                Write-Logs -Level INFO -Message "Finished reseting $($tweak.name) Services" -LogPath $sync.logfile

                #Scheduled Tasks Modification
                Foreach ($ScheduledTasks in $($tweak.value.ScheduledTask)){
                    foreach($ScheduledTask in $ScheduledTasks) {
                        if($($ScheduledTask.OriginalState) -eq "Disabled"){
                            Disable-ScheduledTask -TaskName "$($ScheduledTask.name)" | Out-Null
                        }
                        if($($ScheduledTask.OriginalState) -eq "Enabled"){
                            Enable-TaskName "$($ScheduledTask.name)"  | Out-Null
                        }
                        Write-Logs -Level INFO -Message "Scheduled Task $($ScheduledTask.name) set to  $($ScheduledTask.OriginalState)" -LogPath $sync.logfile
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

        if($sync["Form"]){
            $sync.taskrunning = $false
            [System.Windows.MessageBox]::Show("All tweaks have been removed",'Undo is done!',"OK","Info")
        }
    }

    #===========================================================================
    # Tab 3 - Config Buttons
    #===========================================================================

    <#

        This section is working as expected and logs output to console and $ENV:Temp\winutil.log

        TODO: Error Handling as Try blocks and -erroraction stop causes runspace to lock up
    
    #>

    $Sync.GUIFeatures = {
        
        <#

            .DESCRIPTION
            This Scriptblock is meant to be ran from inside the GUI and will prevent the user from starting another install task. 

            Input data will look like below and link with the name of the check box. This will then look to the config/features.json file to find
            the install commands for the selected features.

            Featureshyperv,Featureslegacymedia

            .EXAMPLE

            Invoke-command $sync.GUIInstallPrograms -ArgumentList "Featureshyperv,Featureslegacymedia"

        #>
        
        param ($featuretoinstall)

        #Check if any check boxes have been checked and if a task is currently running 

            if ($sync.taskrunning -eq $true){
                [System.Windows.MessageBox]::Show($sync.taskmessage,$sync.tasktitle,"OK","Info")
                return
            }

            if($featuretoinstall -notlike "*Features*"){
                [System.Windows.MessageBox]::Show("Please check the features you wish to install",'Nothing to do',"OK","Info")
                return
            }

            $sync.taskrunning = $true

        #Invoke a runspace so that the GUI does not lock up  
            
            $params = @{
                ScriptBlock = $sync.ScriptFeatureInstall
                ArgumentList = ("$featuretoinstall")
            }
            
            Invoke-Runspace @params

    }

    $sync.ScriptFeatureInstall = {

        <#

            .DESCRIPTION
            This scriptblock will install the selected features from the config/features.json file. 

            TODO: Figure out error handling as any errors in this runspace will crash the powershell session.

            .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptFeatureInstall
                ArgumentList = "Featureshyperv,Featureslegacymedia"
                Verbose = $true
            }
            VerbosePreference = "Continue"
            Invoke-Command @params

        #>

        param ($featuretoinstall)

        $featuretoinstall = $featuretoinstall -split ","

        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }
        
        Foreach ($feature in $featuretoinstall){

            $sync.feature.$feature | ForEach-Object {
                Try{
                    Write-Logs -Level INFO -Message "Installing Windows Feature $psitem" -LogPath $sync.logfile
                    Enable-WindowsOptionalFeature -Online -FeatureName "$psitem" -All -NoRestart
                    Write-output $psitem
                }Catch{Write-Logs -Level ERROR -Message "Failed to install $psitem" -LogPath $sync.logfile}

            }

        }

        Write-Logs -Level INFO -Message "Finished Installing features" -LogPath $sync.logfile

        if($sync.FeatureInstall){
            $sync.taskrunning = $false
            [System.Windows.MessageBox]::Show("Features have been installed",'Installs are done!',"OK","Info")
        }
        
    }

    #===========================================================================
    # Tab 4 - Updates Buttons
    #===========================================================================
    
    $Sync.GUIUpdates = {
        
        <#

            .DESCRIPTION

            Current Options

            "Updatesdefault" 
            "Updatesdisable" 
            "Updatessecurity"

            .EXAMPLE

            Invoke-command $sync.GUIUpdates -ArgumentList "Updatesdefault"

        #>
        
        param ($updatestoconfigure)

        #Check if any check boxes have been checked and if a task is currently running 

            if ($sync.taskrunning -eq $true){
                [System.Windows.MessageBox]::Show($sync.taskmessage,$sync.tasktitle,"OK","Info")
                return
            }

            $sync.taskrunning = $true

        #Invoke a runspace so that the GUI does not lock up  
            
            $params = @{
                ScriptBlock = $sync.ScriptUpdates
                ArgumentList = ("$updatestoconfigure")
            }
            
            Invoke-Runspace @params

    }

    $sync.ScriptUpdates = {

        <#

            .DESCRIPTION
            This scriptblock will install the selected features from the config/features.json file. 

            TODO: Figure out error handling as any errors in this runspace will crash the powershell session.

            .EXAMPLE

            $params = @{
                ScriptBlock = $sync.ScriptFeatureInstall
                ArgumentList = "Featureshyperv,Featureslegacymedia"
                Verbose = $true
            }
            VerbosePreference = "Continue"
            Invoke-Command @params

        #>

        param ($updatestoconfigure)

        function Write-Logs {
            param($Level, $Message, $LogPath)
            Invoke-command $sync.WriteLogs -ArgumentList ($Level,$Message, $LogPath)
        }


        $Scriptblock = [scriptblock]::Create($psitem)
        #Invoke-Command -ScriptBlock $Scriptblock
        Start-Process $PSHOME\powershell.exe -Verb runas -ArgumentList "-Command  $scriptblock" -Wait
        

        if($sync["Form"]){
            $sync.taskrunning = $false
            [System.Windows.MessageBox]::Show("Updates have been configured",'Configuration is done!',"OK","Info")
        }
        
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

$runspace.close()

Write-Host "Thank you for using winutil!"

