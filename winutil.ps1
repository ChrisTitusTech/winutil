<#
.NOTES
   Author      : Chris Titus @christitustech
   GitHub      : https://github.com/ChrisTitusTech
    Version 0.0.1
#>

$inputXML = @"
<Window x:Class="WinUtility.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WinUtility"
        mc:Ignorable="d"
        Background="#777777"
        Title="Chris Titus Tech's Windows Utility" Height="533" Width="786">
	<Viewbox>
		<Grid Background="#777777" ShowGridLines="False" Name="MainGrid">
			<Grid.ColumnDefinitions>
				<ColumnDefinition Width="3*"/>
				<ColumnDefinition Width="7*"/>
			</Grid.ColumnDefinitions>
			<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0">
				<Image Height="200" Width="200" Name="Icon" SnapsToDevicePixels="True" Source="https://christitus.com/images/logo-full.png" Margin="0,10,0,10"/>
				<Button Content="Install" VerticalAlignment="Top" Height="40" Background="#222222" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab1BT"/>
				<Button Content="Tweaks" VerticalAlignment="Top" Height="40" Background="#333333" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab2BT"/>
				<Button Content="Config" VerticalAlignment="Top" Height="40" Background="#444444" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab3BT"/>
				<Button Content="Updates" VerticalAlignment="Top" Height="40" Background="#555555" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab4BT"/>
			</StackPanel>
			<TabControl Grid.Column="1" Padding="-1" Name="TabNav" SelectedIndex="0">
				<TabItem Header="Install" Visibility="Collapsed" Name="Tab1">
					<Grid Background="#222222">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="1*"/>
							<ColumnDefinition Width="1*"/>
							<ColumnDefinition Width="1*"/>
						</Grid.ColumnDefinitions>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10">
							<Label Content="Browsers" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installbrave" Content="Brave" Margin="5,0"/>
							<CheckBox Name="Installchrome" Content="Google Chrome" Margin="5,0"/>
							<CheckBox Name="Installchromium" Content="Un-Googled Chromium" Margin="5,0"/>
							<CheckBox Name="Installfirefox" Content="Firefox" Margin="5,0"/>
							<CheckBox Name="Installlibrewolf" Content="LibreWolf" Margin="5,0"/>
							<CheckBox Name="Installvivaldi" Content="Vivaldi" Margin="5,0"/>
							<Label Content="Document Tools" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installadobe" Content="Adobe Reader DC" Margin="5,0"/>
							<CheckBox Name="Installnotepadplus" Content="Notepad++" Margin="5,0"/>
							<CheckBox Name="Installobsidian" Content="Obsidian" Margin="5,0"/>
							<CheckBox Name="Installsumatra" Content="Sumatra PDF" Margin="5,0"/>
							<CheckBox Name="Installvscode" Content="VS Code" Margin="5,0"/>
							<CheckBox Name="Installvscodium" Content="VS Codium" Margin="5,0"/>
							<Label Content="Games" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installepicgames" Content="Epic Games Launcher" Margin="5,0"/>
							<CheckBox Name="Installgog" Content="GOG Galaxy" Margin="5,0"/>
							<CheckBox Name="Installsteam" Content="Steam" Margin="5,0"/>

						</StackPanel>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10">
							<Label Content="Pro Tools" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installadvancedip" Content="Advanced IP Scanner" Margin="5,0"/>
							<CheckBox Name="Installmremoteng" Content="mRemoteNG" Margin="5,0"/>
							<CheckBox Name="Installputty" Content="Putty and WinSCP" Margin="5,0"/>
							<CheckBox Name="Installvisualstudio" Content="Visual Studio 2022 Community" Margin="5,0"/>
							<CheckBox Name="Installwireshark" Content="WireShark" Margin="5,0"/>
							<Label Content="Multimedia Tools" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installblender" Content="Blender (3D Graphics)" Margin="5,0"/>
							<CheckBox Name="Installeartrumpet" Content="Eartrumpet (Audio)" Margin="5,0"/>
							<CheckBox Name="Installflameshot" Content="Flameshot (Screenshots)" Margin="5,0"/>
							<CheckBox Name="Installfoobar" Content="Foobar2000 (Music Player)" Margin="5,0"/>
							<CheckBox Name="Installgimp" Content="GIMP (Image Editor)" Margin="5,0"/>
							<CheckBox Name="Installgreenshot" Content="Greenshot (Screenshots)" Margin="5,0"/>
							<CheckBox Name="Installhandbrake" Content="HandBrake" Margin="5,0"/>
							<CheckBox Name="Installimageglass" Content="ImageGlass (Image Viewer)" Margin="5,0"/>
							<CheckBox Name="Installinkscape" Content="Inkscape" Margin="5,0"/>
							<CheckBox Name="Installmpc" Content="Media Player Classic (Video Player)" Margin="5,0"/>
							<CheckBox Name="Installobs" Content="OBS Studio" Margin="5,0"/>
							<CheckBox Name="Installsharex" Content="ShareX (Screenshots)" Margin="5,0"/>
							<CheckBox Name="Installspotify" Content="Spotify" Margin="5,0"/>
							<CheckBox Name="Installvlc" Content="VLC (Video Player)" Margin="5,0"/>
							<CheckBox Name="Installvoicemeeter" Content="Voicemeeter (Audio)" Margin="5,0"/>
							<CheckBox Name="Installzoom" Content="Zoom Video Conference" Margin="5,0,5,5"/>
						</StackPanel>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="2" Margin="10">
							<Label Content="Utilities" FontSize="16" Margin="5,0"/>
							<CheckBox Name="Installsevenzip" Content="7-Zip" Margin="5,0"/>
							<CheckBox Name="Installanydesk" Content="AnyDesk" Margin="5,0"/>
							<CheckBox Name="Installautohotkey" Content="AutoHotkey" Margin="5,0"/>
							<CheckBox Name="Installbitwarden" Content="Bitwarden" Margin="5,0"/>
							<CheckBox Name="Installcpuz" Content="CPU-Z" Margin="5,0"/>
							<CheckBox Name="Installdiscord" Content="Discord" Margin="5,0"/>
							<CheckBox Name="Installetcher" Content="Etcher USB Creator" Margin="5,0"/>
							<CheckBox Name="Installesearch" Content="Everything Search" Margin="5,0"/>
							<CheckBox Name="Installgithubdesktop" Content="GitHub Desktop" Margin="5,0"/>
							<CheckBox Name="Installgpuz" Content="GPU-Z" Margin="5,0"/>
							<CheckBox Name="Installhwinfo" Content="HWInfo" Margin="5,0"/>
							<CheckBox Name="Installkeepass" Content="KeePass" Margin="5,0"/>
							<CheckBox Name="Installmalwarebytes" Content="MalwareBytes" Margin="5,0"/>
							<CheckBox Name="Installnvclean" Content="NVCleanstall" Margin="5,0"/>
							<CheckBox Name="Installpowertoys" Content="Microsoft Powertoys" Margin="5,0"/>
							<CheckBox Name="Installrevo" Content="RevoUninstaller" Margin="5,0"/>
							<CheckBox Name="Installrufus" Content="Rufus Imager" Margin="5,0"/>
							<CheckBox Name="Installslack" Content="Slack" Margin="5,0"/>
							<CheckBox Name="Installteamviewer" Content="TeamViewer" Margin="5,0"/>
							<CheckBox Name="Installttaskbar" Content="Translucent Taskbar" Margin="5,0"/>
							<CheckBox Name="Installtreesize" Content="TreeSize Free" Margin="5,0"/>
							<CheckBox Name="Installwindirstat" Content="WinDirStat" Margin="5,0"/>
							<CheckBox Name="Installterminal" Content="Windows Terminal" Margin="5,0"/>
							<Button Name="install" Background="AliceBlue" Content="Start Install" Margin="20"/>

						</StackPanel>
					</Grid>
				</TabItem>
				<TabItem Header="Tweaks" Visibility="Collapsed" Name="Tab2">
					<Grid Background="#333333">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="1*"/>
							<ColumnDefinition Width="1*"/>
						</Grid.ColumnDefinitions>
						<Grid.RowDefinitions>
							<RowDefinition Height="1*"/>
							<RowDefinition Height="6*"/>
						</Grid.RowDefinitions>
						<StackPanel Background="#777777" Orientation="Horizontal" Grid.Row="0" HorizontalAlignment="Center" Grid.ColumnSpan="2">
							<Label Content="Recommended Selections:" FontSize="17" VerticalAlignment="Center"/>
							<Button Name="desktop" Content="Desktop" Margin="7"/>
							<Button Name="laptop" Content="Laptop" Margin="7"/>
							<Button Name="minimal" Content="Minimal" Margin="7"/>
						</StackPanel>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Row="1" Grid.Column="0" Margin="10,5">
							<Label FontSize="16" Content="Essential Tweaks"/>
							<CheckBox Name="EssTweaksRP" Content="Create Restore Point" Margin="5,0"/>
							<CheckBox Name="EssTweaksOO" Content="Run O and O Shutup" Margin="5,0"/>
							<CheckBox Name="EssTweaksTele" Content="Disable Telemetry" Margin="5,0"/>
							<CheckBox Name="EssTweaksWifi" Content="Disable Wifi-Sense" Margin="5,0"/>
							<CheckBox Name="EssTweaksAH" Content="Disable Activity History" Margin="5,0"/>
							<CheckBox Name="EssTweaksLoc" Content="Disable Location Tracking" Margin="5,0"/>
							<CheckBox Name="EssTweaksHome" Content="Disable Homegroup" Margin="5,0"/>
							<CheckBox Name="EssTweaksStorage" Content="Disable Storage Sense" Margin="5,0"/>
							<CheckBox Name="EssTweaksHiber" Content="Disable Hibernation" Margin="5,0"/>
							<CheckBox Name="EssTweaksDVR" Content="Disable GameDVR" Margin="5,0"/>
							<CheckBox Name="EssTweaksServices" Content="Set Services to Manual" Margin="5,0"/>
							

						</StackPanel>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Row="1" Grid.Column="1" Margin="10,5">
							<Label FontSize="16" Content="Misc. Tweaks"/>
							<CheckBox Name="MiscTweaksPower" Content="Disable Power Throttling" Margin="5,0"/>
							<CheckBox Name="MiscTweaksLapPower" Content="Enable Power Throttling" Margin="5,0"/>
							<CheckBox Name="MiscTweaksNum" Content="Enable NumLock on Startup" Margin="5,0"/>
							<CheckBox Name="MiscTweaksLapNum" Content="Disable Numlock on Startup" Margin="5,0"/>
							<CheckBox Name="MiscTweaksExt" Content="Show File Extensions" Margin="5,0"/>
							<CheckBox Name="MiscTweaksDisplay" Content="Set Display for Performance" Margin="5,0"/>
							<CheckBox Name="MiscTweaksUTC" Content="Set Time to UTC (Dual Boot)" Margin="5,0"/>
							<CheckBox Name="EssTweaksDeBloat" Content="Remove MS Store Apps" Margin="5,0"/>

							<Button Name="tweaksbutton" Background="AliceBlue" Content="Run Tweaks" Margin="20,10,20,0"/>
							<Button Name="undoall" Background="AliceBlue" Content="Undo All Tweaks" Margin="20,5"/>
						</StackPanel>
					</Grid>
				</TabItem>
				<TabItem Header="Config" Visibility="Collapsed" Name="Tab3">
					<Grid Background="#333333">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="1*"/>
							<ColumnDefinition Width="1*"/>
						</Grid.ColumnDefinitions>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10,5">
							<Label Content="Features" FontSize="16"/>
						</StackPanel>
						<StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10,5">
							<Label Content="Old Windows Panels" FontSize="16"/>
						</StackPanel>
					</Grid>
				</TabItem>
				<TabItem Header="Updates" Visibility="Collapsed" Name="Tab4">
					<Grid Background="#333333">
						<TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Updates" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
					</Grid>
				</TabItem>
			</TabControl>
		</Grid>
	</Viewbox>
