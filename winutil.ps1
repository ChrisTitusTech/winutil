<#
.NOTES
   Author      : Chris Titus @christitustech
   GitHub      : https://github.com/ChrisTitusTech
    Version 0.0.1
#>

# $inputXML = Get-Content "MainWindow.xaml" #uncomment for development
$inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/MainWindow.xaml") #uncomment for Production

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader = (New-Object System.Xml.XmlNodeReader $xaml) 
try { $Form = [Windows.Markup.XamlReader]::Load( $reader ) }
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    If ($error[0].Exception.Message -like "*button*") {
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch {
    # If it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | % { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }
 
Function Get-FormVariables {
    If ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    

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
                           
 
    #====DEBUG GUI Elements====

    #write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    #get-variable WPF*
}
 
Get-FormVariables

#===========================================================================
# Global Variables
#===========================================================================
$AppTitle = "Chris Titus Tech's Windows Utility"


#===========================================================================
# Navigation Controls
#===========================================================================

$WPFTab1BT.Add_Click({
        $WPFTabNav.Items[0].IsSelected = $true
        $WPFTabNav.Items[1].IsSelected = $false
        $WPFTabNav.Items[2].IsSelected = $false
        $WPFTabNav.Items[3].IsSelected = $false
    })
$WPFTab2BT.Add_Click({
        $WPFTabNav.Items[0].IsSelected = $false
        $WPFTabNav.Items[1].IsSelected = $true
        $WPFTabNav.Items[2].IsSelected = $false
        $WPFTabNav.Items[3].IsSelected = $false
    })
$WPFTab3BT.Add_Click({
        $WPFTabNav.Items[0].IsSelected = $false
        $WPFTabNav.Items[1].IsSelected = $false
        $WPFTabNav.Items[2].IsSelected = $true
        $WPFTabNav.Items[3].IsSelected = $false
    })
$WPFTab4BT.Add_Click({
        $WPFTabNav.Items[0].IsSelected = $false
        $WPFTabNav.Items[1].IsSelected = $false
        $WPFTabNav.Items[2].IsSelected = $false
        $WPFTabNav.Items[3].IsSelected = $true
    })

#===========================================================================
# Tab 1 - Install
#===========================================================================
$WPFinstall.Add_Click({
        $wingetinstall = New-Object System.Collections.Generic.List[System.Object]
        If ( $WPFInstalladobe.IsChecked -eq $true ) { 
            $wingetinstall.Add("Adobe.Acrobat.Reader.64-bit")
            $WPFInstalladobe.IsChecked = $false
        }
        If ( $WPFInstalladvancedip.IsChecked -eq $true ) { 
            $wingetinstall.Add("Famatech.AdvancedIPScanner")
            $WPFInstalladvancedip.IsChecked = $false
        }
        If ( $WPFInstallatom.IsChecked -eq $true ) { 
            $wingetinstall.Add("GitHub.Atom")
            $WPFInstallatom.IsChecked = $false
        }
        If ( $WPFInstallaudacity.IsChecked -eq $true ) { 
            $wingetinstall.Add("Audacity.Audacity")
            $WPFInstallaudacity.IsChecked = $false
        }
        If ( $WPFInstallautohotkey.IsChecked -eq $true ) { 
            $wingetinstall.Add("Lexikos.AutoHotkey")
            $WPFInstallautohotkey.IsChecked = $false
        }  
        If ( $WPFInstallbrave.IsChecked -eq $true ) { 
            $wingetinstall.Add("BraveSoftware.BraveBrowser")
            $WPFInstallbrave.IsChecked = $false
        }
        If ( $WPFInstallchrome.IsChecked -eq $true ) { 
            $wingetinstall.Add("Google.Chrome")
            $WPFInstallchrome.IsChecked = $false
        }
        If ( $WPFInstalldiscord.IsChecked -eq $true ) { 
            $wingetinstall.Add("Discord.Discord")
            $WPFInstalldiscord.IsChecked = $false
        }
        If ( $WPFInstallesearch.IsChecked -eq $true ) { 
            $wingetinstall.Add("voidtools.Everything --source winget")
            $WPFInstallesearch.IsChecked = $false
        }
        If ( $WPFInstalletcher.IsChecked -eq $true ) { 
            $wingetinstall.Add("Balena.Etcher")
            $WPFInstalletcher.IsChecked = $false
        }
        If ( $WPFInstallfirefox.IsChecked -eq $true ) { 
            $wingetinstall.Add("Mozilla.Firefox")
            $WPFInstallfirefox.IsChecked = $false
        }
        If ( $WPFInstallgimp.IsChecked -eq $true ) { 
            $wingetinstall.Add("GIMP.GIMP")
            $WPFInstallgimp.IsChecked = $false
        }
        If ( $WPFInstallgithubdesktop.IsChecked -eq $true ) { 
            $wingetinstall.Add("Git.Git")
            $wingetinstall.Add("GitHub.GitHubDesktop")
            $WPFInstallgithubdesktop.IsChecked = $false
        }
        If ( $WPFInstallimageglass.IsChecked -eq $true ) { 
            $wingetinstall.Add("DuongDieuPhap.ImageGlass")
            $WPFInstallimageglass.IsChecked = $false
        }
        If ( $WPFInstalljava8.IsChecked -eq $true ) { 
            $wingetinstall.Add("AdoptOpenJDK.OpenJDK.8")
            $WPFInstalljava8.IsChecked = $false
        }
        If ( $WPFInstalljava16.IsChecked -eq $true ) { 
            $wingetinstall.Add("AdoptOpenJDK.OpenJDK.16")
            $WPFInstalljava16.IsChecked = $false
        }
        If ( $WPFInstalljava18.IsChecked -eq $true ) { 
            $wingetinstall.Add("Oracle.JDK.18")
            $WPFInstalljava18.IsChecked = $false
        }
        If ( $WPFInstalljetbrains.IsChecked -eq $true ) { 
            $wingetinstall.Add("JetBrains.Toolbox")
            $WPFInstalljetbrains.IsChecked = $false
        }
        If ( $WPFInstallmpc.IsChecked -eq $true ) { 
            $wingetinstall.Add("clsid2.mpc-hc")
            $WPFInstallmpc.IsChecked = $false
        }
        If ( $WPFInstallnodejs.IsChecked -eq $true ) { 
            $wingetinstall.Add("OpenJS.NodeJS")
            $WPFInstallnodejs.IsChecked = $false
        }
        If ( $WPFInstallnodejslts.IsChecked -eq $true ) { 
            $wingetinstall.Add("OpenJS.NodeJS.LTS")
            $WPFInstallnodejslts.IsChecked = $false
        }
        If ( $WPFInstallnotepadplus.IsChecked -eq $true ) { 
            $wingetinstall.Add("Notepad++.Notepad++")
            $WPFInstallnotepadplus.IsChecked = $false
        }
        If ( $WPFInstallpowertoys.IsChecked -eq $true ) { 
            $wingetinstall.Add("Microsoft.PowerToys")
            $WPFInstallpowertoys.IsChecked = $false
        }
        If ( $WPFInstallputty.IsChecked -eq $true ) { 
            $wingetinstall.Add("PuTTY.PuTTY")
            $WPFInstallputty.IsChecked = $false
        }
        If ( $WPFInstallpython3.IsChecked -eq $true ) { 
            $wingetinstall.Add("Python.Python.3")
            $WPFInstallpython3.IsChecked = $false
        }
        If ( $WPFInstallsevenzip.IsChecked -eq $true ) { 
            $wingetinstall.Add("7zip.7zip")
            $WPFInstallsevenzip.IsChecked = $false
        }
        If ( $WPFInstallsharex.IsChecked -eq $true ) { 
            $wingetinstall.Add("ShareX.ShareX")
            $WPFInstallsharex.IsChecked = $false
        }
        If ( $WPFInstallsublime.IsChecked -eq $true ) { 
            $wingetinstall.Add("SublimeHQ.SublimeText.4")
            $WPFInstallsublime.IsChecked = $false
        }
        If ( $WPFInstallsumatra.IsChecked -eq $true ) { 
            $wingetinstall.Add("SumatraPDF.SumatraPDF")
            $WPFInstallsumatra.IsChecked = $false
        }
        If ( $WPFInstallterminal.IsChecked -eq $true ) { 
            $wingetinstall.Add("Microsoft.WindowsTerminal")
            $WPFInstallterminal.IsChecked = $false
        }
        If ( $WPFInstallttaskbar.IsChecked -eq $true ) { 
            $wingetinstall.Add("9PF4KZ2VN4W9")
            $WPFInstallttaskbar.IsChecked = $false
        }
        If ( $WPFInstallvlc.IsChecked -eq $true ) { 
            $wingetinstall.Add("VideoLAN.VLC")
            $WPFInstallvlc.IsChecked = $false
        }
        If ( $WPFInstallvscode.IsChecked -eq $true ) { 
            $wingetinstall.Add("Git.Git")
            $wingetinstall.Add("Microsoft.VisualStudioCode --source winget")
            $WPFInstallvscode.IsChecked = $false
        }
        If ( $WPFInstallvscodium.IsChecked -eq $true ) { 
            $wingetinstall.Add("Git.Git")
            $wingetinstall.Add("VSCodium.VSCodium")
            $WPFInstallvscodium.IsChecked = $false
        }
        If ( $WPFInstallwinscp.IsChecked -eq $true ) { 
            $wingetinstall.Add("WinSCP.WinSCP")
            $WPFInstallputty.IsChecked = $false
        }
        If ( $WPFInstallanydesk.IsChecked -eq $true ) { 
            $wingetinstall.Add("AnyDeskSoftwareGmbH.AnyDesk")
            $WPFInstallanydesk.IsChecked = $false
        }
        If ( $WPFInstallbitwarden.IsChecked -eq $true ) { 
            $wingetinstall.Add("Bitwarden.Bitwarden")
            $WPFInstallbitwarden.IsChecked = $false
        }        
        If ( $WPFInstallblender.IsChecked -eq $true ) { 
            $wingetinstall.Add("BlenderFoundation.Blender")
            $WPFInstallblender.IsChecked = $false
        }                    
        If ( $WPFInstallchromium.IsChecked -eq $true ) { 
            $wingetinstall.Add("eloston.ungoogled-chromium")
            $WPFInstallchromium.IsChecked = $false
        }             
        If ( $WPFInstallcpuz.IsChecked -eq $true ) { 
            $wingetinstall.Add("CPUID.CPU-Z")
            $WPFInstallcpuz.IsChecked = $false
        }                            
        If ( $WPFInstalleartrumpet.IsChecked -eq $true ) { 
            $wingetinstall.Add("File-New-Project.EarTrumpet")
            $WPFInstalleartrumpet.IsChecked = $false
        }           
        If ( $WPFInstallepicgames.IsChecked -eq $true ) { 
            $wingetinstall.Add("EpicGames.EpicGamesLauncher")
            $WPFInstallepicgames.IsChecked = $false
        }                                      
        If ( $WPFInstallflameshot.IsChecked -eq $true ) { 
            $wingetinstall.Add("Flameshot.Flameshot")
            $WPFInstallflameshot.IsChecked = $false
        }            
        If ( $WPFInstallfoobar.IsChecked -eq $true ) { 
            $wingetinstall.Add("PeterPawlowski.foobar2000")
            $WPFInstallfoobar.IsChecked = $false
        }                     
        If ( $WPFInstallgog.IsChecked -eq $true ) { 
            $wingetinstall.Add("GOG.Galaxy")
            $WPFInstallgog.IsChecked = $false
        }                  
        If ( $WPFInstallgpuz.IsChecked -eq $true ) { 
            $wingetinstall.Add("TechPowerUp.GPU-Z")
            $WPFInstallgpuz.IsChecked = $false
        }                 
        If ( $WPFInstallgreenshot.IsChecked -eq $true ) { 
            $wingetinstall.Add("Greenshot.Greenshot")
            $WPFInstallgreenshot.IsChecked = $false
        }            
        If ( $WPFInstallhandbrake.IsChecked -eq $true ) { 
            $wingetinstall.Add("HandBrake.HandBrake")
            $WPFInstallhandbrake.IsChecked = $false
        }      
        If ( $WPFInstallhexchat.IsChecked -eq $true ) { 
            $wingetinstall.Add("HexChat.HexChat")
            $WPFInstallhexchat.IsChecked = $false
        }       
        If ( $WPFInstallhwinfo.IsChecked -eq $true ) { 
            $wingetinstall.Add("REALiX.HWiNFO")
            $WPFInstallhwinfo.IsChecked = $false
        }                       
        If ( $WPFInstallinkscape.IsChecked -eq $true ) { 
            $wingetinstall.Add("Inkscape.Inkscape")
            $WPFInstallinkscape.IsChecked = $false
        }             
        If ( $WPFInstallkeepass.IsChecked -eq $true ) { 
            $wingetinstall.Add("KeePassXCTeam.KeePassXC")
            $WPFInstallkeepass.IsChecked = $false
        }              
        If ( $WPFInstalllibrewolf.IsChecked -eq $true ) { 
            $wingetinstall.Add("LibreWolf.LibreWolf")
            $WPFInstalllibrewolf.IsChecked = $false
        }            
        If ( $WPFInstallmalwarebytes.IsChecked -eq $true ) { 
            $wingetinstall.Add("Malwarebytes.Malwarebytes")
            $WPFInstallmalwarebytes.IsChecked = $false
        }          
        If ( $WPFInstallmatrix.IsChecked -eq $true ) { 
            $wingetinstall.Add("Element.Element")
            $WPFInstallmatrix.IsChecked = $false
        } 
        If ( $WPFInstallmremoteng.IsChecked -eq $true ) { 
            $wingetinstall.Add("mRemoteNG.mRemoteNG")
            $WPFInstallmremoteng.IsChecked = $false
        }                    
        If ( $WPFInstallnvclean.IsChecked -eq $true ) { 
            $wingetinstall.Add("TechPowerUp.NVCleanstall")
            $WPFInstallnvclean.IsChecked = $false
        }              
        If ( $WPFInstallobs.IsChecked -eq $true ) { 
            $wingetinstall.Add("OBSProject.OBSStudio")
            $WPFInstallobs.IsChecked = $false
        }                  
        If ( $WPFInstallobsidian.IsChecked -eq $true ) { 
            $wingetinstall.Add("Obsidian.Obsidian")
            $WPFInstallobsidian.IsChecked = $false
        }                           
        If ( $WPFInstallrevo.IsChecked -eq $true ) { 
            $wingetinstall.Add("RevoUninstaller.RevoUninstaller")
            $WPFInstallrevo.IsChecked = $false
        }                 
        If ( $WPFInstallrufus.IsChecked -eq $true ) { 
            $wingetinstall.Add("Rufus.Rufus")
            $WPFInstallrufus.IsChecked = $false
        }   
        If ( $WPFInstallsignal.IsChecked -eq $true ) { 
            $wingetinstall.Add("OpenWhisperSystems.Signal")
            $WPFInstallsignal.IsChecked = $false
        }
        If ( $WPFInstallskype.IsChecked -eq $true ) { 
            $wingetinstall.Add("Microsoft.Skype")
            $WPFInstallskype.IsChecked = $false
        }                               
        If ( $WPFInstallslack.IsChecked -eq $true ) { 
            $wingetinstall.Add("SlackTechnologies.Slack")
            $WPFInstallslack.IsChecked = $false
        }                
        If ( $WPFInstallspotify.IsChecked -eq $true ) { 
            $wingetinstall.Add("Spotify.Spotify")
            $WPFInstallspotify.IsChecked = $false
        }              
        If ( $WPFInstallsteam.IsChecked -eq $true ) { 
            $wingetinstall.Add("Valve.Steam")
            $WPFInstallsteam.IsChecked = $false
        }                             
        If ( $WPFInstallteamviewer.IsChecked -eq $true ) { 
            $wingetinstall.Add("TeamViewer.TeamViewer")
            $WPFInstallteamviewer.IsChecked = $false
        }
        If ( $WPFInstallteams.IsChecked -eq $true ) { 
            $wingetinstall.Add("Microsoft.Teams")
            $WPFInstallteams.IsChecked = $false
        }                        
        If ( $WPFInstalltreesize.IsChecked -eq $true ) { 
            $wingetinstall.Add("JAMSoftware.TreeSize.Free")
            $WPFInstalltreesize.IsChecked = $false
        }                         
        If ( $WPFInstallvisualstudio.IsChecked -eq $true ) { 
            $wingetinstall.Add("Microsoft.VisualStudio.2022.Community")
            $WPFInstallvisualstudio.IsChecked = $false
        }         
        If ( $WPFInstallvivaldi.IsChecked -eq $true ) { 
            $wingetinstall.Add("VivaldiTechnologies.Vivaldi")
            $WPFInstallvivaldi.IsChecked = $false
        }                              
        If ( $WPFInstallvoicemeeter.IsChecked -eq $true ) { 
            $wingetinstall.Add("VB-Audio.Voicemeeter")
            $WPFInstallvoicemeeter.IsChecked = $false
        }                    
        If ( $WPFInstallwindirstat.IsChecked -eq $true ) { 
            $wingetinstall.Add("WinDirStat.WinDirStat")
            $WPFInstallwindirstat.IsChecked = $false
        }           
        If ( $WPFInstallwireshark.IsChecked -eq $true ) { 
            $wingetinstall.Add("WiresharkFoundation.Wireshark")
            $WPFInstallwireshark.IsChecked = $false
        }            
        If ( $WPFInstallzoom.IsChecked -eq $true ) { 
            $wingetinstall.Add("Zoom.Zoom")
            $WPFInstallzoom.IsChecked = $false
        }    

        # Check if winget is installed
        Write-Host "Checking if Winget is Installed..."
        if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
        }
        else {
            if (((((Get-ComputerInfo).OSName.IndexOf("LTSC")) -ne -1) -or ((Get-ComputerInfo).OSName.IndexOf("Server") -ne -1)) -and (((Get-ComputerInfo).WindowsVersion) -ge "1809")) {
                #Checks if Windows edition is LTSC/Server 2019+
                #Manually Installing Winget
                Write-Host "Running Alternative Installer for LTSC/Server Editions"

                #Download Needed Files
                Write-Host "Downloading Needed Files..."
                Start-BitsTransfer -Source "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -Destination "./Microsoft.VCLibs.x64.14.00.Desktop.appx"
                Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Destination "./Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                Start-BitsTransfer -Source "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/b0a0692da1034339b76dce1c298a1e42_License1.xml" -Destination "./b0a0692da1034339b76dce1c298a1e42_License1.xml"

                #Installing Packages
                Write-Host "Installing Packages..."
                Add-AppxProvisionedPackage -Online -PackagePath ".\Microsoft.VCLibs.x64.14.00.Desktop.appx" -SkipLicense
                Add-AppxProvisionedPackage -Online -PackagePath ".\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -LicensePath ".\b0a0692da1034339b76dce1c298a1e42_License1.xml"
                Write-Host "winget Installed (Reboot might be required before winget will work)"

                #Sleep for 5 seconds to maximize chance that winget will work without reboot
                Write-Host "Pausing for 5 seconds to maximize chance that winget will work without reboot"
                Start-Sleep -s 5

                #Removing no longer needed Files
                Write-Host "Removing no longer needed Files..."
                Remove-Item -Path ".\Microsoft.VCLibs.x64.14.00.Desktop.appx" -Force
                Remove-Item -Path ".\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force
                Remove-Item -Path ".\b0a0692da1034339b76dce1c298a1e42_License1.xml" -Force
                Write-Host "Removed Files that are no longer needed"
            }
            elseif (((Get-ComputerInfo).WindowsVersion) -lt "1809") {
                #Checks if Windows Version is too old for winget
                Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            }
            else {
                #Installing Winget from the Microsoft Store
                Write-Host "Winget not found, installing it now."
                Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
                $nid = (Get-Process AppInstaller).Id
                Wait-Process -Id $nid
                Write-Host "Winget Installed"
            }
        }

        if ($wingetinstall.Count -eq 0) {
            $WarningMsg = "Please select the program(s) to install"
            [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        # Install all winget programs in new window
        $wingetinstall.ToArray()
        # Define Output variable
        $wingetResult = New-Object System.Collections.Generic.List[System.Object]
        foreach ( $node in $wingetinstall ) {
            try {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget install -e --accept-source-agreements --accept-package-agreements --silent $node | Out-Host" -Wait -WindowStyle Maximized
                $wingetResult.Add("$node`n")
            }
            catch [System.InvalidOperationException] {
                Write-Warning "Allow Yes on User Access Control to Install"
            }
            catch {
                Write-Error $_.Exception
            }
        }
        $wingetResult.ToArray()
        $wingetResult | % { $_ } | Out-Host

        # Popup after finished
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        if ($wingetResult -ne "") {
            $Messageboxbody = "Installed Programs `n$($wingetResult)"
        }
        else {
            $Messageboxbody = "No Program(s) are installed"
        }
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $AppTitle, $ButtonType, $MessageIcon)

        Write-Host "================================="
        Write-Host "---  Installs are Finished    ---"
        Write-Host "================================="

    })

$WPFInstallUpgrade.Add_Click({
        $isUpgradeSuccess = $false
        try {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget upgrade --all  | Out-Host" -Wait -WindowStyle Maximized
            $isUpgradeSuccess = $true
        }
        catch [System.InvalidOperationException] {
            Write-Warning "Allow Yes on User Access Control to Upgrade"
        }
        catch {
            Write-Error $_.Exception
        }
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $Messageboxbody = if($isUpgradeSuccess) {"Upgrade Done"} else {"Upgrade was not succesful"}
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $AppTitle, $ButtonType, $MessageIcon)
    })

#===========================================================================
# Tab 2 - Tweak Buttons
#===========================================================================
$WPFdesktop.Add_Click({

        $WPFEssTweaksAH.IsChecked = $true
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksDVR.IsChecked = $true
        $WPFEssTweaksHiber.IsChecked = $true
        $WPFEssTweaksHome.IsChecked = $true
        $WPFEssTweaksLoc.IsChecked = $true
        $WPFEssTweaksOO.IsChecked = $true
        $WPFEssTweaksRP.IsChecked = $true
        $WPFEssTweaksServices.IsChecked = $true
        $WPFEssTweaksStorage.IsChecked = $true
        $WPFEssTweaksTele.IsChecked = $true
        $WPFEssTweaksWifi.IsChecked = $true
        $WPFMiscTweaksPower.IsChecked = $true
        $WPFMiscTweaksNum.IsChecked = $true
        $WPFMiscTweaksLapPower.IsChecked = $false
        $WPFMiscTweaksLapNum.IsChecked = $false
    })

$WPFlaptop.Add_Click({

        $WPFEssTweaksAH.IsChecked = $true
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksDVR.IsChecked = $true
        $WPFEssTweaksHiber.IsChecked = $false
        $WPFEssTweaksHome.IsChecked = $true
        $WPFEssTweaksLoc.IsChecked = $true
        $WPFEssTweaksOO.IsChecked = $true
        $WPFEssTweaksRP.IsChecked = $true
        $WPFEssTweaksServices.IsChecked = $true
        $WPFEssTweaksStorage.IsChecked = $true
        $WPFEssTweaksTele.IsChecked = $true
        $WPFEssTweaksWifi.IsChecked = $true
        $WPFMiscTweaksLapPower.IsChecked = $true
        $WPFMiscTweaksLapNum.IsChecked = $true
        $WPFMiscTweaksPower.IsChecked = $false
        $WPFMiscTweaksNum.IsChecked = $false
    })

$WPFminimal.Add_Click({
    
        $WPFEssTweaksAH.IsChecked = $false
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksDVR.IsChecked = $false
        $WPFEssTweaksHiber.IsChecked = $false
        $WPFEssTweaksHome.IsChecked = $true
        $WPFEssTweaksLoc.IsChecked = $false
        $WPFEssTweaksOO.IsChecked = $true
        $WPFEssTweaksRP.IsChecked = $true
        $WPFEssTweaksServices.IsChecked = $true
        $WPFEssTweaksStorage.IsChecked = $false
        $WPFEssTweaksTele.IsChecked = $true
        $WPFEssTweaksWifi.IsChecked = $false
        $WPFMiscTweaksPower.IsChecked = $false
        $WPFMiscTweaksNum.IsChecked = $false
        $WPFMiscTweaksLapPower.IsChecked = $false
        $WPFMiscTweaksLapNum.IsChecked = $false
    })

$WPFtweaksbutton.Add_Click({

        If ( $WPFEssTweaksAH.IsChecked -eq $true ) {
            Write-Host "Disabling Activity History..."
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0
            $WPFEssTweaksAH.IsChecked = $false
        }

        If ( $WPFEssTweaksDVR.IsChecked -eq $true ) {
            If (!(Test-Path "HKCU:\System\GameConfigStore")) {
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type Hex -Value 00000000
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type Hex -Value 00000000
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type Hex -Value 00000000
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 00000000
            }
            $WPFEssTweaksDVR.IsChecked = $false
        }
        If ( $WPFEssTweaksHiber.IsChecked -eq $true  ) {
            Write-Host "Disabling Hibernation..."
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 0
            If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0
            $WPFEssTweaksHiber.IsChecked = $false

        }
        If ( $WPFEssTweaksHome.IsChecked -eq $true ) {
            $WPFEssTweaksHome.IsChecked = $false
        }
        If ( $WPFEssTweaksLoc.IsChecked -eq $true ) {
            Write-Host "Disabling Location Tracking..."
            If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Deny"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0
            Write-Host "Disabling automatic Maps updates..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 0
            $WPFEssTweaksLoc.IsChecked = $false
        }
        If ( $WPFEssTweaksOO.IsChecked -eq $true ) {
            Write-Host "Running O&O Shutup with Recommended Settings"
            curl.exe -ss "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -o ooshutup10.cfg
            curl.exe -ss "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -o OOSU10.exe
            ./OOSU10.exe ooshutup10.cfg /quiet
            $WPFEssTweaksOO.IsChecked = $false
        }
        If ( $WPFEssTweaksRP.IsChecked -eq $true ) {
            Write-Host "Creating Restore Point in case something bad happens"
            Enable-ComputerRestore -Drive "$env:SystemDrive"
            Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
            $WPFEssTweaksRP.IsChecked = $false
        }
        If ( $WPFEssTweaksServices.IsChecked -eq $true ) {
            # Set Services to Manual 

            $services = @(
                "ALG"                                          # Application Layer Gateway Service(Provides support for 3rd party protocol plug-ins for Internet Connection Sharing)
                "AJRouter"                                     # Needed for AllJoyn Router Service
                "BcastDVRUserService_48486de"                  # GameDVR and Broadcast is used for Game Recordings and Live Broadcasts
                #"BDESVC"                                      # Bitlocker Drive Encryption Service
                #"BFE"                                         # Base Filtering Engine (Manages Firewall and Internet Protocol security)
                #"BluetoothUserService_48486de"                # Bluetooth user service supports proper functionality of Bluetooth features relevant to each user session.
                #"BrokerInfrastructure"                        # Windows Infrastructure Service (Controls which background tasks can run on the system)
                "Browser"                                      # Let users browse and locate shared resources in neighboring computers
                "BthAvctpSvc"                                  # AVCTP service (needed for Bluetooth Audio Devices or Wireless Headphones)
                "CaptureService_48486de"                       # Optional screen capture functionality for applications that call the Windows.Graphics.Capture API.
                "cbdhsvc_48486de"                              # Clipboard Service
                "diagnosticshub.standardcollector.service"     # Microsoft (R) Diagnostics Hub Standard Collector Service
                "DiagTrack"                                    # Diagnostics Tracking Service
                "dmwappushservice"                             # WAP Push Message Routing Service
                "DPS"                                          # Diagnostic Policy Service (Detects and Troubleshoots Potential Problems)
                "edgeupdate"                                   # Edge Update Service
                "edgeupdatem"                                  # Another Update Service
                #"EntAppSvc"                                    # Enterprise Application Management.
                "Fax"                                          # Fax Service
                "fhsvc"                                        # Fax History
                "FontCache"                                    # Windows font cache
                #"FrameServer"                                 # Windows Camera Frame Server (Allows multiple clients to access video frames from camera devices)
                "gupdate"                                      # Google Update
                "gupdatem"                                     # Another Google Update Service
                "iphlpsvc"                                     # ipv6(Most websites use ipv4 instead)
                "lfsvc"                                        # Geolocation Service
                #"LicenseManager"                              # Disable LicenseManager (Windows Store may not work properly)
                "lmhosts"                                      # TCP/IP NetBIOS Helper
                "MapsBroker"                                   # Downloaded Maps Manager
                "MicrosoftEdgeElevationService"                # Another Edge Update Service
                "MSDTC"                                        # Distributed Transaction Coordinator
                #"ndu"                                          # Windows Network Data Usage Monitor (Disabling Breaks Task Manager Per-Process Network Monitoring)
                "NetTcpPortSharing"                            # Net.Tcp Port Sharing Service
                "PcaSvc"                                       # Program Compatibility Assistant Service
                "PerfHost"                                     # Remote users and 64-bit processes to query performance.
                "PhoneSvc"                                     # Phone Service(Manages the telephony state on the device)
                #"PNRPsvc"                                     # Peer Name Resolution Protocol (Some peer-to-peer and collaborative applications, such as Remote Assistance, may not function, Discord will still work)
                #"p2psvc"                                      # Peer Name Resolution Protocol(Enables multi-party communication using Peer-to-Peer Grouping.  If disabled, some applications, such as HomeGroup, may not function. Discord will still work)iscord will still work)
                #"p2pimsvc"                                    # Peer Networking Identity Manager (Peer-to-Peer Grouping services may not function, and some applications, such as HomeGroup and Remote Assistance, may not function correctly. Discord will still work)
                "PrintNotify"                                  # Windows printer notifications and extentions
                "QWAVE"                                        # Quality Windows Audio Video Experience (audio and video might sound worse)
                "RemoteAccess"                                 # Routing and Remote Access
                "RemoteRegistry"                               # Remote Registry
                "RetailDemo"                                   # Demo Mode for Store Display
                "RtkBtManServ"                                 # Realtek Bluetooth Device Manager Service
                "SCardSvr"                                     # Windows Smart Card Service
                "seclogon"                                     # Secondary Logon (Disables other credentials only password will work)
                "SEMgrSvc"                                     # Payments and NFC/SE Manager (Manages payments and Near Field Communication (NFC) based secure elements)
                "SharedAccess"                                 # Internet Connection Sharing (ICS)
                #"Spooler"                                     # Printing
                "stisvc"                                       # Windows Image Acquisition (WIA)
                #"StorSvc"                                     # StorSvc (usb external hard drive will not be reconized by windows)
                "SysMain"                                      # Analyses System Usage and Improves Performance
                "TrkWks"                                       # Distributed Link Tracking Client
                #"WbioSrvc"                                    # Windows Biometric Service (required for Fingerprint reader / facial detection)
                "WerSvc"                                       # Windows error reporting
                "wisvc"                                        # Windows Insider program(Windows Insider will not work if Disabled)
                #"WlanSvc"                                     # WLAN AutoConfig
                "WMPNetworkSvc"                                # Windows Media Player Network Sharing Service
                "WpcMonSvc"                                    # Parental Controls
                "WPDBusEnum"                                   # Portable Device Enumerator Service
                "WpnService"                                   # WpnService (Push Notifications may not work)
                #"wscsvc"                                      # Windows Security Center Service
                "WSearch"                                      # Windows Search
                "XblAuthManager"                               # Xbox Live Auth Manager (Disabling Breaks Xbox Live Games)
                "XblGameSave"                                  # Xbox Live Game Save Service (Disabling Breaks Xbox Live Games)
                "XboxNetApiSvc"                                # Xbox Live Networking Service (Disabling Breaks Xbox Live Games)
                "XboxGipSvc"                                   # Xbox Accessory Management Service
                # Hp services
                "HPAppHelperCap"
                "HPDiagsCap"
                "HPNetworkCap"
                "HPSysInfoCap"
                "HpTouchpointAnalyticsService"
                # Hyper-V services
                "HvHost"
                "vmicguestinterface"
                "vmicheartbeat"
                "vmickvpexchange"
                "vmicrdv"
                "vmicshutdown"
                "vmictimesync"
                "vmicvmsession"
                # Services that cannot be disabled
                #"WdNisSvc"
            )
        
            foreach ($service in $services) {
                # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist
        
                Write-Host "Setting $service StartupType to Manual"
                Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Manual
            }
            $WPFEssTweaksServices.IsChecked = $false
        }
        If ( $WPFEssTweaksStorage.IsChecked -eq $true ) {
            Write-Host "Disabling Storage Sense..."
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Recurse -ErrorAction SilentlyContinue
            $WPFEssTweaksStorage.IsChecked = $false
        }
        If ( $WPFEssTweaksTele.IsChecked -eq $true ) {
            Write-Host "Disabling Telemetry..."
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
            }
            else { Write-Host "Task Manager patch not run in builds 22557+ due to bug" }

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
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type DWord -Value 10
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type DWord -Value 10
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type DWord -Value 2000
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type DWord -Value 5000
            Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue
            # Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type DWord -Value 4000 # Note: This caused flickering
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type DWord -Value 1000
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillServiceTimeout" -Type DWord -Value 2000
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Type DWord -Value 10


            # Network Tweaks
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 20

            # Group svchost.exe processes
            $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force

            Write-Host "Disable News and Interests"
            If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
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
            $WPFEssTweaksTele.IsChecked = $false
        }
        If ( $WPFEssTweaksWifi.IsChecked -eq $true ) {
            Write-Host "Disabling Wi-Fi Sense..."
            If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
            If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
            $WPFEssTweaksWifi.IsChecked = $false
        }
        If ( $WPFMiscTweaksLapPower.IsChecked -eq $true ) {
            If (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling") {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000000
            }
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0000001
            $WPFMiscTweaksLapPower.IsChecked = $false
        }
        If ( $WPFMiscTweaksLapNum.IsChecked -eq $true ) {
            Write-Host "Disabling NumLock after startup..."
            If (!(Test-Path "HKU:")) {
                New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
            }
            Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
            $WPFMiscTweaksLapNum.IsChecked = $false
        }
        If ( $WPFMiscTweaksPower.IsChecked -eq $true ) {
            If (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling") {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000001
            }
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0000000
            $WPFMiscTweaksPower.IsChecked = $false 
        }
        If ( $WPFMiscTweaksNum.IsChecked -eq $true ) {
            Write-Host "Enabling NumLock after startup..."
            If (!(Test-Path "HKU:")) {
                New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
            }
            Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 2
            $WPFMiscTweaksNum.IsChecked = $false
        }
        If ( $WPFMiscTweaksExt.IsChecked -eq $true ) {
            Write-Host "Showing known file extensions..."
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0
            $WPFMiscTweaksExt.IsChecked = $false
        }
        If ( $WPFMiscTweaksUTC.IsChecked -eq $true ) {
            Write-Host "Setting BIOS time to UTC..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 1
            $WPFMiscTweaksUTC.IsChecked
        }

        If ( $WPFMiscTweaksDisplay.IsChecked -eq $true ) {
            Write-Host "Adjusting visual effects for performance..."
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 200
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144, 18, 3, 128, 16, 0, 0, 0))
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0
            Write-Host "Adjusted visual effects for performance"
            $WPFMiscTweaksDisplay.IsChecked = false
        }

        If ( $WPFEssTweaksDeBloat.IsChecked -eq $true ) {
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

                #Optional: Typically not removed but you can if you need to
                "*Microsoft.Advertising.Xaml*"
                #"*Microsoft.MSPaint*"
                #"*Microsoft.MicrosoftStickyNotes*"
                #"*Microsoft.Windows.Photos*"
                #"*Microsoft.WindowsCalculator*"
                #"*Microsoft.WindowsStore*"
            )

            Write-Host "Removing Bloatware"

            foreach ($Bloat in $Bloatware) {
                Get-AppxPackage -Name $Bloat | Remove-AppxPackage
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
                Write-Host "Trying to remove $Bloat."
            }

            Write-Host "Finished Removing Bloatware Apps"
            $WPFEssTweaksDeBloat.IsChecked = $false
        }
        Write-Host "Doing Security checks for Administrator Account and Group Policy"
        if(($(Get-WMIObject -class Win32_ComputerSystem | select username).username).IndexOf('Administrator') -eq -1){
            net user administrator /active:no
        }
    
        if(!(((Get-ComputerInfo).WindowsEditionId).IndexOf('Core') -eq -1) -or !(((Get-ComputerInfo).WindowsEditionId).IndexOf('Home') -eq -1)){ # Not sure if home edition is Core or Home
            Write-Host "Enabling gpedit.msc...Group Policy for Home Users"
            Get-ChildItem @(
                "$env:SystemDrive\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package*.mum",
                "$env:SystemDrive\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package*.mum"
            ) | ForEach-Object { dism.exe /online /norestart /add-package:"$_" }
        }
        Write-Host "================================="
        Write-Host "--     Tweaks are Finished    ---"
        Write-Host "================================="
        
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Tweaks are Finished "
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
    })
