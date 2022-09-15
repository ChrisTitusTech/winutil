<#
.NOTES
   Author      : @DeveloperDurp
   GitHub      : https://github.com/DeveloperDurp
   Version 0.0.1
#>

if ($IsLinux){ # PowerShell on Linux has that read-only bool variable set to $true
   Write-Host "This utility is exclusively designed for Windows"
   return
}

#region Variables
    $global:sync = [Hashtable]::Synchronized(@{})

    #WinForms dependencies 
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

    #To use local files run $env:environment = "dev" before starting the ps1 file
    if($env:environment -eq "dev"){
        $confirm = [System.Windows.MessageBox]::Show('$ENV:Environment is set to dev. Do you wish to load the dev environment?','Dev Environment tag detected',"YesNo","Info")
        if($confirm -eq "yes"){
            $inputXML = Get-Content "MainWindow.xaml"
            $global:sync["applications"] = Get-Content applications.json | ConvertFrom-Json
        }
    }
    else{
        $inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/MainWindow.xaml")
        $global:sync["applications"] = Invoke-RestMethod "https://raw.githubusercontent.com/ChrisTitusTech/winutil/test/applications.json"
    }

    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
    [xml]$XAML = $inputXML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    
    try{$global:sync["Form"]=[Windows.Markup.XamlReader]::Load( $reader )}
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
        write-host $error[0].Exception.Message -ForegroundColor Red
        if ($error[0].Exception.Message -like "*button*"){
            write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
    }
    catch{#if it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
        Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
    }

#endregion Variables
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$global:sync["$("$($_.Name)")"] = $global:sync["Form"].FindName($_.Name)}
 
#region Functions

    #===========================================================================
    # Button clicks
    #===========================================================================
    
    #Gives every button the invoke-button function
    $global:sync.keys | ForEach-Object {
        if($($sync["$_"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
            $global:sync["$_"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-Button $Sender.name
            })
        }
    }

    function Invoke-Button {
        Param ([string]$Button) 
        #[System.Windows.MessageBox]::Show("$button",'Button Value',"OK","Info")
        Switch -Wildcard ($Button){

            "*Tab*BT*" {switchtab $Button}
            "*InstallUpgrade*" {Invoke-Runspace $InstallUpgrade}
            "*desktop*" {Tweak-Buttons $Button}
            "*laptop*" {Tweak-Buttons $Button}
            "*minimal*" {Tweak-Buttons $Button}
            "*undoall*" {Invoke-Runspace $undotweaks}
            "install" {Invoke-Runspace $installprograms $(uncheckall "Install")}
            "tweaksbutton" {Invoke-Runspace $tweaks $(uncheckall "tweaks")}
            "FeatureInstall" {Invoke-Runspace $features $(uncheckall "feature")}
            "Panelcontrol" {cmd /c control}
            "Panelnetwork" {cmd /c ncpa.cpl}
            "Panelpower" {cmd /c powercfg.cpl}
            "Panelsound" {cmd /c mmsys.cpl}
            "Panelsystem" {cmd /c sysdm.cpl}
            "Paneluser" {cmd /c "control userpasswords2"}
            "Updatesdefault" {Invoke-Runspace $Updatesdefault}
            "Updatesdisable" {Invoke-Runspace $Updatesdisable}
            "Updatessecurity" {Invoke-Runspace $Updatessecurity}
        }
    }

    function uncheckall {
        param($group)
        $output = @()
        $global:sync.keys | Where-Object {$_ -like "*$($group)?*" -and $_ -notlike "$($group)Install" -and $_ -notlike "$($group)Install"} | ForEach-Object {
            if ($global:sync["$_"].IsChecked -eq $true){
                $output += $_
                $global:sync["$_"].IsChecked = $false
            }
        }
        Write-Output $output
    }

    function Invoke-Runspace {
        Param ([string]$commands,$arguments) 

        $Script = [PowerShell]::Create().AddScript($commands).AddArgument($arguments)

        $runspace = [RunspaceFactory]::CreateRunspace()
        $runspace.ApartmentState = "STA"
        $runspace.ThreadOptions = "ReuseThread"
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("sync", $global:sync)

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
            
            if ($x -eq $_){$global:sync["TabNav"].Items[$_].IsSelected = $true}
            else{$global:sync["TabNav"].Items[$_].IsSelected = $false}
        }
    }

    Function Tweak-Buttons {
        Param ($button)
        
        if ($button -eq "desktop"){
            $preset = @(
                "EssTweaksAH"
                "EssTweaksDVR"
                "EssTweaksHiber"
                "EssTweaksHome"
                "EssTweaksLoc"
                "EssTweaksOO"
                "EssTweaksRP"
                "EssTweaksServices"
                "EssTweaksStorage"
                "EssTweaksTele"
                "EssTweaksWifi"
                "MiscTweaksPower"
                "MiscTweaksNum"
            )
        }
        if ($button -eq "laptop"){
            $preset = @(
                "EssTweaksAH"
                "EssTweaksDVR"
                "EssTweaksHome"
                "EssTweaksLoc"
                "EssTweaksOO"
                "EssTweaksRP"
                "EssTweaksServices"
                "EssTweaksStorage"
                "EssTweaksTele"
                "EssTweaksWifi"
                "MiscTweaksLapPower"
                "MiscTweaksLapNum"
            )
        }
        if ($button -eq "minimal"){
            $preset = @(
                "EssTweaksHome"
                "EssTweaksOO"
                "EssTweaksRP"
                "EssTweaksServices"
                "EssTweaksTele"
            )
        }
        $global:sync.keys | Where-Object {$_ -like "*tweaks*" -and $_ -notlike "tweaksbutton"} | ForEach-Object {
            if ($preset -contains $_ ){$global:sync["$_"].IsChecked = $True}
            Else{$global:sync["$_"].IsChecked = $false} 
        }
    }