</Window>


"@
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*"){
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
}
catch{#if it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
        }
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables



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
# Install Tab1
#===========================================================================
$WPFinstall.Add_Click({

    If ( $WPFInstalladobe.IsChecked -eq $true ) { 
        winget install -e --id Adobe.Acrobat.Reader.64-bit | Out-Host
        $WPFInstalladobe.IsChecked = $false
    }
    If ( $WPFInstalladvancedip.IsChecked -eq $true ) { 
        winget install -e Famatech.AdvancedIPScanner | Out-Host
        $WPFInstalladvancedip.IsChecked = $false
    }
    If ( $WPFInstallautohotkey.IsChecked -eq $true ) { 
        winget install -e Lexikos.AutoHotkey | Out-Host
        $WPFInstallautohotkey.IsChecked = $false
    }  
    If ( $WPFInstallbrave.IsChecked -eq $true ) { 
        winget install -e BraveSoftware.BraveBrowser | Out-Host
        $WPFInstallbrave.IsChecked = $false
    }
    If ( $WPFInstallchrome.IsChecked -eq $true ) { 
        winget install -e Google.Chrome | Out-Host
        $WPFInstallchrome.IsChecked = $false
    }
    If ( $WPFInstalldiscord.IsChecked -eq $true ) { 
        winget install -e Discord.Discord | Out-Host
        $WPFInstalldiscord.IsChecked = $false
    }
    If ( $WPFInstallesearch.IsChecked -eq $true ) { 
        winget install -e voidtools.Everything --source winget | Out-Host
        $WPFInstallesearch.IsChecked = $false
    }
    If ( $WPFInstalletcher.IsChecked -eq $true ) { 
        winget install -e Balena.Etcher | Out-Host
        $WPFInstalletcher.IsChecked = $false
    }
    If ( $WPFInstallfirefox.IsChecked -eq $true ) { 
        winget install -e Mozilla.Firefox | Out-Host
        $WPFInstallfirefox.IsChecked = $false
    }
    If ( $WPFInstallgimp.IsChecked -eq $true ) { 
        winget install -e GIMP.GIMP | Out-Host
        $WPFInstallgimp.IsChecked = $false
    }
    If ( $WPFInstallgithubdesktop.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e GitHub.GitHubDesktop | Out-Host
        $WPFInstallgithubdesktop.IsChecked = $false
    }
    If ( $WPFInstallimageglass.IsChecked -eq $true ) { 
        winget install -e DuongDieuPhap.ImageGlass | Out-Host
        $WPFInstallimageglass.IsChecked = $false
    }
    If ( $WPFInstallmpc.IsChecked -eq $true ) { 
        winget install -e clsid2.mpc-hc | Out-Host
        $WPFInstallmpc.IsChecked = $false
    }
    If ( $WPFInstallnotepadplus.IsChecked -eq $true ) { 
        winget install -e Notepad++.Notepad++ | Out-Host
        $WPFInstallnotepadplus.IsChecked = $false
    }
    If ( $WPFInstallpowertoys.IsChecked -eq $true ) { 
        winget install -e Microsoft.PowerToys | Out-Host
        $WPFInstallpowertoys.IsChecked = $false
    }
    If ( $WPFInstallputty.IsChecked -eq $true ) { 
        winget install -e PuTTY.PuTTY | Out-Host
        winget install -e WinSCP.WinSCP | Out-Host
        $WPFInstallputty.IsChecked = $false
    }
    If ( $WPFInstallsevenzip.IsChecked -eq $true ) { 
        winget install -e 7zip.7zip | Out-Host
        $WPFInstallsevenzip.IsChecked = $false
    }
    If ( $WPFInstallsharex.IsChecked -eq $true ) { 
        winget install -e ShareX.ShareX | Out-Host
        $WPFInstallsharex.IsChecked = $false
    }
    If ( $WPFInstallsumatra.IsChecked -eq $true ) { 
        winget install -e SumatraPDF.SumatraPDF | Out-Host
        $WPFInstallsumatra.IsChecked = $false
    }
    If ( $WPFInstallterminal.IsChecked -eq $true ) { 
        winget install -e Microsoft.WindowsTerminal | Out-Host
        $WPFInstallterminal.IsChecked = $false
    }
    If ( $WPFInstallttaskbar.IsChecked -eq $true ) { 
        winget install -e TranslucentTB.TranslucentTB | Out-Host
        $WPFInstallttaskbar.IsChecked = $false
    }
    If ( $WPFInstallvlc.IsChecked -eq $true ) { 
        winget install -e VideoLAN.VLC | Out-Host
        $WPFInstallvlc.IsChecked = $false
    }
    If ( $WPFInstallvscode.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e Microsoft.VisualStudioCode --source winget | Out-Host
        $WPFInstallvscode.IsChecked = $false
    }
    If ( $WPFInstallvscodium.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e VSCodium.VSCodium | Out-Host
        $WPFInstallvscodium.IsChecked = $false
    }
    If ( $WPFInstallanydesk.IsChecked -eq $true ) { 
        winget install -e AnyDeskSoftwareGmbH.AnyDesk | Out-Host
        $WPFInstallanydesk.IsChecked = $false
    }
    If ( $WPFInstallbitwarden.IsChecked -eq $true ) { 
        winget install -e Bitwarden.Bitwarden | Out-Host
        $WPFInstallbitwarden.IsChecked = $false
    }        
    If ( $WPFInstallblender.IsChecked -eq $true ) { 
        winget install -e BlenderFoundation.Blender | Out-Host
        $WPFInstallblender.IsChecked = $false
    }                    
    If ( $WPFInstallchromium.IsChecked -eq $true ) { 
        winget install -e eloston.ungoogled-chromium | Out-Host
        $WPFInstallchromium.IsChecked = $false
    }             
    If ( $WPFInstallcpuz.IsChecked -eq $true ) { 
        winget install -e CPUID.CPU-Z | Out-Host
        $WPFInstallcpuz.IsChecked = $false
    }                            
    If ( $WPFInstalleartrumpet.IsChecked -eq $true ) { 
        winget install -e File-New-Project.EarTrumpet | Out-Host
        $WPFInstalleartrumpet.IsChecked = $false
    }           
    If ( $WPFInstallepicgames.IsChecked -eq $true ) { 
        winget install -e EpicGames.EpicGamesLauncher | Out-Host
        $WPFInstallepicgames.IsChecked = $false
    }                                      
    If ( $WPFInstallflameshot.IsChecked -eq $true ) { 
        winget install -e Flameshot.Flameshot | Out-Host
        $WPFInstallflameshot.IsChecked = $false
    }            
    If ( $WPFInstallfoobar.IsChecked -eq $true ) { 
        winget install -e PeterPawlowski.foobar2000 | Out-Host
        $WPFInstallfoobar.IsChecked = $false
    }                     
    If ( $WPFInstallgog.IsChecked -eq $true ) { 
        winget install -e GOG.Galaxy | Out-Host
        $WPFInstallgog.IsChecked = $false
    }                  
    If ( $WPFInstallgpuz.IsChecked -eq $true ) { 
        winget install -e TechPowerUp.GPU-Z | Out-Host
        $WPFInstallgpuz.IsChecked = $false
    }                 
    If ( $WPFInstallgreenshot.IsChecked -eq $true ) { 
        winget install -e Greenshot.Greenshot | Out-Host
        $WPFInstallgreenshot.IsChecked = $false
    }            
    If ( $WPFInstallhandbrake.IsChecked -eq $true ) { 
        winget install -e HandBrake.HandBrake | Out-Host
        $WPFInstallhandbrake.IsChecked = $false
    }            
    If ( $WPFInstallhwinfo.IsChecked -eq $true ) { 
        winget install -e REALiX.HWiNFO | Out-Host
        $WPFInstallhwinfo.IsChecked = $false
    }                       
    If ( $WPFInstallinkscape.IsChecked -eq $true ) { 
        winget install -e Inkscape.Inkscape | Out-Host
        $WPFInstallinkscape.IsChecked = $false
    }             
    If ( $WPFInstallkeepass.IsChecked -eq $true ) { 
        winget install -e DominikReichl.KeePass | Out-Host
        $WPFInstallkeepass.IsChecked = $false
    }              
    If ( $WPFInstalllibrewolf.IsChecked -eq $true ) { 
        winget install -e LibreWolf.LibreWolf | Out-Host
        $WPFInstalllibrewolf.IsChecked = $false
    }            
    If ( $WPFInstallmalwarebytes.IsChecked -eq $true ) { 
        winget install -e Malwarebytes.Malwarebytes | Out-Host
        $WPFInstallmalwarebytes.IsChecked = $false
    }                          
    If ( $WPFInstallmremoteng.IsChecked -eq $true ) { 
        winget install -e mRemoteNG.mRemoteNG | Out-Host
        $WPFInstallmremoteng.IsChecked = $false
    }                    
    If ( $WPFInstallnvclean.IsChecked -eq $true ) { 
        winget install -e TechPowerUp.NVCleanstall | Out-Host
        $WPFInstallnvclean.IsChecked = $false
    }              
    If ( $WPFInstallobs.IsChecked -eq $true ) { 
        winget install -e OBSProject.OBSStudio | Out-Host
        $WPFInstallobs.IsChecked = $false
    }                  
    If ( $WPFInstallobsidian.IsChecked -eq $true ) { 
        winget install -e Obsidian.Obsidian | Out-Host
        $WPFInstallobsidian.IsChecked = $false
    }                           
    If ( $WPFInstallrevo.IsChecked -eq $true ) { 
        winget install -e RevoUninstaller.RevoUninstaller | Out-Host
        $WPFInstallrevo.IsChecked = $false
    }                 
    If ( $WPFInstallrufus.IsChecked -eq $true ) { 
        winget install -e Rufus.Rufus | Out-Host
        $WPFInstallrufus.IsChecked = $false
    }                             
    If ( $WPFInstallslack.IsChecked -eq $true ) { 
        winget install -e SlackTechnologies.Slack | Out-Host
        $WPFInstallslack.IsChecked = $false
    }                
    If ( $WPFInstallspotify.IsChecked -eq $true ) { 
        winget install -e Spotify.Spotify | Out-Host
        $WPFInstallspotify.IsChecked = $false
    }              
    If ( $WPFInstallsteam.IsChecked -eq $true ) { 
        winget install -e Valve.Steam | Out-Host
        $WPFInstallsteam.IsChecked = $false
    }                             
    If ( $WPFInstallteamviewer.IsChecked -eq $true ) { 
        winget install -e TeamViewer.TeamViewer | Out-Host
        $WPFInstallteamviewer.IsChecked = $false
    }                        
    If ( $WPFInstalltreesize.IsChecked -eq $true ) { 
        winget install -e JAMSoftware.TreeSize.Free | Out-Host
        $WPFInstalltreesize.IsChecked = $false
    }                         
    If ( $WPFInstallvisualstudio.IsChecked -eq $true ) { 
        winget install -e Microsoft.VisualStudio.2022.Community | Out-Host
        $WPFInstallvisualstudio.IsChecked = $false
    }         
    If ( $WPFInstallvivaldi.IsChecked -eq $true ) { 
        winget install -e VivaldiTechnologies.Vivaldi | Out-Host
        $WPFInstallvivaldi.IsChecked = $false
    }                              
    If ( $WPFInstallvoicemeeter.IsChecked -eq $true ) { 
        winget install -e VB-Audio.Voicemeeter | Out-Host
        $WPFInstallvoicemeeter.IsChecked = $false
    }                    
    If ( $WPFInstallwindirstat.IsChecked -eq $true ) { 
        winget install -e WinDirStat.WinDirStat | Out-Host
        $WPFInstallwindirstat.IsChecked = $false
    }           
    If ( $WPFInstallwireshark.IsChecked -eq $true ) { 
        winget install -e WiresharkFoundation.Wireshark | Out-Host
        $WPFInstallwireshark.IsChecked = $false
    }            
    If ( $WPFInstallzoom.IsChecked -eq $true ) { 
        winget install -e Zoom.Zoom | Out-Host
        $WPFInstallzoom.IsChecked = $false
    }    
})

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
        Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type Hex -Value 00000000
        Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type Hex -Value 00000000
        Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type Hex -Value 00000000
        Set-ItemProperty -Path "HKLM:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 00000000
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
        Write-Host "Allowing Home Groups services..."
        Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
        Set-Service "HomeGroupListener" -StartupType Manual
        Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
        Set-Service "HomeGroupProvider" -StartupType Manual
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
        Import-Module BitsTransfer
        Start-BitsTransfer -Source "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -Destination ooshutup10.cfg
        Start-BitsTransfer -Source "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -Destination OOSU10.exe
        ./OOSU10.exe ooshutup10.cfg /quiet
        $WPFEssTweaksOO.IsChecked = $false
    }
    If ( $WPFEssTweaksRP.IsChecked -eq $true ) {
        Write-Host "Creating Restore Point incase something bad happens"
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
        $WPFEssTweaksRP.IsChecked = $false
    }
    If ( $WPFEssTweaksServices.IsChecked -eq $true ) {
        # Service tweaks to Manual 

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
            "fhsvc"                                        #Disables fax histroy
            "gupdate"                                      #Disables google update
            "gupdatem"                                     #Disable another google update
            "stisvc"                                       #Disables Windows Image Acquisition (WIA)
            "AJRouter"                                     #Disables (needed for AllJoyn Router Service)
            "MSDTC"                                        # Disables Distributed Transaction Coordinator
            "WpcMonSvc"                                    #Disables Parental Controls
            "PhoneSvc"                                     #Disables Phone Service(Manages the telephony state on the device)
            "PrintNotify"                                  #Disables Windows printer notifications and extentions
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

            #Write-Host "Installing Windows Media Player..."
            #Enable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart -WarningAction SilentlyContinue | Out-Null

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
        $WPFEssTweaksTele.IsChecked = $false
    }
    If ( $WPFEssTweaksWifi.IsChecked -eq $true ) {
        Write-Host "Disabling Wi-Fi Sense..."
        If (!(Test-Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
            New-Item -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
        $WPFEssTweaksWifi.IsChecked = $false
    }
    If ( $WPFMiscTweaksLapPower.IsChecked -eq $true ) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000000
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
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type DWord -Value 00000001
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
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
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

    Write-Host "Removing Bloatware"

    foreach ($Bloat in $Bloatware) {
        Get-AppxPackage -Name $Bloat| Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
        Write-Host "Trying to remove $Bloat."
    }

    Write-Host "Finished Removing Bloatware Apps"
    $WPFEssTweaksDeBloat.IsChecked = $false
    }
})
#===========================================================================
# Undo All
#===========================================================================
$WPFundoall.Add_Click({
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
})
#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null