#===========================================================================
# Undo All
#===========================================================================
$WPFundoall.Add_Click({
        Write-Host "Creating Restore Point in case something bad happens"
        Enable-ComputerRestore -Drive "$env:SystemDrive"
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
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0
        Write-Host "Enabling Activity History..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 1
        Write-Host "Enable Location Tracking..."
        If (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location") {
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 1
        Write-Host "Enabling automatic Maps updates..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 1
        Write-Host "Enabling Feedback..."
        If (Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules") {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 0
        Write-Host "Enabling Tailored Experiences..."
        If (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
            Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 0
        Write-Host "Disabling Advertising ID..."
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo") {
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
        If (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager") {
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
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158, 30, 7, 128, 18, 0, 0, 0))
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 1
        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        Write-Host "Restoring Clipboard History..."
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -ErrorAction SilentlyContinue
        Write-Host "Done - Reverted to Stock Settings"

        Write-Host "Essential Undo Completed"

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Undo All"
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

        Write-Host "================================="
        Write-Host "---   Undo All is Finished    ---"
        Write-Host "================================="
    })
#===========================================================================
# Tab 3 - Config Buttons
#===========================================================================
$WPFFeatureInstall.Add_Click({

        If ( $WPFFeaturesdotnet.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx4-AdvSrvs" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart
        }
        If ( $WPFFeatureshyperv.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Tools-All" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-PowerShell" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Hypervisor" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Services" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-Clients" -All -NoRestart
            cmd /c bcdedit /set hypervisorschedulertype classic
            Write-Host "HyperV is now installed and configured. Please Reboot before using."
        } 
        If ( $WPFFeatureslegacymedia.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "MediaPlayback" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "LegacyComponents" -All -NoRestart
        }
        If ( $WPFFeaturewsl.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -All -NoRestart
            Write-Host "WSL is now installed and configured. Please Reboot before using."
        }
        If ( $WPFFeaturenfs.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "NFS-Administration" -All -NoRestart
            nfsadmin client stop
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousUID" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousGID" -Type DWord -Value 0
            nfsadmin client start
            nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i
            Write-Host "NFS is now setup for user based NFS mounts"
        }
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "All features are now installed "
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

        Write-Host "================================="
        Write-Host "---  Features are Installed   ---"
        Write-Host "================================="
    })

$WPFPanelDISM.Add_Click({
        Start-Process PowerShell -ArgumentList "Write-Host '(1/4) Chkdsk' -ForegroundColor Green; Chkdsk /scan; 
        Write-Host '`n(2/4) SFC - 1st scan' -ForegroundColor Green; sfc /scannow;
        Write-Host '`n(3/4) DISM' -ForegroundColor Green; DISM /Online /Cleanup-Image /Restorehealth; 
        Write-Host '`n(4/4) SFC - 2nd scan' -ForegroundColor Green; sfc /scannow; 
        Read-Host '`nPress Enter to Continue'" -verb runas
    })

$WPFPanelcontrol.Add_Click({
        cmd /c control
    })
$WPFPanelnetwork.Add_Click({
        cmd /c ncpa.cpl
    })
$WPFPanelpower.Add_Click({
        cmd /c powercfg.cpl
    })
$WPFPanelsound.Add_Click({
        cmd /c mmsys.cpl
    })
$WPFPanelsystem.Add_Click({
        cmd /c sysdm.cpl
    })
$WPFPaneluser.Add_Click({
        cmd /c "control userpasswords2"
    })
#===========================================================================
# Tab 4 - Updates Buttons
#===========================================================================

$WPFUpdatesdefault.Add_Click({
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 3
        If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1
        
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
        Write-Host "================================="
        Write-Host "---  Updates Set to Default   ---"
        Write-Host "================================="
    })

$WPFFixesUpdate.Add_Click({
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
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 
    
        Write-Host "8) Resetting the WinSock..." 
        netsh winsock reset 
        netsh winhttp reset proxy 
        netsh int ip reset
    
        Write-Host "9) Delete all BITS jobs..." 
        Get-BitsTransfer | Remove-BitsTransfer 
    
        Write-Host "10) Attempting to install the Windows Update Agent..." 
        If (!((wmic OS get OSArchitecture | Out-String).IndexOf("64") -eq -1)) { 
            wusa Windows8-RT-KB2937636-x64 /quiet 
        }
        else { 
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

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Reset Windows Update "
        $Messageboxbody = ("Stock settings loaded.`n Please reboot your computer")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
        Write-Host "================================="
        Write-Host "-- Reset ALL Updates to Factory -"
        Write-Host "================================="
    })

$WPFUpdatesdisable.Add_Click({
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0
    
    $services = @(
        "BITS"
        "wuauserv"
    )

    foreach ($service in $services) {
        # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist

        Write-Host "Setting $service StartupType to Disabled"
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
    }
    Write-Host "================================="
    Write-Host "---  Updates ARE DISABLED     ---"
    Write-Host "================================="
})
$WPFUpdatessecurity.Add_Click({
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
    
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Set Security Updates"
        $Messageboxbody = ("Recommended Update settings loaded")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
        Write-Host "================================="
        Write-Host "-- Updates Set to Recommended ---"
        Write-Host "================================="
    })

#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null