#endregion Functions

#region Scripts

    #===========================================================================
    # Install Tab
    #===========================================================================

    $installPrograms = {
        Param ($programstoinstall)

        if($programstoinstall -eq $null){
            [System.Windows.MessageBox]::Show("Please check the applications you wish to install",'Nothing to do',"OK","Info")
            return
        }

        $global:sync.form.Dispatcher.Invoke([action]{$sync.installcheck = $global:sync.install.Content},"Normal")
        If($sync.installcheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Installs are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.install.Content = "Running"},"Normal")      

        foreach ($program in $programstoinstall){

            [System.Windows.MessageBox]::Show("$($global:sync.applications.install.$program.winget)",'I am going to install this program',"OK","Info")

        }

        #TODO Convert this to work inside the runspace and elevate credentials
        <#
            # Install all winget programs in new window
            $wingetinstall.ToArray()
            # Define Output variable
            $wingetResult = New-Object System.Collections.Generic.List[System.Object]
            foreach ( $node in $wingetinstall )
            {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget install -e --accept-source-agreements --accept-package-agreements --silent $node | Out-Host" -Wait -WindowStyle Maximized
                $wingetResult.Add("$node`n")
            }
            $wingetResult.ToArray()
            $wingetResult | % { $_ } | Out-Host

            # Popup after finished
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Installed Programs "
            $Messageboxbody = ($wingetResult)
            $MessageIcon = [System.Windows.MessageBoxImage]::Information

            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
        #>
        
        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.install.Content = "Start Install"},"Normal")
        [System.Windows.MessageBox]::Show("Installs have completed!",'Installs are done!',"OK","Info")
    }

    $InstallUpgrade = {

        $global:sync.form.Dispatcher.Invoke([action]{$sync.InstallUpgradecheck = $global:sync.InstallUpgrade.Content},"Normal")
        If($sync.InstallUpgradecheck -like "Running"){
            [System.Windows.MessageBox]::Show("Updates are currently running",'Installs are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.InstallUpgrade.Content = "Running"},"Normal")
        Start-Sleep -Seconds 5
        #TODO Convert this to work inside the runspace
        <#
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget upgrade --all  | Out-Host" -Wait -WindowStyle Maximized
            
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Upgraded All Programs "
            $Messageboxbody = ("Done")
            $MessageIcon = [System.Windows.MessageBoxImage]::Information

            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
        #>

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.InstallUpgrade.Content = "Upgrade Installs"},"Normal")
        [System.Windows.MessageBox]::Show("Updates have completed!",'Updates are done!',"OK","Info")
    }

    #===========================================================================
    # Tab 2 - Tweaks Buttons
    #===========================================================================

    $tweaks = {
        Param($Tweakstorun)
        $global:sync.form.Dispatcher.Invoke([action]{$sync.tweakscheck = $global:sync.tweaksbutton.Content},"Normal")
        If($sync.tweakscheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Tweaks are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.tweaksbutton.Content = "Running"},"Normal")
        [System.Windows.MessageBox]::Show("$Tweakstorun",'I am going to install these tweaks',"OK","Info")
        
        <#TODO Get this to run in an elevated prompt if not already.

        Foreach($tweak in $tweakstorun){
            if ($tweak -eq "EssTweaksAH"){
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0
            }
            if ($tweak -eq "EssTweaksDVR"){
                Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type Hex -Value 00000000
                Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type Hex -Value 00000000
                Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type Hex -Value 00000000
                Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 00000000
            }
            if ($tweak -eq "EssTweaksHiber"){
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Type Dword -Value 0
                If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
                    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0
            }
            if ($tweak -eq "EssTweaksHome"){
                Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
                Set-Service "HomeGroupListener" -StartupType Manual
                Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
                Set-Service "HomeGroupProvider" -StartupType Manual
            }
            if ($tweak -eq "EssTweaksLoc"){
                If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
                    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Deny"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0
                Write-Host "Disabling automatic Maps updates..."
                Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 0
            }            
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
            if ($tweak -eq "EssTweaksServices"){
                $services = @(
                    "diagnosticshub.standardcollector.service"     # Microsoft (R) Diagnostics Hub Standard Collector Service
                    "DiagTrack"                                    # Diagnostics Tracking Service
                    "DPS"
                    "dmwappushservice"                             # WAP Push Message Routing Service (see known issues)
                    "lfsvc"                                        # Geolocation Service
                    "MapsBroker"                                   # Downloaded Maps Manager
                    "NetTcpPortSharing"                            # Net.Tcp Port Sharing Service
                    "RemoteAccess"                                 # Routing and Remote Access
                    "RemoteRegistry"                               # Remote Registry
                    "SharedAccess"                                 # Internet Connection Sharing (ICS)
                    "TrkWks"                                       # Distributed Link Tracking Client
                    #"WbioSrvc"                                     # Windows Biometric Service (required for Fingerprint reader / facial detection)
                    #"WlanSvc"                                      # WLAN AutoConfig
                    "WMPNetworkSvc"                                # Windows Media Player Network Sharing Service
                    #"wscsvc"                                       # Windows Security Center Service
                    "WSearch"                                      # Windows Search
                    "XblAuthManager"                               # Xbox Live Auth Manager
                    "XblGameSave"                                  # Xbox Live Game Save Service
                    "XboxNetApiSvc"                                # Xbox Live Networking Service
                    "XboxGipSvc"                                   #Disables Xbox Accessory Management Service
                    "ndu"                                          # Windows Network Data Usage Monitor
                    "WerSvc"                                       #disables windows error reporting
                    #"Spooler"                                      #Disables your printer
                    "Fax"                                          #Disables fax
                    "fhsvc"                                        #Disables fax history
                    "gupdate"                                      #Disables google update
                    "gupdatem"                                     #Disable another google update
                    "stisvc"                                       #Disables Windows Image Acquisition (WIA)
                    "AJRouter"                                     #Disables (needed for AllJoyn Router Service)
                    "MSDTC"                                        # Disables Distributed Transaction Coordinator
                    "WpcMonSvc"                                    #Disables Parental Controls
                    "PhoneSvc"                                     #Disables Phone Service(Manages the telephony state on the device)
                    "PrintNotify"                                  #Disables Windows printer notifications and extensions
                    "PcaSvc"                                       #Disables Program Compatibility Assistant Service
                    "WPDBusEnum"                                   #Disables Portable Device Enumerator Service
                    #"LicenseManager"                               #Disable LicenseManager(Windows store may not work properly)
                    "seclogon"                                     #Disables  Secondary Logon(disables other credentials only password will work)
                    "SysMain"                                      #Disables sysmain
                    "lmhosts"                                      #Disables TCP/IP NetBIOS Helper
                    "wisvc"                                        #Disables Windows Insider program(Windows Insider will not work)
                    "FontCache"                                    #Disables Windows font cache
                    "RetailDemo"                                   #Disables RetailDemo whic is often used when showing your device
                    "ALG"                                          # Disables Application Layer Gateway Service(Provides support for 3rd party protocol plug-ins for Internet Connection Sharing)
                    #"BFE"                                         #Disables Base Filtering Engine (BFE) (is a service that manages firewall and Internet Protocol security)
                    #"BrokerInfrastructure"                         #Disables Windows infrastructure service that controls which background tasks can run on the system.
                    "SCardSvr"                                      #Disables Windows smart card
                    "EntAppSvc"                                     #Disables enterprise application management.
                    "BthAvctpSvc"                                   #Disables AVCTP service (if you use  Bluetooth Audio Device or Wireless Headphones. then don't disable this)
                    #"FrameServer"                                   #Disables Windows Camera Frame Server(this allows multiple clients to access video frames from camera devices.)
                    "Browser"                                       #Disables computer browser
                    "BthAvctpSvc"                                   #AVCTP service (This is Audio Video Control Transport Protocol service.)
                    #"BDESVC"                                        #Disables bitlocker
                    "iphlpsvc"                                      #Disables ipv6 but most websites don't use ipv6 they use ipv4     
                    "edgeupdate"                                    # Disables one of edge update service  
                    "MicrosoftEdgeElevationService"                 # Disables one of edge  service 
                    "edgeupdatem"                                   # disbales another one of update service (disables edgeupdatem)                          
                    "SEMgrSvc"                                      #Disables Payments and NFC/SE Manager (Manages payments and Near Field Communication (NFC) based secure elements)
                    #"PNRPsvc"                                      # Disables peer Name Resolution Protocol ( some peer-to-peer and collaborative applications, such as Remote Assistance, may not function, Discord will still work)
                    #"p2psvc"                                       # Disbales Peer Name Resolution Protocol(nables multi-party communication using Peer-to-Peer Grouping.  If disabled, some applications, such as HomeGroup, may not function. Discord will still work)
                    #"p2pimsvc"                                     # Disables Peer Networking Identity Manager (Peer-to-Peer Grouping services may not function, and some applications, such as HomeGroup and Remote Assistance, may not function correctly.Discord will still work)
                    "PerfHost"                                      #Disables  remote users and 64-bit processes to query performance .
                    "BcastDVRUserService_48486de"                   #Disables GameDVR and Broadcast   is used for Game Recordings and Live Broadcasts
                    "CaptureService_48486de"                        #Disables ptional screen capture functionality for applications that call the Windows.Graphics.Capture API.  
                    "cbdhsvc_48486de"                               #Disables   cbdhsvc_48486de (clipboard service it disables)
                    #"BluetoothUserService_48486de"                  #disbales BluetoothUserService_48486de (The Bluetooth user service supports proper functionality of Bluetooth features relevant to each user session.)
                    "WpnService"                                    #Disables WpnService (Push Notifications may not work )
                    #"StorSvc"                                       #Disables StorSvc (usb external hard drive will not be reconised by windows)
                    "RtkBtManServ"                                  #Disables Realtek Bluetooth Device Manager Service
                    "QWAVE"                                         #Disables Quality Windows Audio Video Experience (audio and video might sound worse)
                    #Hp services
                    "HPAppHelperCap"
                    "HPDiagsCap"
                    "HPNetworkCap"
                    "HPSysInfoCap"
                    "HpTouchpointAnalyticsService"
                    #hyper-v services
                    "HvHost"                          
                    "vmickvpexchange"
                    "vmicguestinterface"
                    "vmicshutdown"
                    "vmicheartbeat"
                    "vmicvmsession"
                    "vmicrdv"
                    "vmictimesync" 
                    # Services which cannot be disabled
                    #"WdNisSvc"
                )
                
                foreach ($service in $services) {
                    # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist
                
                    Write-Host "Setting $service StartupType to Manual"
                    Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Manual
                }
            }
            if ($tweak -eq "EssTweaksStorage"){
                Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Recurse -ErrorAction SilentlyContinue
            }
            if ($tweak -eq "EssTweaksTele"){
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
                Write-Host "Disabling Application suggestions..."
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
                If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1
                Write-Host "Disabling Feedback..."
                If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
                    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null
                Write-Host "Disabling Tailored Experiences..."
                If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
                    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1
                Write-Host "Disabling Advertising ID..."
                If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) {
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1
                Write-Host "Disabling Error reporting..."
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null
                Write-Host "Restricting Windows Update P2P only to local network..."
                If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
                    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1
                Write-Host "Stopping and disabling Diagnostics Tracking Service..."
                Stop-Service "DiagTrack" -WarningAction SilentlyContinue
                Set-Service "DiagTrack" -StartupType Disabled
                Write-Host "Stopping and disabling WAP Push Service..."
                Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
                Set-Service "dmwappushservice" -StartupType Disabled
                Write-Host "Enabling F8 boot menu options..."
                bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null
                Write-Host "Disabling Remote Assistance..."
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0
                Write-Host "Stopping and disabling Superfetch service..."
                Stop-Service "SysMain" -WarningAction SilentlyContinue
                Set-Service "SysMain" -StartupType Disabled
        
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
        
                Write-Host "Showing file operations details..."
                If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) {
                    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" | Out-Null
                }
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 1
                Write-Host "Hiding Task View button..."
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0
                Write-Host "Hiding People icon..."
                If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
                    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
                }
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0
        
                Write-Host "Changing default Explorer view to This PC..."
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1
            
                Write-Host "Hiding 3D Objects icon from This PC..."
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue  
                
                ## Performance Tweaks and More Telemetry
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type DWord -Value 00000000
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type DWord -Value 0000000a
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type DWord -Value 0000000a
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type DWord -Value 2000
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "MenuShowDelay" -Type DWord -Value 0
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type DWord -Value 5000
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "HungAppTimeout" -Type DWord -Value 4000
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "AutoEndTasks" -Type DWord -Value 1
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type DWord -Value 00001000
                    Set-ItemProperty -Path "HKLM:\Control Panel\Desktop" -Name "WaitToKillServiceTimeout" -Type DWord -Value 00002000
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type DWord -Value 00000001
                    Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Services\Ndu" -Name "Start" -Type DWord -Value 00000004
                    Set-ItemProperty -Path "HKLM:\Control Panel\Mouse" -Name "MouseHoverTime" -Type DWord -Value 00000010
        
        
                    # Network Tweaks
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 20
        
                    # Group svchost.exe processes
                    $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force
        
                    Write-Host "Disable News and Interests"
                    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
                    # Remove "News and Interest" from taskbar
                    Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2
        
                    # remove "Meet Now" button from taskbar
        
                    If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
                        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
                    }
        
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type DWord -Value 1
        
                Write-Host "Removing AutoLogger file and restricting directory..."
                $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
                If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
                    Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
                }
                icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
        
                Write-Host "Stopping and disabling Diagnostics Tracking Service..."
                Stop-Service "DiagTrack"
                Set-Service "DiagTrack" -StartupType Disabled
            }
            if ($tweak -eq "EssTweaksWifi"){
                If (!(Test-Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
                    New-Item -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Force | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
            }
            if ($tweak -eq "MiscTweaksLapPower"){
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000000
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0000001
            }
            if ($tweak -eq "MiscTweaksLapNum"){
                If (!(Test-Path "HKU:")) {
                    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
                }
                Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
            }
            if ($tweak -eq "MiscTweaksPower"){
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000001
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0000000
            }
            if ($tweak -eq "MiscTweaksNum"){
                If (!(Test-Path "HKU:")) {
                    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
                }
                Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 2
            }
            if ($tweak -eq "MiscTweaksExt"){
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0
            }
            if ($tweak -eq "MiscTweaksUTC"){
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 1
            }
            if ($tweak -eq "MiscTweaksDisplay"){
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 0
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 200
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 0
                Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0
            }
            if ($tweak -eq "EssTweaksDeBloat"){
                $Bloatware = @(
                    #Unnecessary Windows 10 AppX Apps
                    "Microsoft.3DBuilder"
                    "Microsoft.Microsoft3DViewer"
                    "Microsoft.AppConnector"
                    "Microsoft.BingFinance"
                    "Microsoft.BingNews"
                    "Microsoft.BingSports"
                    "Microsoft.BingTranslator"
                    "Microsoft.BingWeather"
                    "Microsoft.BingFoodAndDrink"
                    "Microsoft.BingHealthAndFitness"
                    "Microsoft.BingTravel"
                    "Microsoft.MinecraftUWP"
                    "Microsoft.GamingServices"
                    # "Microsoft.WindowsReadingList"
                    "Microsoft.GetHelp"
                    "Microsoft.Getstarted"
                    "Microsoft.Messaging"
                    "Microsoft.Microsoft3DViewer"
                    "Microsoft.MicrosoftSolitaireCollection"
                    "Microsoft.NetworkSpeedTest"
                    "Microsoft.News"
                    "Microsoft.Office.Lens"
                    "Microsoft.Office.Sway"
                    "Microsoft.Office.OneNote"
                    "Microsoft.OneConnect"
                    "Microsoft.People"
                    "Microsoft.Print3D"
                    "Microsoft.SkypeApp"
                    "Microsoft.Wallet"
                    "Microsoft.Whiteboard"
                    "Microsoft.WindowsAlarms"
                    "microsoft.windowscommunicationsapps"
                    "Microsoft.WindowsFeedbackHub"
                    "Microsoft.WindowsMaps"
                    "Microsoft.WindowsPhone"
                    "Microsoft.WindowsSoundRecorder"
                    "Microsoft.XboxApp"
                    "Microsoft.ConnectivityStore"
                    "Microsoft.CommsPhone"
                    "Microsoft.ScreenSketch"
                    "Microsoft.Xbox.TCUI"
                    "Microsoft.XboxGameOverlay"
                    "Microsoft.XboxGameCallableUI"
                    "Microsoft.XboxSpeechToTextOverlay"
                    "Microsoft.MixedReality.Portal"
                    "Microsoft.XboxIdentityProvider"
                    "Microsoft.ZuneMusic"
                    "Microsoft.ZuneVideo"
                    #"Microsoft.YourPhone"
                    "Microsoft.Getstarted"
                    "Microsoft.MicrosoftOfficeHub"
            
                    #Sponsored Windows 10 AppX Apps
                    #Add sponsored/featured apps to remove in the "*AppName*" format
                    "*EclipseManager*"
                    "*ActiproSoftwareLLC*"
                    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
                    "*Duolingo-LearnLanguagesforFree*"
                    "*PandoraMediaInc*"
                    "*CandyCrush*"
                    "*BubbleWitch3Saga*"
                    "*Wunderlist*"
                    "*Flipboard*"
                    "*Twitter*"
                    "*Facebook*"
                    "*Royal Revolt*"
                    "*Sway*"
                    "*Speed Test*"
                    "*Dolby*"
                    "*Viber*"
                    "*ACGMediaPlayer*"
                    "*Netflix*"
                    "*OneCalendar*"
                    "*LinkedInforWindows*"
                    "*HiddenCityMysteryofShadows*"
                    "*Hulu*"
                    "*HiddenCity*"
                    "*AdobePhotoshopExpress*"
                    "*HotspotShieldFreeVPN*"
            
                    #Optional: Typically not removed but you can if you need to for some reason
                    "*Microsoft.Advertising.Xaml*"
                    #"*Microsoft.MSPaint*"
                    #"*Microsoft.MicrosoftStickyNotes*"
                    #"*Microsoft.Windows.Photos*"
                    #"*Microsoft.WindowsCalculator*"
                    #"*Microsoft.WindowsStore*"
                    )
                           
                foreach ($Bloat in $Bloatware) {
                    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
                    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
                    Write-Host "Trying to remove $Bloat."
                }
            }
        }
        #>
        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.tweaksbutton.Content = "Run Tweaks"},"Normal")
        [System.Windows.MessageBox]::Show("Tweaks haved completed!",'Tweaks are done!',"OK","Info")
    }

    $undotweaks = {
        [System.Windows.MessageBox]::Show("UNDOALL THE THINGS",'Tweaks will be undone!',"OK","Info")
        <#TODO Get this to run in an elevated prompt if not already.

        Write-Host "Creating Restore Point incase something bad happens"
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
    
        Write-Host "Enabling Telemetry..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1
        Write-Host "Enabling Wi-Fi Sense"
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 1
        Write-Host "Enabling Application suggestions..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 1
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0
        Write-Host "Enabling Activity History..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 1
        Write-Host "Enable Location Tracking..."
        If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 1
        Write-Host "Enabling automatic Maps updates..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 1
        Write-Host "Enabling Feedback..."
        If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 0
        Write-Host "Enabling Tailored Experiences..."
        If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 0
        Write-Host "Disabling Advertising ID..."
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 0
        Write-Host "Allow Error reporting..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 0
        Write-Host "Allowing Diagnostics Tracking Service..."
        Stop-Service "DiagTrack" -WarningAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Manual
        Write-Host "Allowing WAP Push Service..."
        Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
        Set-Service "dmwappushservice" -StartupType Manual
        Write-Host "Allowing Home Groups services..."
        Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
        Set-Service "HomeGroupListener" -StartupType Manual
        Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
        Set-Service "HomeGroupProvider" -StartupType Manual
        Write-Host "Enabling Storage Sense..."
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" | Out-Null
        Write-Host "Allowing Superfetch service..."
        Stop-Service "SysMain" -WarningAction SilentlyContinue
        Set-Service "SysMain" -StartupType Manual
        Write-Host "Setting BIOS time to Local Time instead of UTC..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 0
        Write-Host "Enabling Hibernation..."
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 1
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -ErrorAction SilentlyContinue
    
        Write-Host "Hiding file operations details..."
        If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 0
        Write-Host "Showing Task View button..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 1
    
        Write-Host "Changing default Explorer view to Quick Access..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1
    
        Write-Host "Unrestricting AutoLogger directory"
        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        icacls $autoLoggerDir /grant:r SYSTEM:`(OI`)`(CI`)F | Out-Null
    
        Write-Host "Enabling and starting Diagnostics Tracking Service"
        Set-Service "DiagTrack" -StartupType Automatic
        Start-Service "DiagTrack"
    
        Write-Host "Hiding known file extensions"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 1
    
        Write-Host "Reset Local Group Policies to Stock Defaults"
        # cmd /c secedit /configure /cfg %windir%\inf\defltbase.inf /db defltbase.sdb /verbose
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicy"
        cmd /c gpupdate /force
        # Considered using Invoke-GPUpdate but requires module most people won't have installed
    
        Write-Output "Adjusting visual effects for appearance..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 400
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158,30,7,128,18,0,0,0))
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 1
    
        Write-Host "Restoring Clipboard History..."
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -ErrorAction SilentlyContinue
        Write-Host "Done - Reverted to Stock Settings"
    
        Write-Host "Essential Undo Completed"
        #>
        [System.Windows.MessageBox]::Show("Done",'Undo All',"OK","Info")
    }
    #===========================================================================
    # Tab 3 - Config Buttons
    #===========================================================================

    $features = {
        param ($featuretoinstall)

        $global:sync.form.Dispatcher.Invoke([action]{$sync.featurescheck = $global:sync.FeatureInstall.Content},"Normal")
        If($sync.tweakscheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.FeatureInstall.Content = "Running"},"Normal")
        [System.Windows.MessageBox]::Show("$featuretoinstall",'I am going to install these features',"OK","Info")

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

       #>
       $ButtonType = [System.Windows.MessageBoxButton]::OK
       $MessageboxTitle = "All features are now installed "
       $Messageboxbody = ("Done")
       $MessageIcon = [System.Windows.MessageBoxImage]::Information
      
       [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)

       $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.FeatureInstall.Content = "Install Features"},"Normal")
    }

    #===========================================================================
    # Tab 4 - Updates Buttons
    #===========================================================================

    $Updatesdefault = {

        $global:sync.form.Dispatcher.Invoke([action]{$sync.Updatesdefaultcheck = $global:sync.Updatesdefault.Content},"Normal")
        If($sync.Updatesdefaultcheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatesdefault.Content = "Running"},"Normal")
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
        
        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatesdefault.Content = "Default (Out of Box) Settings"},"Normal")
    }

    $Updatesdisable = {

        $global:sync.form.Dispatcher.Invoke([action]{$sync.Updatesdisablecheck = $global:sync.Updatesdisable.Content},"Normal")
        If($sync.Updatesdisablecheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatesdisable.Content = "Running"},"Normal")
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
        
        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatesdisable.Content = "Disable ALL Updates (NOT RECOMMENDED!)"},"Normal")
    }

    $Updatessecurity = {

        $global:sync.form.Dispatcher.Invoke([action]{$sync.Updatessecuritycheck = $global:sync.Updatessecurity.Content},"Normal")
        If($sync.Updatessecuritycheck -like "Running"){
            [System.Windows.MessageBox]::Show("Task is currently running",'Features are in progress',"OK","Info")
            return
        }

        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatessecurity.Content = "Running"},"Normal")
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
        
        $global:sync.Form.Dispatcher.Invoke([action]{$global:sync.Updatessecurity.Content = "Security (Recommended) Settings"},"Normal")

    }

#endregion scripts

# Arguments
If($env:args){
    Write-Verbose "Arguments Detected, Running Args"
    If($env:args -match '\bInstallUpgrade\b'){Invoke-Command -scriptblock $InstallUpgrade}
    If($env:args -match '\bUndoTweaks\b'){Invoke-Command -scriptblock $undotweaks}
    If($env:args -match '\bPanelControl\b'){cmd /c control}
    If($env:args -match '\bPanelNetwork\b'){cmd /c ncpa.cpl}
    If($env:args -match '\bPanelPower\b'){cmd /c powercfg.cpl}
    If($env:args -match '\bPanelSound\b'){cmd /c mmsys.cpl}
    If($env:args -match '\bPanelSystem\b'){cmd /c sysdm.cpl}
    If($env:args -match '\bPanelUser\b'){cmd /c "control userpasswords2"}
    If($env:args -match '\bDefaultUpdates\b'){Invoke-Command -scriptblock $Updatesdefault}
    If($env:args -match '\bDisableUpdates\b'){Invoke-Command -scriptblock $Updatesdisable}
    If($env:args -match '\bEnableSecurity\b'){Invoke-Command -scriptblock $Updatessecurity}
    If($env:args -match '\bQuitAfter\b'){Break}
    If($env:args -match '\bInstall\b'){
        $ProgramstoInstall = (($env:args-split " " | Where-Object {$_ -like "install*"} ) -split ":")[1]
        Write-Verbose "Installing $ProgramstoInstall."
        Invoke-Command -scriptblock  $sync.ScriptsInstallPrograms -ArgumentList $ProgramstoInstall
    }
}

# Create Form
$global:sync["Form"].ShowDialog() | out-null
