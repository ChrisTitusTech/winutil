$inputXML = '<Window x:Class="WinUtility.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WinUtility"
        mc:Ignorable="d"
        Background="#777777"
        WindowStartupLocation="CenterScreen"
        Title="Chris Titus Techs Windows Utility" Height="800" Width="1200">
    <Border Name="dummy" Grid.Column="0" Grid.Row="0">
        <Viewbox Stretch="Uniform" VerticalAlignment="Top">
            <Grid Background="#777777" ShowGridLines="False" Name="MainGrid">
                <Grid.RowDefinitions>
                    <RowDefinition Height=".1*"/>
                    <RowDefinition Height=".9*"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <DockPanel Background="#777777" SnapsToDevicePixels="True" Grid.Row="0" Width="1100">
                    <Image Height="50" Width="100" Name="Icon" SnapsToDevicePixels="True" Source="https://christitus.com/images/logo-full.png" Margin="0,10,0,10"/>
                    <Button Content="Install" HorizontalAlignment="Left" Height="40" Width="100" Background="#222222" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab1BT"/>
                    <Button Content="Tweaks" HorizontalAlignment="Left" Height="40" Width="100" Background="#333333" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab2BT"/>
                    <Button Content="Config" HorizontalAlignment="Left" Height="40" Width="100" Background="#444444" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab3BT"/>
                    <Button Content="Updates" HorizontalAlignment="Left" Height="40" Width="100" Background="#555555" BorderThickness="0,0,0,0" FontWeight="Bold" Foreground="#ffffff" Name="Tab4BT"/>
                </DockPanel>
                <TabControl Grid.Row="1" Padding="-1" Name="TabNav" Background="#222222">
                    <TabItem Header="Install" Visibility="Collapsed" Name="Tab1">
                        <Grid Background="#222222">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10">
                                <Label Content="Browsers" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installbrave" Content="Brave" Margin="5,0"/>
                                <CheckBox Name="Installchrome" Content="Chrome" Margin="5,0"/>
                                <CheckBox Name="Installchromium" Content="Chromium" Margin="5,0"/>
                                <CheckBox Name="Installedge" Content="Edge" Margin="5,0"/>
                                <CheckBox Name="Installfirefox" Content="Firefox" Margin="5,0"/>
                                <CheckBox Name="Installlibrewolf" Content="LibreWolf" Margin="5,0"/>
                                <CheckBox Name="Installtor" Content="Tor Browser" Margin="5,0"/>
                                <CheckBox Name="Installvivaldi" Content="Vivaldi" Margin="5,0"/>
                                <CheckBox Name="Installwaterfox" Content="Waterfox" Margin="5,0"/>

                                <Label Content="Communications" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installdiscord" Content="Discord" Margin="5,0"/>
                                <CheckBox Name="Installhexchat" Content="Hexchat" Margin="5,0"/>
                                <CheckBox Name="Installjami" Content="Jami" Margin="5,0"/>
                                <CheckBox Name="Installmatrix" Content="Matrix" Margin="5,0"/>
                                <CheckBox Name="Installsignal" Content="Signal" Margin="5,0"/>
                                <CheckBox Name="Installskype" Content="Skype" Margin="5,0"/>
                                <CheckBox Name="Installslack" Content="Slack" Margin="5,0"/>
                                <CheckBox Name="Installteams" Content="Teams" Margin="5,0"/>
                                <CheckBox Name="Installtelegram" Content="Telegram" Margin="5,0"/>
                                <CheckBox Name="Installviber" Content="Viber" Margin="5,0"/>
                                <CheckBox Name="Installzoom" Content="Zoom" Margin="5,0"/>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10">
                                <Label Content="Development" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installatom" Content="Atom" Margin="5,0"/>
                                <CheckBox Name="Installgit" Content="Git" Margin="5,0"/>
                                <CheckBox Name="Installgithubdesktop" Content="GitHub Desktop" Margin="5,0"/>
                                <CheckBox Name="Installjava8" Content="OpenJDK Java 8" Margin="5,0"/>
                                <CheckBox Name="Installjava16" Content="OpenJDK Java 16" Margin="5,0"/>
                                <CheckBox Name="Installjava18" Content="Oracle Java 18" Margin="5,0"/>
                                <CheckBox Name="Installjetbrains" Content="Jetbrains Toolbox" Margin="5,0"/>
                                <CheckBox Name="Installnodejs" Content="NodeJS" Margin="5,0"/>
                                <CheckBox Name="Installnodejslts" Content="NodeJS LTS" Margin="5,0"/>
                                <CheckBox Name="Installpython3" Content="Python3" Margin="5,0"/>
                                <CheckBox Name="Installrustlang" Content="Rust" Margin="5,0"/>
                                <CheckBox Name="Installsublime" Content="Sublime" Margin="5,0"/>
                                <CheckBox Name="Installunity" Content="Unity Game Engine" Margin="5,0"/>
                                <CheckBox Name="Installvisualstudio" Content="Visual Studio 2022" Margin="5,0"/>
                                <CheckBox Name="Installvscode" Content="VS Code" Margin="5,0"/>
                                <CheckBox Name="Installvscodium" Content="VS Codium" Margin="5,0"/>

                                <Label Content="Document" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installadobe" Content="Adobe Reader DC" Margin="5,0"/>
                                <CheckBox Name="Installfoxpdf" Content="Foxit PDF" Margin="5,0"/>
                                <CheckBox Name="Installjoplin" Content="Joplin (FOSS Notes)" Margin="5,0"/>
                                <CheckBox Name="Installlibreoffice" Content="LibreOffice" Margin="5,0"/>
                                <CheckBox Name="Installnotepadplus" Content="Notepad++" Margin="5,0"/>
                                <CheckBox Name="Installobsidian" Content="Obsidian" Margin="5,0"/>
                                <CheckBox Name="Installonlyoffice" Content="ONLYOffice Desktop" Margin="5,0"/>
                                <CheckBox Name="Installopenoffice" Content="Apache OpenOffice" Margin="5,0"/>
                                <CheckBox Name="Installsumatra" Content="Sumatra PDF" Margin="5,0"/>
                                <CheckBox Name="Installwinmerge" Content="WinMerge" Margin="5,0"/>

                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="2" Margin="10">


                                <Label Content="Games" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installbluestacks" Content="Bluestacks" Margin="5,0"/>
                                <CheckBox Name="Installepicgames" Content="Epic Games Launcher" Margin="5,0"/>
                                <CheckBox Name="Installgog" Content="GOG Galaxy" Margin="5,0"/>
                                <CheckBox Name="Installorigin" Content="Origin" Margin="5,0"/>
                                <CheckBox Name="Installsteam" Content="Steam" Margin="5,0"/>

                                <Label Content="Pro Tools" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installadvancedip" Content="Advanced IP Scanner" Margin="5,0"/>
                                <CheckBox Name="Installmremoteng" Content="mRemoteNG" Margin="5,0"/>
                                <CheckBox Name="Installputty" Content="Putty" Margin="5,0"/>
                                <CheckBox Name="Installrustdesk" Content="Rust Remote Desktop (FOSS)" Margin="5,0"/>
                                <CheckBox Name="Installsimplewall" Content="SimpleWall" Margin="5,0"/>
                                <CheckBox Name="Installscp" Content="WinSCP" Margin="5,0"/>
                                <CheckBox Name="Installwireshark" Content="WireShark" Margin="5,0"/>

                                <Label Content="Microsoft Tools" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installdotnet3" Content=".NET Desktop Runtime 3.1" Margin="5,0"/>
                                <CheckBox Name="Installdotnet5" Content=".NET Desktop Runtime 5" Margin="5,0"/>
                                <CheckBox Name="Installdotnet6" Content=".NET Desktop Runtime 6" Margin="5,0"/>
                                <CheckBox Name="Installnuget" Content="Nuget" Margin="5,0"/>
                                <CheckBox Name="Installonedrive" Content="OneDrive" Margin="5,0"/>
                                <CheckBox Name="Installpowershell" Content="PowerShell" Margin="5,0"/>
                                <CheckBox Name="Installpowertoys" Content="Powertoys" Margin="5,0"/>
                                <CheckBox Name="Installprocessmonitor" Content="SysInternals Process Monitor" Margin="5,0"/>
                                <CheckBox Name="Installvc2015_64" Content="Visual C++ 2015-2022 64-bit" Margin="5,0"/>
                                <CheckBox Name="Installvc2015_32" Content="Visual C++ 2015-2022 32-bit" Margin="5,0"/>
                                <CheckBox Name="Installterminal" Content="Windows Terminal" Margin="5,0"/>


                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="3" Margin="10">
                                <Label Content="Multimedia Tools" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installaudacity" Content="Audacity" Margin="5,0"/>
                                <CheckBox Name="Installblender" Content="Blender (3D Graphics)" Margin="5,0"/>
                                <CheckBox Name="Installcider" Content="Cider (FOSS Music Player)" Margin="5,0"/>
                                <CheckBox Name="Installeartrumpet" Content="Eartrumpet (Audio)" Margin="5,0"/>
                                <CheckBox Name="Installflameshot" Content="Flameshot (Screenshots)" Margin="5,0"/>
                                <CheckBox Name="Installfoobar" Content="Foobar2000 (Music Player)" Margin="5,0"/>
                                <CheckBox Name="Installgimp" Content="GIMP (Image Editor)" Margin="5,0"/>
                                <CheckBox Name="Installgreenshot" Content="Greenshot (Screenshots)" Margin="5,0"/>
                                <CheckBox Name="Installhandbrake" Content="HandBrake" Margin="5,0"/>
                                <CheckBox Name="Installimageglass" Content="ImageGlass (Image Viewer)" Margin="5,0"/>
                                <CheckBox Name="Installinkscape" Content="Inkscape" Margin="5,0"/>
                                <CheckBox Name="Installitunes" Content="iTunes" Margin="5,0"/>
                                <CheckBox Name="Installkdenlive" Content="Kdenlive (Video Editor)" Margin="5,0"/>
                                <CheckBox Name="Installkodi" Content="Kodi Media Center" Margin="5,0"/>
                                <CheckBox Name="Installklite" Content="K-Lite Codec Standard" Margin="5,0"/>
                                <CheckBox Name="Installkrita" Content="Krita (Image Editor)" Margin="5,0"/>
                                <CheckBox Name="Installmpc" Content="Media Player Classic (Video Player)" Margin="5,0"/>
                                <CheckBox Name="Installobs" Content="OBS Studio" Margin="5,0"/>
                                <CheckBox Name="Installnglide" Content="nGlide (3dfx compatibility)" Margin="5,0"/>
                                <CheckBox Name="Installsharex" Content="ShareX (Screenshots)" Margin="5,0"/>
                                <CheckBox Name="Installstrawberry" Content="Strawberry (Music Player)" Margin="5,0"/>
                                <CheckBox Name="Installvlc" Content="VLC (Video Player)" Margin="5,0"/>
                                <CheckBox Name="Installvoicemeeter" Content="Voicemeeter (Audio)" Margin="5,0"/>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="4" Margin="10">
                                <Label Content="Utilities" FontSize="16" Margin="5,0"/>
                                <CheckBox Name="Installsevenzip" Content="7-Zip" Margin="5,0"/>
                                <CheckBox Name="Installalacritty" Content="Alacritty Terminal" Margin="5,0"/>
                                <CheckBox Name="Installanydesk" Content="AnyDesk" Margin="5,0"/>
                                <CheckBox Name="Installautohotkey" Content="AutoHotkey" Margin="5,0"/>
                                <CheckBox Name="Installbitwarden" Content="Bitwarden" Margin="5,0"/>
                                <CheckBox Name="Installcpuz" Content="CPU-Z" Margin="5,0"/>
                                <CheckBox Name="Installetcher" Content="Etcher USB Creator" Margin="5,0"/>
                                <CheckBox Name="Installesearch" Content="Everything Search" Margin="5,0"/>
                                <CheckBox Name="Installflux" Content="f.lux Redshift" Margin="5,0"/>
                                <CheckBox Name="Installgpuz" Content="GPU-Z" Margin="5,0"/>
                                <CheckBox Name="Installglaryutilities" Content="Glary Utilities" Margin="5,0"/>
                                <CheckBox Name="Installhwinfo" Content="HWInfo" Margin="5,0"/>
                                <CheckBox Name="Installidm" Content="Internet Download Manager" Margin="5,0"/>
                                <CheckBox Name="Installjdownloader" Content="J Download Manager" Margin="5,0"/>
                                <CheckBox Name="Installkeepass" Content="KeePassXC" Margin="5,0"/>
                                <CheckBox Name="Installmalwarebytes" Content="MalwareBytes" Margin="5,0"/>
                                <CheckBox Name="Installnvclean" Content="NVCleanstall" Margin="5,0"/>
                                <CheckBox Name="Installopenshell" Content="Open Shell (Start Menu)" Margin="5,0"/>
                                <CheckBox Name="Installprocesslasso" Content="Process Lasso" Margin="5,0"/>
                                <CheckBox Name="Installqbittorrent" Content="qBittorrent" Margin="5,0"/>
                                <CheckBox Name="Installrevo" Content="RevoUninstaller" Margin="5,0"/>
                                <CheckBox Name="Installrufus" Content="Rufus Imager" Margin="5,0"/>
                                <CheckBox Name="Installsandboxie" Content="Sandboxie Plus" Margin="5,0"/>
                                <CheckBox Name="Installshell" Content="Shell (Expanded Context Menu)" Margin="5,0"/>
                                <CheckBox Name="Installteamviewer" Content="TeamViewer" Margin="5,0"/>
                                <CheckBox Name="Installttaskbar" Content="Translucent Taskbar" Margin="5,0"/>
                                <CheckBox Name="Installtreesize" Content="TreeSize Free" Margin="5,0"/>
                                <CheckBox Name="Installtwinkletray" Content="Twinkle Tray" Margin="5,0"/>
                                <CheckBox Name="Installwindirstat" Content="WinDirStat" Margin="5,0"/>
                                <CheckBox Name="Installwiztree" Content="WizTree" Margin="5,0"/>
                                <Button Name="install" Background="AliceBlue" Content="Start Install" HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="150" ToolTip="Install all checked programs"/>
                                <Button Name="InstallUpgrade" Background="AliceBlue" Content="Upgrade Installs" HorizontalAlignment = "Left" Margin="5,0,0,5" Padding="20,5" Width="150" ToolTip="Upgrade All Existing Programs on System"/>

                            </StackPanel>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Tweaks" Visibility="Collapsed" Name="Tab2">
                        <Grid Background="#333333">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height=".10*"/>
                                <RowDefinition Height=".10*"/>
                                <RowDefinition Height=".80*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Background="#777777" Orientation="Horizontal" Grid.Row="0" HorizontalAlignment="Center" Grid.ColumnSpan="2" Margin="10">
                                <Label Content="Recommended Selections:" FontSize="17" VerticalAlignment="Center"/>
                                <Button Name="desktop" Content="Desktop" Margin="7"/>
                                <Button Name="laptop" Content="Laptop" Margin="7"/>
                                <Button Name="minimal" Content="Minimal" Margin="7"/>
                            </StackPanel>
                            <StackPanel Background="#777777" Orientation="Horizontal" Grid.Row="1" HorizontalAlignment="Center" Grid.ColumnSpan="2" Margin="10">
                                <TextBlock Padding="10">
                                    Note: Hover over items to get a better description. Please be careful as many of these tweaks will heavily modify your system.
                                    <LineBreak/>Recommended selections are for normal users and if you are unsure do NOT check anything else!
                                </TextBlock>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Row="2" Grid.Column="0" Margin="10,5">
                                <Label FontSize="16" Content="Essential Tweaks"/>
                                <CheckBox Name="EssTweaksRP" Content="Create Restore Point" Margin="5,0" ToolTip="Creates a Windows Restore point before modifying system. Can use Windows System Restore to rollback to before tweaks were applied"/>
                                <CheckBox Name="EssTweaksOO" Content="Run OO Shutup" Margin="5,0" ToolTip="Runs OO Shutup from https://www.oo-software.com/en/shutup10"/>
                                <CheckBox Name="EssTweaksTele" Content="Disable Telemetry" Margin="5,0" ToolTip="Disables Microsoft Telemetry. Note: This will lock many Edge Browser settings. Microsoft spys heavily on you when using the Edge browser."/>
                                <CheckBox Name="EssTweaksWifi" Content="Disable Wifi-Sense" Margin="5,0" ToolTip="Wifi Sense is a spying service that phones home all nearby scaned wifi networks and your current geo location."/>
                                <CheckBox Name="EssTweaksAH" Content="Disable Activity History" Margin="5,0" ToolTip="This erases recent docs, clipboard, and run history."/>
                                <CheckBox Name="EssTweaksDeleteTempFiles" Content="Delete Temporary Files" Margin="5,0" ToolTip="Erases TEMP Folders"/>
                                <CheckBox Name="EssTweaksDiskCleanup" Content="Run Disk Cleanup" Margin="5,0" ToolTip="Runs Disk Cleanup on Drive C: and removes old Windows Updates."/>
                                <CheckBox Name="EssTweaksLoc" Content="Disable Location Tracking" Margin="5,0" ToolTip="Disables Location Tracking...DUH!"/>
                                <CheckBox Name="EssTweaksHome" Content="Disable Homegroup" Margin="5,0" ToolTip="Disables HomeGroup - Windows 11 doesnt have this, it was awful."/>
                                <CheckBox Name="EssTweaksStorage" Content="Disable Storage Sense" Margin="5,0" ToolTip="Storage Sense is supposed to delete temp files automatically, but often runs at wierd times and mostly doesnt do much. Although when it was introduced in Win 10 (1809 Version) it deleted peoples documents... So there is that."/>
                                <CheckBox Name="EssTweaksHiber" Content="Disable Hibernation" Margin="5,0" ToolTip="Hibernation is really meant for laptops as it saves whats in memory before turning the pc off. It really should never be used, but some people are lazy and rely on it. Dont be like Bob. Bob likes hibernation."/>
                                <CheckBox Name="EssTweaksDVR" Content="Disable GameDVR" Margin="5,0" ToolTip="GameDVR is a Windows App that is a dependancy for some Store Games. Ive never met someone that likes it, but its there for the XBOX crowd."/>
                                <CheckBox Name="EssTweaksServices" Content="Set Services to Manual" Margin="5,0" ToolTip="Turns a bunch of system services to manual that dont need to be running all the time. This is pretty harmless as if the service is needed, it will simply start on demand."/>
                                <Label Content="Dark Theme" />
                                <Button Name="EnableDarkMode" Background="AliceBlue" Content="Enable" HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="150"/>
                                <Button Name="DisableDarkMode" Background="AliceBlue" Content="Disable" HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="150"/>
                                <Label Content="Performance Plans" />
                                <Button Name="AddUltPerf" Background="AliceBlue" Content="Add Ultimate Performance Profile" HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="300"/>
                                <Button Name="RemoveUltPerf" Background="AliceBlue" Content="Remove Ultimate Performance Profile" HorizontalAlignment = "Left" Margin="5,0,0,5" Padding="20,5" Width="300"/>

                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Row="2" Grid.Column="1" Margin="10,5">
                                <Label FontSize="16" Content="Misc. Tweaks"/>
                                <CheckBox Name="MiscTweaksPower" Content="Disable Power Throttling" Margin="5,0" ToolTip="This is mainly for Laptops, It disables Power Throttling and will use more battery."/>
                                <CheckBox Name="MiscTweaksLapPower" Content="Enable Power Throttling" Margin="5,0" ToolTip="ONLY FOR LAPTOPS! Do not use on a desktop."/>
                                <CheckBox Name="MiscTweaksNum" Content="Enable NumLock on Startup" Margin="5,0" ToolTip="This creates a time vortex and send you back to the past... or it simply turns numlock on at startup"/>
                                <CheckBox Name="MiscTweaksLapNum" Content="Disable Numlock on Startup" Margin="5,0" ToolTip="Disables Numlock... Very useful when you are on a laptop WITHOUT 9-key and this fixes that issue when the numlock is enabled!"/>
                                <CheckBox Name="MiscTweaksExt" Content="Show File Extensions" Margin="5,0"/>
                                <CheckBox Name="MiscTweaksDisplay" Content="Set Display for Performance" Margin="5,0" ToolTip="Sets the system preferences to performance. You can do this manually with sysdm.cpl as well."/>
                                <CheckBox Name="MiscTweaksUTC" Content="Set Time to UTC (Dual Boot)" Margin="5,0" ToolTip="Essential for computers that are dual booting. Fixes the time sync with Linux Systems."/>
                                <CheckBox Name="MiscTweaksDisableUAC" Content="Disable UAC" Margin="5,0" ToolTip="Disables User Account Control. Only recommended for Expert Users."/>
                                <CheckBox Name="MiscTweaksDisableNotifications" Content="Disable Notification" Margin="5,0" ToolTip="Disables all Notifications"/>
                                <CheckBox Name="MiscTweaksDisableTPMCheck" Content="Disable TPM on Update" Margin="5,0" ToolTip="Add the Windows 11 Bypass for those that want to upgrade their Windows 10."/>
                                <CheckBox Name="EssTweaksDeBloat" Content="Remove ALL MS Store Apps" Margin="5,0" ToolTip="USE WITH CAUTION!!!!! This will remove ALL Microsoft store apps other than the essentials to make winget work. Games installed by MS Store ARE INCLUDED!"/>
                                <CheckBox Name="EssTweaksRemoveCortana" Content="Remove Cortana" Margin="5,0" ToolTip="Removes Cortana, but often breaks search... if you are a heavy windows search users, this is NOT recommended."/>
                                <CheckBox Name="EssTweaksRemoveEdge" Content="Remove Microsoft Edge" Margin="5,0" ToolTip="Removes MS Edge when it gets reinstalled by updates."/>
                                <CheckBox Name="MiscTweaksRightClickMenu" Content="Set Classic Right-Click Menu " Margin="5,0" ToolTip="Great Windows 11 tweak to bring back good context menus when right clicking things in explorer."/>
                                <Label Content="DNS" />
							    <ComboBox Name="changedns"  Height = "20" Width = "150" HorizontalAlignment = "Left" Margin="5,5"> 
								    <ComboBoxItem IsSelected="True" Content = "Default"/> 
								    <ComboBoxItem Content = "Google"/> 
								    <ComboBoxItem Content = "Cloud Flare"/> 
								    <ComboBoxItem Content = "Level3"/> 
								    <ComboBoxItem Content = "Open DNS"/> 
							    </ComboBox> 
                                <Button Name="tweaksbutton" Background="AliceBlue" Content="Run Tweaks  " HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="150"/>
                                <Button Name="undoall" Background="AliceBlue" Content="Undo Tweaks" HorizontalAlignment = "Left" Margin="5,0" Padding="20,5" Width="150"/>
                            </StackPanel>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Config" Visibility="Collapsed" Name="Tab3">
                        <Grid Background="#444444">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10,5">
                                <Label Content="Features" FontSize="16"/>
                                <CheckBox Name="Featuresdotnet" Content="All .Net Framework (2,3,4)" Margin="5,0"/>
                                <CheckBox Name="Featureshyperv" Content="HyperV Virtualization" Margin="5,0"/>
                                <CheckBox Name="Featureslegacymedia" Content="Legacy Media (WMP, DirectPlay)" Margin="5,0"/>
                                <CheckBox Name="Featurenfs" Content="NFS - Network File System" Margin="5,0"/>
                                <CheckBox Name="Featurewsl" Content="Windows Subsystem for Linux" Margin="5,0"/>
                                <Button Name="FeatureInstall" FontSize="14" Background="AliceBlue" Content="Install Features" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="150"/>
                                <Label Content="Fixes" FontSize="16"/>
                                <Button Name="PanelAutologin" FontSize="14" Background="AliceBlue" Content="Set Up Autologin" HorizontalAlignment = "Left" Margin="5,2" Padding="20,5" Width="300"/>
                                <Button Name="FixesUpdate" FontSize="14" Background="AliceBlue" Content="Reset Windows Update" HorizontalAlignment = "Left" Margin="5,2" Padding="20,5" Width="300"/>
                                <Button Name="PanelDISM" FontSize="14" Background="AliceBlue" Content="System Corruption Scan" HorizontalAlignment = "Left" Margin="5,2" Padding="20,5" Width="300"/>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10,5">
                                <Label Content="Legacy Windows Panels" FontSize="16"/>
                                <Button Name="Panelcontrol" FontSize="14" Background="AliceBlue" Content="Control Panel" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                                <Button Name="Panelnetwork" FontSize="14" Background="AliceBlue" Content="Network Connections" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                                <Button Name="Panelpower" FontSize="14" Background="AliceBlue" Content="Power Panel" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                                <Button Name="Panelsound" FontSize="14" Background="AliceBlue" Content="Sound Settings" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                                <Button Name="Panelsystem" FontSize="14" Background="AliceBlue" Content="System Properties" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                                <Button Name="Paneluser" FontSize="14" Background="AliceBlue" Content="User Accounts" HorizontalAlignment = "Left" Margin="5" Padding="20,5" Width="200"/>
                            </StackPanel>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Updates" Visibility="Collapsed" Name="Tab4">
                        <Grid Background="#555555">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10,5">
                                <Button Name="Updatesdefault" FontSize="16" Background="AliceBlue" Content="Default (Out of Box) Settings" Margin="20,0,20,10" Padding="10"/>
                                <TextBlock Margin="20,0,20,0" Padding="10" TextWrapping="WrapWithOverflow" MaxWidth="300">This is the default settings that come with Windows. <LineBreak/><LineBreak/> No modifications are made and will remove any custom windows update settings.<LineBreak/><LineBreak/>Note: If you still encounter update errors, reset all updates in the config tab. That will restore ALL Microsoft Update Services from their servers and reinstall them to default settings.</TextBlock>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10,5">
                                <Button Name="Updatessecurity" FontSize="16" Background="AliceBlue" Content="Security (Recommended) Settings" Margin="20,0,20,10" Padding="10"/>
                                <TextBlock Margin="20,0,20,0" Padding="10" TextWrapping="WrapWithOverflow" MaxWidth="300">This is my recommended setting I use on all computers.<LineBreak/><LineBreak/> It will delay feature updates by 2 years and will install security updates 4 days after release.<LineBreak/><LineBreak/>Feature Updates: Adds features and often bugs to systems when they are released. You want to delay these as long as possible.<LineBreak/><LineBreak/>Security Updates: Typically these are pressing security flaws that need to be patched quickly. You only want to delay these a couple of days just to see if they are safe and dont break other systems. You dont want to go without these for ANY extended periods of time.</TextBlock>
                            </StackPanel>
                            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="2" Margin="10,5">
                                <Button Name="Updatesdisable" FontSize="16" Background="AliceBlue" Content="Disable ALL Updates (NOT RECOMMENDED!)" Margin="20,0,20,10" Padding="10,10,10,10"/>
                                <TextBlock Margin="20,0,20,0" Padding="10" TextWrapping="WrapWithOverflow" MaxWidth="300">This completely disables ALL Windows Updates and is NOT RECOMMENDED.<LineBreak/><LineBreak/> However, it can be suitable if you use your system for a select purpose and do not actively browse the internet. <LineBreak/><LineBreak/>Note: Your system will be easier to hack and infect without security updates.</TextBlock>
                                <TextBlock Text=" " Margin="20,0,20,0" Padding="10" TextWrapping="WrapWithOverflow" MaxWidth="300"/>

                            </StackPanel>

                        </Grid>
                    </TabItem>
                </TabControl>
            </Grid>
        </Viewbox>
    </Border>
</Window>
'
$preset = '{
  "desktop": [
    "EssTweaksAH",
    "EssTweaksDVR",
    "EssTweaksHiber",
    "EssTweaksHome",
    "EssTweaksLoc",
    "EssTweaksOO",
    "EssTweaksRP",
    "EssTweaksServices",
    "EssTweaksStorage",
    "EssTweaksTele",
    "EssTweaksWifi",
    "MiscTweaksPower",
    "MiscTweaksNum"
  ],
  "laptop": [
    "EssTweaksAH",
    "EssTweaksDVR",
    "EssTweaksHome",
    "EssTweaksLoc",
    "EssTweaksOO",
    "EssTweaksRP",
    "EssTweaksServices",
    "EssTweaksStorage",
    "EssTweaksTele",
    "EssTweaksWifi",
    "MiscTweaksLapPower",
    "MiscTweaksLapNum"
  ],
  "minimal": [
    "EssTweaksHome",
    "EssTweaksOO",
    "EssTweaksRP",
    "EssTweaksServices",
    "EssTweaksTele"
  ]
}
' | convertfrom-json
$tweaks = '{
  "EssTweaksAH": {
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "EnableActivityFeed",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "PublishUserActivities",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "UploadUserActivities",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  },
  "EssTweaksDVR": {
    "registry": [
      {
        "Path": "HKLM:\\System\\GameConfigStore",
        "Name": "GameDVR_DXGIHonorFSEWindowsCompatible",
        "Type": "Hex",
        "Value": "00000000",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\System\\GameConfigStore",
        "Name": "GameDVR_HonorUserFSEBehaviorMode",
        "Type": "Hex",
        "Value": "00000000",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\System\\GameConfigStore",
        "Name": "GameDVR_EFSEFeatureFlags",
        "Type": "Hex",
        "Value": "00000000",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\System\\GameConfigStore",
        "Name": "GameDVR_Enabled",
        "Type": "Hex",
        "Value": "00000000",
        "OriginalValue": "1"
      }
    ]
  },
  "EssTweaksHiber": {
    "registry": [
      {
        "Path": "HKLM:\\System\\CurrentControlSet\\Control\\Session Manager\\Power",
        "Name": "GameDVR_DXGIHonorFSEWindowsCompatible",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FlyoutMenuSettings",
        "Name": "GameDVR_HonorUserFSEBehaviorMode",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  },
  "EssTweaksHome": {
    "service": [
      {
        "Name": "HomeGroupListener",
        "StartupType": "Manual",
        "OriginalType": "Automatic"
      },
      {
        "Name": "HomeGroupProvider",
        "StartupType": "Manual",
        "OriginalType": "Automatic"
      }
    ]
  },
  "EssTweaksLoc": {
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location",
        "Name": "Value",
        "Type": "String",
        "Value": "Deny",
        "OriginalValue": "Allow"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Sensor\\Overrides\\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}",
        "Name": "SensorPermissionState",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\lfsvc\\Service\\Configuration",
        "Name": "Status",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SYSTEM\\Maps",
        "Name": "AutoUpdateEnabled",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  },
  "EssTweaksServices": {
    "service": [
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "diagnosticshub.standardcollector.service"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "DiagTrack"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "DPS"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "dmwappushservice"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "lfsvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "MapsBroker"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "NetTcpPortSharing"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "RemoteAccess"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "RemoteRegistry"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "SharedAccess"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "TrkWks"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WMPNetworkSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WSearch"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "XblAuthManager"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "XblGameSave"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "XboxNetApiSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "XboxGipSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "ndu"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WerSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "Fax"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "fhsvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "gupdate"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "gupdatem"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "stisvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "AJRouter"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "MSDTC"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WpcMonSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "PhoneSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "PrintNotify"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "PcaSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WPDBusEnum"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "seclogon"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "SysMain"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "lmhosts"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "wisvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "FontCache"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "RetailDemo"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "ALG"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "SCardSvr"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "EntAppSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "BthAvctpSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "Browser"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "BthAvctpSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "iphlpsvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "edgeupdate"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "MicrosoftEdgeElevationService"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "edgeupdatem"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "SEMgrSvc"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "PerfHost"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "BcastDVRUserService_48486de"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "CaptureService_48486de"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "cbdhsvc_48486de"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "WpnService"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "RtkBtManServ"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "QWAVE"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HPAppHelperCap"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HPDiagsCap"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HPNetworkCap"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HPSysInfoCap"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HpTouchpointAnalyticsService"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "HvHost"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmickvpexchange"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmicguestinterface"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmicshutdown"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmicheartbeat"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmicvmsession"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmicrdv"
      },
      {
        "StartupType": "Manual",
        "OriginalType": "Automatic",
        "Name": "vmictimesync"
      }
    ]
  },
  "EssTweaksTele": {
    "ScheduledTask": [
      {
        "Name": "Microsoft\\Windows\\Application Experience\\Microsoft Compatibility Appraiser",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Application Experience\\ProgramDataUpdater",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Autochk\\Proxy",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Customer Experience Improvement Program\\Consolidator",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Customer Experience Improvement Program\\UsbCeip",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticDataCollector",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Feedback\\Siuf\\DmClient",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Feedback\\Siuf\\DmClientOnScenarioDownload",
        "State": "Disabled",
        "OriginalState": "Enabled"
      },
      {
        "Name": "Microsoft\\Windows\\Windows Error Reporting\\QueueReporting",
        "State": "Disabled",
        "OriginalState": "Enabled"
      }
    ],
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
        "type": "Dword",
        "value": 0,
        "name": "AllowTelemetry",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
        "OriginalValue": "1",
        "name": "AllowTelemetry",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "ContentDeliveryAllowed",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "OemPreInstalledAppsEnabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "PreInstalledAppsEnabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "PreInstalledAppsEverEnabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SilentInstalledAppsEnabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SubscribedContent-338387Enabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SubscribedContent-338388Enabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SubscribedContent-338389Enabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SubscribedContent-353698Enabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "OriginalValue": "1",
        "name": "SystemPaneSuggestionsEnabled",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "OriginalValue": "0",
        "name": "DisableWindowsConsumerFeatures",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Siuf\\Rules",
        "OriginalValue": "0",
        "name": "NumberOfSIUFInPeriod",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
        "OriginalValue": "0",
        "name": "DoNotShowFeedbackNotifications",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "OriginalValue": "0",
        "name": "DisableTailoredExperiencesWithDiagnosticData",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AdvertisingInfo",
        "OriginalValue": "0",
        "name": "DisabledByGroupPolicy",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Windows Error Reporting",
        "OriginalValue": "0",
        "name": "Disabled",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DeliveryOptimization\\Config",
        "OriginalValue": "1",
        "name": "DODownloadMode",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Remote Assistance",
        "OriginalValue": "1",
        "name": "fAllowToGetHelp",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\OperationStatusManager",
        "OriginalValue": "0",
        "name": "EnthusiastMode",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "OriginalValue": "1",
        "name": "ShowTaskViewButton",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\People",
        "OriginalValue": "1",
        "name": "PeopleBand",
        "value": 0,
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "OriginalValue": "1",
        "name": "LaunchTo",
        "value": 1,
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DriverSearching",
        "OriginalValue": "1",
        "name": "SearchOrderConfig",
        "value": "00000000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
        "OriginalValue": "1",
        "name": "SystemResponsiveness",
        "value": "0000000a",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
        "OriginalValue": "1",
        "name": "NetworkThrottlingIndex",
        "value": "0000000a",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control",
        "OriginalValue": "1",
        "name": "WaitToKillServiceTimeout",
        "value": "2000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "MenuShowDelay",
        "value": "0",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "WaitToKillAppTimeout",
        "value": "5000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "AutoEndTasks",
        "value": "1",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "LowLevelHooksTimeout",
        "value": "00001000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "WaitToKillServiceTimeout",
        "value": "00002000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management",
        "OriginalValue": "0",
        "name": "ClearPageFileAtShutdown",
        "value": "00000000",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SYSTEM\\ControlSet001\\Services\\Ndu",
        "OriginalValue": "1",
        "name": "Start",
        "value": "00000004",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\Control Panel\\Mouse",
        "OriginalValue": "1",
        "name": "MouseHoverTime",
        "value": "00000010",
        "type": "Dword"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters",
        "OriginalValue": "1",
        "name": "IRPStackSize",
        "value": "20",
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Feeds",
        "OriginalValue": "1",
        "name": "EnableFeeds",
        "value": "0",
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Feeds",
        "OriginalValue": "1",
        "name": "ShellFeedsTaskbarViewMode",
        "value": "2",
        "type": "Dword"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
        "OriginalValue": "1",
        "name": "HideSCAMeetNow",
        "value": "1",
        "type": "Dword"
      }
    ],
    "service": [
      {
        "Name": "DiagTrack",
        "StartupType": "Disabled",
        "OriginalType": "Automatic"
      },
      {
        "Name": "dmwappushservice",
        "StartupType": "Disabled",
        "OriginalType": "Manual"
      },
      {
        "Name": "SysMain",
        "StartupType": "Disabled",
        "OriginalType": "Manual"
      }
    ],
    "InvokeScript": [
      "bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null
        If ((get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\" -Name CurrentBuild).CurrentBuild -lt 22557) {
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
            Do {
                Start-Sleep -Milliseconds 100
                $preferences = Get-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -ErrorAction SilentlyContinue
            } Until ($preferences)
            Stop-Process $taskmgr
            $preferences.Preferences[28] = 0
            Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -Type Binary -Value $preferences.Preferences
        }
        Remove-Item -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\" -Recurse -ErrorAction SilentlyContinue  

        # Group svchost.exe processes
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
        Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\" -Name \"SvcHostSplitThresholdInKB\" -Type DWord -Value $ram -Force

        $autoLoggerDir = \"$env:PROGRAMDATA\\Microsoft\\Diagnosis\\ETLLogs\\AutoLogger\"
        If (Test-Path \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\") {
            Remove-Item \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\"
        }
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null"
    ]
  },
  "EssTweaksWifi": {
    "registry": [
      {
        "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowWiFiHotSpotReporting",
        "Name": "Value",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowAutoConnectToWiFiSenseHotspots",
        "Name": "Value",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  },
  "MiscTweaksLapPower": {
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling",
        "Name": "PowerThrottlingOff",
        "Type": "DWord",
        "Value": "00000000",
        "OriginalValue": "00000001"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power",
        "Name": "HiberbootEnabled",
        "Type": "DWord",
        "Value": "0000001",
        "OriginalValue": "0000000"
      }
    ]
  },
  "MiscTweaksPower": {
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling",
        "Name": "PowerThrottlingOff",
        "Type": "DWord",
        "Value": "00000001",
        "OriginalValue": "00000000"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power",
        "Name": "HiberbootEnabled",
        "Type": "DWord",
        "Value": "0000000",
        "OriginalValue": "00000001"
      }
    ]
  },
  "MiscTweaksExt": {
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "Name": "HideFileExt",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      }
    ]
  },
  "MiscTweaksUTC": {
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation",
        "Name": "RealTimeIsUniversal",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "0"
      }
    ]
  },
  "MiscTweaksDisplay": {
    "registry": [
      {
        "path": "HKCU:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "DragFullWindows",
        "value": "0",
        "type": "String"
      },
      {
        "path": "HKCU:\\Control Panel\\Desktop",
        "OriginalValue": "1",
        "name": "MenuShowDelay",
        "value": "200",
        "type": "String"
      },
      {
        "path": "HKCU:\\Control Panel\\Desktop\\WindowMetrics",
        "OriginalValue": "1",
        "name": "MinAnimate",
        "value": "0",
        "type": "String"
      },
      {
        "path": "HKCU:\\Control Panel\\Keyboard",
        "OriginalValue": "1",
        "name": "KeyboardDelay",
        "value": "0",
        "type": "DWord"
      },
      {
        "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "OriginalValue": "1",
        "name": "ListviewAlphaSelect",
        "value": "0",
        "type": "DWord"
      },
      {
        "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "OriginalValue": "1",
        "name": "ListviewShadow",
        "value": "0",
        "type": "DWord"
      },
      {
        "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "OriginalValue": "1",
        "name": "TaskbarAnimations",
        "value": "0",
        "type": "DWord"
      },
      {
        "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects",
        "OriginalValue": "1",
        "name": "VisualFXSetting",
        "value": "3",
        "type": "DWord"
      },
      {
        "path": "HKCU:\\Software\\Microsoft\\Windows\\DWM",
        "OriginalValue": "1",
        "name": "EnableAeroPeek",
        "value": "0",
        "type": "DWord"
      }
    ],
    "InvokeScript": [
      "Set-ItemProperty -Path \"HKCU:\\Control Panel\\Desktop\" -Name \"UserPreferencesMask\" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))"
    ]
  },
  "EssTweaksDeBloat": {
    "appx": [
      "Microsoft.Microsoft3DViewer",
      "Microsoft.AppConnector",
      "Microsoft.BingFinance",
      "Microsoft.BingNews",
      "Microsoft.BingSports",
      "Microsoft.BingTranslator",
      "Microsoft.BingWeather",
      "Microsoft.BingFoodAndDrink",
      "Microsoft.BingHealthAndFitness",
      "Microsoft.BingTravel",
      "Microsoft.MinecraftUWP",
      "Microsoft.GamingServices",
      "Microsoft.GetHelp",
      "Microsoft.Getstarted",
      "Microsoft.Messaging",
      "Microsoft.Microsoft3DViewer",
      "Microsoft.MicrosoftSolitaireCollection",
      "Microsoft.NetworkSpeedTest",
      "Microsoft.News",
      "Microsoft.Office.Lens",
      "Microsoft.Office.Sway",
      "Microsoft.Office.OneNote",
      "Microsoft.OneConnect",
      "Microsoft.People",
      "Microsoft.Print3D",
      "Microsoft.SkypeApp",
      "Microsoft.Wallet",
      "Microsoft.Whiteboard",
      "Microsoft.WindowsAlarms",
      "microsoft.windowscommunicationsapps",
      "Microsoft.WindowsFeedbackHub",
      "Microsoft.WindowsMaps",
      "Microsoft.WindowsPhone",
      "Microsoft.WindowsSoundRecorder",
      "Microsoft.XboxApp",
      "Microsoft.ConnectivityStore",
      "Microsoft.CommsPhone",
      "Microsoft.ScreenSketch",
      "Microsoft.Xbox.TCUI",
      "Microsoft.XboxGameOverlay",
      "Microsoft.XboxGameCallableUI",
      "Microsoft.XboxSpeechToTextOverlay",
      "Microsoft.MixedReality.Portal",
      "Microsoft.XboxIdentityProvider",
      "Microsoft.ZuneMusic",
      "Microsoft.ZuneVideo",
      "Microsoft.Getstarted",
      "Microsoft.MicrosoftOfficeHub",
      "*EclipseManager*",
      "*ActiproSoftwareLLC*",
      "*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
      "*Duolingo-LearnLanguagesforFree*",
      "*PandoraMediaInc*",
      "*CandyCrush*",
      "*BubbleWitch3Saga*",
      "*Wunderlist*",
      "*Flipboard*",
      "*Twitter*",
      "*Facebook*",
      "*Royal Revolt*",
      "*Sway*",
      "*Speed Test*",
      "*Dolby*",
      "*Viber*",
      "*ACGMediaPlayer*",
      "*Netflix*",
      "*OneCalendar*",
      "*LinkedInforWindows*",
      "*HiddenCityMysteryofShadows*",
      "*Hulu*",
      "*HiddenCity*",
      "*AdobePhotoshopExpress*",
      "*HotspotShieldFreeVPN*",
      "*Microsoft.Advertising.Xaml*"
    ]
  },
  "EssTweaksOO": {
    "InvokeScript": [
      "Import-Module BitsTransfer
      Start-BitsTransfer -Source \"https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg\" -Destination C:\\Windows\\Temp\\ooshutup10.cfg
      Start-BitsTransfer -Source \"https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe\" -Destination C:\\Windows\\Temp\\OOSU10.exe
      C:\\Windows\\Temp\\OOSU10.exe C:\\Windows\\Temp\\ooshutup10.cfg /quiet"
    ]
  },
  "EssTweaksRP": {
    "InvokeScript": [
      "Enable-ComputerRestore -Drive \"C:\\\"
      Checkpoint-Computer -Description \"RestorePoint1\" -RestorePointType \"MODIFY_SETTINGS\""
    ]
  },
  "EssTweaksStorage": {
    "InvokeScript": [
      "Remove-Item -Path \"HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy\" -Recurse -ErrorAction SilentlyContinue"
    ]
  },
  "MiscTweaksLapNum": {
    "InvokeScript": [
      "If (!(Test-Path \"HKU:\")) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
       }
       Set-ItemProperty -Path \"HKU:\\.DEFAULT\\Control Panel\\Keyboard\" -Name \"InitialKeyboardIndicators\" -Type DWord -Value 0"
    ]
  },
  "MiscTweaksNum": {
    "InvokeScript": [
      "If (!(Test-Path \"HKU:\")) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
       }
       Set-ItemProperty -Path \"HKU:\\.DEFAULT\\Control Panel\\Keyboard\" -Name \"InitialKeyboardIndicators\" -Type DWord -Value 2"
    ]
  },
  "EssTweaksRemoveEdge": {
    "InvokeScript": [
      "Invoke-WebRequest -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/Edge_Removal.bat | Invoke-Expression"
    ]
  },
  "MiscTweaksDisableNotifications": {
    "InvokeScript": [
      "New-Item -Path \"HKCU:\\Software\\Policies\\Microsoft\\Windows\" -Name \"Explorer\" -force
    New-ItemProperty -Path \"HKCU:\\Software\\Policies\\Microsoft\\Windows\\Explorer\" -Name \"DisableNotificationCenter\" -PropertyType \"DWord\" -Value 1
    New-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\PushNotifications\" -Name \"ToastEnabled\" -PropertyType \"DWord\" -Value 0 -force"
    ]
  },
  "MiscTweaksRightClickMenu": {
    "InvokeScript": [
      "New-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Name \"InprocServer32\" -force -value \"\" "
    ]
  },
  "EssTweaksDiskCleanup": {
    "InvokeScript": [
      "cleanmgr.exe /d C: /VERYLOWDISK"
    ]
  },
  "MiscTweaksDisableTPMCheck": {
    "InvokeScript": [
      "If (!(Test-Path \"HKLM:\\SYSTEM\\Setup\\MoSetup\")) {
        New-Item -Path \"HKLM:\\SYSTEM\\Setup\\MoSetup\" -Force | Out-Null
    }
    Set-ItemProperty -Path \"HKLM:\\SYSTEM\\Setup\\MoSetup\" -Name \"AllowUpgradesWithUnsupportedTPM\" -Type DWord -Value 1"
    ]
  },
  "MiscTweaksDisableUAC": {
    "InvokeScript": [
      "# This below is the pussy mode which can break some apps. Please. Leave this on 1.
    # below i will show a way to do it without breaking some Apps that check UAC. U need to be admin tho.
    # Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" -Name \"EnableLUA\" -Type DWord -Value 0
    Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System -Name ConsentPromptBehaviorAdmin -Type DWord -Value 0 # Default is 5
    # This will set the GPO Entry in Security so that Admin users elevate without any prompt while normal users still elevate and u can even leave it ennabled.
    # It will just not bother u anymore"
    ]
  },
  "MiscTweaksDisableMouseAcceleration":  {
    "registry":  [
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "1",
          "name":  "MouseSpeed",
          "value":  "0",
          "type":  "String"
      },
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "6",
          "name":  "MouseThreshold1",
          "value":  "0",
          "type":  "String"
      },
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "10",
          "name":  "MouseThreshold2",
          "value":  "0",
          "type":  "String"
      }
    ]
  },
  "MiscTweaksEnableMouseAcceleration":  {
    "registry":  [
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "1",
          "name":  "MouseSpeed",
          "value":  "1",
          "type":  "String"
      },
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "6",
          "name":  "MouseThreshold1",
          "value":  "6",
          "type":  "String"
      },
      {
          "path":  "HKCU:\\Control Panel\\Mouse",
          "OriginalValue":  "10",
          "name":  "MouseThreshold2",
          "value":  "10",
          "type":  "String"
      }
    ]
  },
  "EssTweaksDeleteTempFiles": {
    "InvokeScript": [
      "Get-ChildItem -Path \"C:\\Windows\\Temp\" *.* -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse"
    ]
  },
  "EssTweaksRemoveCortana": {
    "InvokeScript": [
      "Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage"
    ]
  }
}
' | convertfrom-json
$applications = '{
  "Install": {
    "WPFInstalladobe": {
      "winget": "Adobe.Acrobat.Reader.64-bit"
    },
    "WPFInstalladvancedip": {
      "winget": "Famatech.AdvancedIPScanner"
    },
    "WPFInstallanydesk": {
      "winget": "AnyDeskSoftwareGmbH.AnyDesk"
    },
    "WPFInstallatom": {
      "winget": "GitHub.Atom"
    },
    "WPFInstallaudacity": {
      "winget": "Audacity.Audacity"
    },
    "WPFInstallautohotkey": {
      "winget": "Lexikos.AutoHotkey"
    },
    "WPFInstallbitwarden": {
      "winget": "Bitwarden.Bitwarden"
    },
    "WPFInstallblender": {
      "winget": "BlenderFoundation.Blender"
    },
    "WPFInstallbrave": {
      "winget": "Brave.Brave"
    },
    "WPFInstallchrome": {
      "winget": "Google.Chrome"
    },
    "WPFInstallchromium": {
      "winget": "eloston.ungoogled-chromium"
    },
    "WPFInstallcpuz": {
      "winget": "CPUID.CPU-Z"
    },
    "WPFInstalldiscord": {
      "winget": "Discord.Discord"
    },
    "WPFInstalleartrumpet": {
      "winget": "File-New-Project.EarTrumpet"
    },
    "WPFInstallepicgames": {
      "winget": "EpicGames.EpicGamesLauncher"
    },
    "WPFInstallesearch": {
      "winget": "voidtools.Everything"
    },
    "WPFInstalletcher": {
      "winget": "Balena.Etcher"
    },
    "WPFInstallfirefox": {
      "winget": "Mozilla.Firefox"
    },
    "WPFInstallflameshot": {
      "winget": "Flameshot.Flameshot"
    },
    "WPFInstallfoobar": {
      "winget": "PeterPawlowski.foobar2000"
    },
    "WPFInstallgimp": {
      "winget": "GIMP.GIMP"
    },
    "WPFInstallgithubdesktop": {
      "winget": "Git.Git;GitHub.GitHubDesktop"
    },
    "WPFInstallgog": {
      "winget": "GOG.Galaxy"
    },
    "WPFInstallgpuz": {
      "winget": "TechPowerUp.GPU-Z"
    },
    "WPFInstallgreenshot": {
      "winget": "Greenshot.Greenshot"
    },
    "WPFInstallhandbrake": {
      "winget": "HandBrake.HandBrake"
    },
    "WPFInstallhexchat": {
      "winget": "HexChat.HexChat"
    },
    "WPFInstallhwinfo": {
      "winget": "REALiX.HWiNFO"
    },
    "WPFInstallimageglass": {
      "winget": "DuongDieuPhap.ImageGlass"
    },
    "WPFInstallinkscape": {
      "winget": "Inkscape.Inkscape"
    },
    "WPFInstalljava16": {
      "winget": "AdoptOpenJDK.OpenJDK.16"
    },
    "WPFInstalljava18": {
      "winget": "EclipseAdoptium.Temurin.18.JRE"
    },
    "WPFInstalljava8": {
      "winget": "EclipseAdoptium.Temurin.8.JRE"
    },
    "WPFInstalljava19": {
      "winget": "EclipseAdoptium.Temurin.19.JRE"
    },
    "WPFInstalljava17": {
      "winget": "EclipseAdoptium.Temurin.17.JRE"
    },
    "WPFInstalljava11": {
      "winget": "EclipseAdoptium.Temurin.11.JRE"
    },
    "WPFInstalljetbrains": {
      "winget": "JetBrains.Toolbox"
    },
    "WPFInstallkeepass": {
      "winget": "KeePassXCTeam.KeePassXC"
    },
    "WPFInstalllibrewolf": {
      "winget": "LibreWolf.LibreWolf"
    },
    "WPFInstallmalwarebytes": {
      "winget": "Malwarebytes.Malwarebytes"
    },
    "WPFInstallmatrix": {
      "winget": "Element.Element"
    },
    "WPFInstallmpc": {
      "winget": "clsid2.mpc-hc"
    },
    "WPFInstallmremoteng": {
      "winget": "mRemoteNG.mRemoteNG"
    },
    "WPFInstallnodejs": {
      "winget": "OpenJS.NodeJS"
    },
    "WPFInstallnodejslts": {
      "winget": "OpenJS.NodeJS.LTS"
    },
    "WPFInstallnotepadplus": {
      "winget": "Notepad++.Notepad++"
    },
    "WPFInstallnvclean": {
      "winget": "TechPowerUp.NVCleanstall"
    },
    "WPFInstallobs": {
      "winget": "OBSProject.OBSStudio"
    },
    "WPFInstallobsidian": {
      "winget": "Obsidian.Obsidian"
    },
    "WPFInstallpowertoys": {
      "winget": "Microsoft.PowerToys"
    },
    "WPFInstallputty": {
      "winget": "PuTTY.PuTTY"
    },
    "WPFInstallpython3": {
      "winget": "Python.Python.3"
    },
    "WPFInstallrevo": {
      "winget": "RevoUnWPFInstaller.RevoUnWPFInstaller"
    },
    "WPFInstallrufus": {
      "winget": "Rufus.Rufus"
    },
    "WPFInstallsevenzip": {
      "winget": "7zip.7zip"
    },
    "WPFInstallsharex": {
      "winget": "ShareX.ShareX"
    },
    "WPFInstallsignal": {
      "winget": "OpenWhisperSystems.Signal"
    },
    "WPFInstallskype": {
      "winget": "Microsoft.Skype"
    },
    "WPFInstallslack": {
      "winget": "SlackTechnologies.Slack"
    },
    "WPFInstallsteam": {
      "winget": "Valve.Steam"
    },
    "WPFInstallsublime": {
      "winget": "SublimeHQ.SublimeText.4"
    },
    "WPFInstallsumatra": {
      "winget": "SumatraPDF.SumatraPDF"
    },
    "WPFInstallteams": {
      "winget": "Microsoft.Teams"
    },
    "WPFInstallteamviewer": {
      "winget": "TeamViewer.TeamViewer"
    },
    "WPFInstallterminal": {
      "winget": "Microsoft.WindowsTerminal"
    },
    "WPFInstalltreesize": {
      "winget": "JAMSoftware.TreeSize.Free"
    },
    "WPFInstallttaskbar": {
      "winget": "TranslucentTB.TranslucentTB"
    },
    "WPFInstallvisualstudio": {
      "winget": "Microsoft.VisualStudio.2022.Community"
    },
    "WPFInstallvivaldi": {
      "winget": "VivaldiTechnologies.Vivaldi"
    },
    "WPFInstallvlc": {
      "winget": "VideoLAN.VLC"
    },
    "WPFInstallvoicemeeter": {
      "winget": "VB-Audio.Voicemeeter"
    },
    "WPFInstallvscode": {
      "winget": "Git.Git;Microsoft.VisualStudioCode"
    },
    "WPFInstallvscodium": {
      "winget": "Git.Git;VSCodium.VSCodium"
    },
    "WPFInstallwindirstat": {
      "winget": "WinDirStat.WinDirStat"
    },
    "WPFInstallscp": {
      "winget": "WinSCP.WinSCP"
    },
    "WPFInstallwireshark": {
      "winget": "WiresharkFoundation.Wireshark"
    },
    "WPFInstallzoom": {
      "winget": "Zoom.Zoom"
    },
    "WPFInstalllibreoffice": {
      "winget": "TheDocumentFoundation.LibreOffice"
    },
    "WPFInstallshell": {
      "winget": "Nilesoft.Shell"
    },
    "WPFInstallklite": {
      "winget": "CodecGuide.K-LiteCodecPack.Standard"
    },
    "WPFInstallsandboxie": {
      "winget": "Sandboxie.Plus"
    },
    "WPFInstallprocesslasso": {
      "winget": "BitSum.ProcessLasso"
    },
    "WPFInstallwinmerge": {
      "winget": "WinMerge.WinMerge"
    },
    "WPFInstalldotnet3": {
      "winget": "Microsoft.DotNet.DesktopRuntime.3_1"
    },
    "WPFInstalldotnet5": {
      "winget": "Microsoft.DotNet.DesktopRuntime.5"
    },
    "WPFInstalldotnet6": {
      "winget": "Microsoft.DotNet.DesktopRuntime.6"
    },
    "WPFInstallvc2015_64": {
      "winget": "Microsoft.VC++2015-2022Redist-x64"
    },
    "WPFInstallvc2015_32": {
      "winget": "Microsoft.VC++2015-2022Redist-x86"
    },
    "WPFInstallfoxpdf": {
      "winget": "Foxit.PhantomPDF"
    },
    "WPFInstallonlyoffice": {
      "winget": "ONLYOFFICE.DesktopEditors"
    },
    "WPFInstallflux": {
      "winget": "flux.flux"
    },
    "WPFInstallitunes": {
      "winget": "Apple.iTunes"
    },
    "WPFInstallcider": {
      "winget": "CiderCollective.Cider"
    },
    "WPFInstalljoplin": {
      "winget": "Joplin.Joplin"
    },
    "WPFInstallopenoffice": {
      "winget": "Apache.OpenOffice"
    },
    "WPFInstallrustdesk": {
      "winget": "RustDesk.RustDesk"
    },
    "WPFInstalljami": {
      "winget": "SFLinux.Jami"
    },
    "WPFInstalljdownloader": {
      "winget": "AppWork.JDownloader"
    },
    "WPFInstallsimplewall": {
      "Winget": "Henry++.simplewall"
    },
    "WPFInstallrustlang": {
      "Winget": "Rustlang.Rust.MSVC"
    },
    "WPFInstallalacritty": {
      "Winget": "Alacritty.Alacritty"
    },
    "WPFInstallkdenlive": {
      "Winget": "KDE.Kdenlive"
    },
    "WPFInstallglaryutilities": {
      "Winget": "Glarysoft.GlaryUtilities"
    },
    "WPFInstalltwinkletray": {
      "Winget": "xanderfrangos.twinkletray"
    },
    "WPFInstallidm": {
      "Winget": "Tonec.InternetDownloadManager"
    },
    "WPFInstallviber": {
      "Winget": "Viber.Viber"
    },
    "WPFInstallgit": {
      "Winget": "Git.Git"
    },
    "WPFInstallwiztree": {
      "Winget": "AntibodySoftware.WizTree"
    },
    "WPFInstalltor": {
      "Winget": "TorProject.TorBrowser"
    },
    "WPFInstallkrita": {
      "winget": "KDE.Krita"
    },
    "WPFInstallnglide": {
      "winget": "ZeusSoftware.nGlide"
    },
    "WPFInstallkodi": {
      "winget": "XBMCFoundation.Kodi"
    },
    "WPFInstalltelegram": {
      "winget": "Telegram.TelegramDesktop"
    },
    "WPFInstallunity": {
      "winget": "UnityTechnologies.UnityHub"
    },
    "WPFInstallqbittorrent": {
      "winget": "qBittorrent.qBittorrent"
    },
    "WPFInstallorigin": {
      "winget": "ElectronicArts.EADesktop"
    },
    "WPFInstallopenshell": {
      "winget": "Open-Shell.Open-Shell-Menu"
    },
    "WPFInstallbluestacks": {
      "winget": "BlueStack.BlueStacks"
    },
    "WPFInstallstrawberry": {
      "winget": "StrawberryMusicPlayer.Strawberry"
    },
    "WPFInstallsqlstudio": {
      "winget": "Microsoft.SQLServerManagementStudio"
    },
    "WPFInstallwaterfox": {
      "winget": "Waterfox.Waterfox"
    },
    "WPFInstallpowershell": {
      "winget": "Microsoft.PowerShell"
    },
    "WPFInstallprocessmonitor": {
      "winget": "Microsoft.Sysinternals.ProcessMonitor"
    },
    "WPFInstallonedrive": {
      "winget": "Microsoft.OneDrive"
    },
    "WPFInstalledge": {
      "winget": "Microsoft.Edge"
    },
    "WPFInstallnuget": {
      "winget": "Microsoft.NuGet"
    }
  }
}
' | convertfrom-json
$feature = '{
  "Featuresdotnet": [
    "NetFx4-AdvSrvs",
    "NetFx3"
  ],
  "Featureshyperv": [
    "HypervisorPlatform",
    "Microsoft-Hyper-V-All",
    "Microsoft-Hyper-V",
    "Microsoft-Hyper-V-Tools-All",
    "Microsoft-Hyper-V-Management-PowerShell",
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Services",
    "Microsoft-Hyper-V-Management-Clients"
  ],
  "Featureslegacymedia": [
    "WindowsMediaPlayer",
    "MediaPlayback",
    "DirectPlay",
    "LegacyComponents"
  ],
  "Featurewsl": [
    "VirtualMachinePlatform",
    "Microsoft-Windows-Subsystem-Linux"
  ],
  "Featurenfs": [
    "ServicesForNFS-ClientOnly",
    "ClientForNFS-Infrastructure",
    "NFS-Administration"
  ]
}
' | convertfrom-json
<#
.NOTES
   Author      : Chris Titus @christitustech
   GitHub      : https://github.com/ChrisTitusTech
    Version 0.0.1
#>
# $inputXML = Get-Content "MainWindow.xaml" #uncomment for development
#$inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/MainWindow.xaml") #uncomment for Production

# Choco install 
$testchoco = powershell choco -v
if(-not($testchoco)){
    Write-Output "Seems Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
}
else{
    Write-Output "Chocolatey Version $testchoco is already installed"
}

#Load config files to hashtable
#$configs = @{}
#
#(
#    "applications", 
#    "tweaks",
#    "preset", 
#    "feature"
#) | ForEach-Object {
#    #$configs["$PSItem"] = Get-Content .\config\$PSItem.json | ConvertFrom-Json
#    $configs["$psitem"] = Invoke-RestMethod "https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/config/$psitem.json"
#}


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
 
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }

#===========================================================================
# Functions
#===========================================================================
 
Function Get-FormVariables {
    #If ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    

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

Function Get-CheckBoxes {

    <#
    
        .DESCRIPTION
        Function is meant to find all checkboxes that are checked on the specefic tab and input them into a script.

        Outputed data will be the names of the checkboxes that were checked        

        .EXAMPLE

        Get-CheckBoxes "WPFInstall"
    
    #>

    Param($Group)

    $CheckBoxes = get-variable | Where-Object {$psitem.name -like "$Group*" -and $psitem.value.GetType().name -eq "CheckBox"}
    $Output = New-Object System.Collections.Generic.List[System.Object]

    if($Group -eq "WPFInstall"){
        Foreach ($CheckBox in $CheckBoxes){
            if($checkbox.value.ischecked -eq $true){
                $output.Add("$($applications.install.$($checkbox.name).winget)")
                $checkbox.value.ischecked = $false
            }
        }
    }

    Write-Output $Output
}

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
        $WingetInstall = Get-CheckBoxes -Group "WPFInstall"

        # Check if winget is installed
        Write-Host "Checking if Winget is Installed..."
        if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
        }
        else {
            #Gets the computer's information
            $ComputerInfo = Get-ComputerInfo

            #Gets the Windows Edition
            $OSName = if ($ComputerInfo.OSName) {
                $ComputerInfo.OSName
            }else {
                $ComputerInfo.WindowsProductName
            }

            if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {
                
                Write-Host "Running Alternative Installer for LTSC/Server Editions"

                # Switching to winget-install from PSGallery from asheroto
                # Source: https://github.com/asheroto/winget-installer
                
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winget.ps1 | iex | Out-Host" -WindowStyle Normal
                
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
        #$wingetinstall.ToArray()
        # Define Output variable
        $wingetResult = New-Object System.Collections.Generic.List[System.Object]
        foreach ( $node in $wingetinstall ) {
            try {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget install -e --accept-source-agreements --accept-package-agreements --silent $node | Out-Host" -WindowStyle Normal
                $wingetResult.Add("$node`n")
                Start-Sleep -s 6
                Wait-Process winget -Timeout 90 -ErrorAction SilentlyContinue
            }
            catch [System.InvalidOperationException] {
                Write-Warning "Allow Yes on User Access Control to Install"
            }
            catch {
                Write-Error $_.Exception
            }
        }
        $wingetResult.ToArray()
        $wingetResult | ForEach-Object { $_ } | Out-Host
        
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
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget upgrade --all  | Out-Host" -Wait -WindowStyle Normal
            $isUpgradeSuccess = $true
        }
        catch [System.InvalidOperationException] {
            Write-Warning "Allow Yes on User Access Control to Upgrade"
        }
        catch {
            Write-Error $_.Exception
        }
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $Messageboxbody = if ($isUpgradeSuccess) { "Upgrade Done" } else { "Upgrade was not succesful" }
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $AppTitle, $ButtonType, $MessageIcon)
    })

#===========================================================================
# Tab 2 - Tweak Buttons
#===========================================================================
$WPFdesktop.Add_Click({

        $WPFEssTweaksAH.IsChecked = $true
        $WPFEssTweaksDeleteTempFiles.IsChecked = $true
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksRemoveCortana.IsChecked = $false
        $WPFEssTweaksRemoveEdge.IsChecked = $false
        $WPFEssTweaksDiskCleanup.IsChecked = $false
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
        $WPFMiscTweaksDisableUAC.IsChecked = $false
        $WPFMiscTweaksDisableNotifications.IsChecked = $false
        $WPFMiscTweaksRightClickMenu.IsChecked = $false
        $WPFMiscTweaksPower.IsChecked = $true
        $WPFMiscTweaksNum.IsChecked = $true
        $WPFMiscTweaksLapPower.IsChecked = $false
        $WPFMiscTweaksLapNum.IsChecked = $false
    })

$WPFlaptop.Add_Click({

        $WPFEssTweaksAH.IsChecked = $true
        $WPFEssTweaksDeleteTempFiles.IsChecked = $true
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksRemoveCortana.IsChecked = $false
        $WPFEssTweaksRemoveEdge.IsChecked = $false
        $WPFEssTweaksDiskCleanup.IsChecked = $false
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
        $WPFMiscTweaksDisableUAC.IsChecked = $false
        $WPFMiscTweaksDisableNotifications.IsChecked = $false
        $WPFMiscTweaksRightClickMenu.IsChecked = $false
        $WPFMiscTweaksLapPower.IsChecked = $true
        $WPFMiscTweaksLapNum.IsChecked = $true
        $WPFMiscTweaksPower.IsChecked = $false
        $WPFMiscTweaksNum.IsChecked = $false
    })

$WPFminimal.Add_Click({
    
        $WPFEssTweaksAH.IsChecked = $false
        $WPFEssTweaksDeleteTempFiles.IsChecked = $false
        $WPFEssTweaksDeBloat.IsChecked = $false
        $WPFEssTweaksRemoveCortana.IsChecked = $false
        $WPFEssTweaksRemoveEdge.IsChecked = $false
        $WPFEssTweaksDiskCleanup.IsChecked = $false
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
        $WPFMiscTweaksDisableUAC.IsChecked = $false
        $WPFMiscTweaksDisableNotifications.IsChecked = $false
        $WPFMiscTweaksRightClickMenu.IsChecked = $false
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

        If ( $WPFEssTweaksDeleteTempFiles.IsChecked -eq $true ) {
            Write-Host "Delete Temp Files"
            Get-ChildItem -Path "C:\Windows\Temp" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $WPFEssTweaksDeleteTempFiles.IsChecked = $false
            Write-Host "======================================="
            Write-Host "--- Cleaned following folders:"
            Write-Host "--- C:\Windows\Temp"
            Write-Host "--- "$env:TEMP
            Write-Host "======================================="
        }

        If ( $WPFEssTweaksDVR.IsChecked -eq $true ) {
            If (!(Test-Path "HKCU:\System\GameConfigStore")) {
                New-Item -Path "HKCU:\System\GameConfigStore" -Force
            }
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type DWord -Value 2
            If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0
            $WPFEssTweaksDVR.IsChecked = $false
        }

        If ( $WPFEssTweaksHiber.IsChecked -eq $true  ) {
            Write-Host "Disabling Hibernation..."
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Type Dword -Value 0
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
        If ( $WPFMiscTweaksDisableTPMCheck.IsChecked -eq $true ) {
            Write-Host "Disabling TPM Check..."
            If (!(Test-Path "HKLM:\SYSTEM\Setup\MoSetup")) {
                New-Item -Path "HKLM:\SYSTEM\Setup\MoSetup" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPM" -Type DWord -Value 1
            $WPFMiscTweaksDisableTPMCheck.IsChecked = $false
        }
        If ( $WPFEssTweaksDiskCleanup.IsChecked -eq $true ) {
            Write-Host "Running Disk Cleanup on Drive C:..."
            cmd /c cleanmgr.exe /d C: /VERYLOWDISK
            $WPFEssTweaksDiskCleanup.IsChecked = $false
        }
        If ( $WPFMiscTweaksDisableUAC.IsChecked -eq $true) {
            Write-Host "Disabling UAC..."
            # This below is the pussy mode which can break some apps. Please. Leave this on 1.
            # below i will show a way to do it without breaking some Apps that check UAC. U need to be admin tho.
            # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Type DWord -Value 0
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Type DWord -Value 0 # Default is 5
            # This will set the GPO Entry in Security so that Admin users elevate without any prompt while normal users still elevate and u can even leave it ennabled.
            # It will just not bother u anymore
            $WPFMiscTweaksDisableUAC.IsChecked = $false
        }
 
        If ( $WPFMiscTweaksDisableNotifications.IsChecked -eq $true ) {
            Write-Host "Disabling Notifications and Action Center..."
            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows" -Name "Explorer" -force
            New-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -PropertyType "DWord" -Value 1
            New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -PropertyType "DWord" -Value 0 -force
            $WPFMiscTweaksDisableNotifications.IsChecked = $false
        }
        
        If ( $WPFMiscTweaksRightClickMenu.IsChecked -eq $true ) {
            Write-Host "Setting Classic Right-Click Menu..."
            New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "InprocServer32" -force -value ""       
            $WPFMiscTweaksRightClickMenu.IsChecked = $false
        }
        If ( $WPFchangedns.text -eq 'Google' ) { 
            Write-Host "Setting DNS to Google for all connections..."
            $DC = "8.8.8.8"
            $Internet = "8.8.4.4"
            $dns = "$DC", "$Internet"
            $Interface = Get-WmiObject Win32_NetworkAdapterConfiguration 
            $Interface.SetDNSServerSearchOrder($dns)  | Out-Null
        }
        If ( $WPFchangedns.text -eq 'Cloud Flare' ) { 
            Write-Host "Setting DNS to Cloud Flare for all connections..."
            $DC = "1.1.1.1"
            $Internet = "1.0.0.1"
            $dns = "$DC", "$Internet"
            $Interface = Get-WmiObject Win32_NetworkAdapterConfiguration 
            $Interface.SetDNSServerSearchOrder($dns)  | Out-Null
        }
        If ( $WPFchangedns.text -eq 'Level3' ) { 
            Write-Host "Setting DNS to Level3 for all connections..."
            $DC = "4.2.2.2"
            $Internet = "4.2.2.1"
            $dns = "$DC", "$Internet"
            $Interface = Get-WmiObject Win32_NetworkAdapterConfiguration 
            $Interface.SetDNSServerSearchOrder($dns)  | Out-Null
        }
        If ( $WPFchangedns.text -eq 'Open DNS' ) { 
            Write-Host "Setting DNS to Open DNS for all connections..."
            $DC = "208.67.222.222"
            $Internet = "208.67.220.220"
            $dns = "$DC", "$Internet"
            $Interface = Get-WmiObject Win32_NetworkAdapterConfiguration 
            $Interface.SetDNSServerSearchOrder($dns)  | Out-Null
        }
        If ( $WPFEssTweaksOO.IsChecked -eq $true ) {
            If (!(Test-Path .\ooshutup10.cfg)) {
                Write-Host "Running O&O Shutup with Recommended Settings"
                curl.exe -s "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -o ooshutup10.cfg
                curl.exe -s "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -o OOSU10.exe
            }
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
                #"iphlpsvc"                                     # ipv6(Most websites use ipv4 instead) - Needed for Xbox Live
                "lfsvc"                                        # Geolocation Service
                #"LicenseManager"                              # Disable LicenseManager (Windows Store may not work properly)
                "lmhosts"                                      # TCP/IP NetBIOS Helper
                "MapsBroker"                                   # Downloaded Maps Manager
                "MicrosoftEdgeElevationService"                # Another Edge Update Service
                "MSDTC"                                        # Distributed Transaction Coordinator
                "NahimicService"                               # Nahimic Service
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
                Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Manual -ErrorAction SilentlyContinue
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
    
            ## Enable Long Paths
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type DWORD -Value 1

            Write-Host "Hiding 3D Objects icon from This PC..."
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue  
        
            ## Performance Tweaks and More Telemetry
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Type DWord -Value 400
            
            ## Timeout Tweaks cause flickering on Windows now
            Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillServiceTimeout" -ErrorAction SilentlyContinue

            # Network Tweaks
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 20
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type DWord -Value 4294967295

            # Gaming Tweaks
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Type DWord -Value 8
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Type DWord -Value 6
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type String -Value "High"
        
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
            Write-Host "Doing Security checks for Administrator Account and Group Policy"
            if (($(Get-WMIObject -class Win32_ComputerSystem | Select-Object username).username).IndexOf('Administrator') -eq -1) {
                net user administrator /active:no
            }
        
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
            $WPFMiscTweaksUTC.IsChecked = $false
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
            $WPFMiscTweaksDisplay.IsChecked = $false
        }
        If ( $WPFMiscTweaksDisableMouseAcceleration.IsChecked -eq $true ) {
            Write-Host "Disabling mouse acceleration..."
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value 0
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value 0
            $WPFMiscTweaksDisableMouseAcceleration.IsChecked = $false
        }
        If ( $WPFMiscTweaksEnableMouseAcceleration.IsChecked -eq $true ) {
            Write-Host "Enabling mouse acceleration..."
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value 6
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value 10
            $WPFMiscTweaksEnableMouseAcceleration.IsChecked = $false
        }
        If ( $WPFEssTweaksRemoveCortana.IsChecked -eq $true ) {
            Write-Host "Removing Cortana..."
            Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage
            $WPFEssTweaksRemoveCortana.IsChecked = $false
        }
        If ( $WPFEssTweaksRemoveEdge.IsChecked -eq $true ) {
            Write-Host "Removing Microsoft Edge..."
            Invoke-WebRequest -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/Edge_Removal.bat | Invoke-Expression
            $WPFEssTweaksRemoveEdge.IsChecked = $false
        }
        If ( $WPFEssTweaksDeBloat.IsChecked -eq $true ) {
            $Bloatware = @(
                #Unnecessary Windows 10 AppX Apps
                "3DBuilder"
                "Microsoft3DViewer"
                "AppConnector"
                "BingFinance"
                "BingNews"
                "BingSports"
                "BingTranslator"
                "BingWeather"
                "BingFoodAndDrink"
                "BingHealthAndFitness"
                "BingTravel"
                "MinecraftUWP"
                "GamingServices"
                # "WindowsReadingList"
                "GetHelp"
                "Getstarted"
                "Messaging"
                "Microsoft3DViewer"
                "MicrosoftSolitaireCollection"
                "NetworkSpeedTest"
                "News"
                "Lens"
                "Sway"
                "OneNote"
                "OneConnect"
                "People"
                "Print3D"
                "SkypeApp"
                "Todos"
                "Wallet"
                "Whiteboard"
                "WindowsAlarms"
                "windowscommunicationsapps"
                "WindowsFeedbackHub"
                "WindowsMaps"
                "WindowsPhone"
                "WindowsSoundRecorder"
                "XboxApp"
                "ConnectivityStore"
                "CommsPhone"
                "ScreenSketch"
                "TCUI"
                "XboxGameOverlay"
                "XboxGameCallableUI"
                "XboxSpeechToTextOverlay"
                "MixedReality.Portal"
                "ZuneMusic"
                "ZuneVideo"
                #"YourPhone"
                "Getstarted"
                "MicrosoftOfficeHub"

                #Sponsored Windows 10 AppX Apps
                #Add sponsored/featured apps to remove in the "*AppName*" format
                "EclipseManager"
                "ActiproSoftwareLLC"
                "AdobeSystemsIncorporated.AdobePhotoshopExpress"
                "Duolingo-LearnLanguagesforFree"
                "PandoraMediaInc"
                "CandyCrush"
                "BubbleWitch3Saga"
                "Wunderlist"
                "Flipboard"
                "Twitter"
                "Facebook"
                "Royal Revolt"
                "Sway"
                "Speed Test"
                "Dolby"
                "Viber"
                "ACGMediaPlayer"
                "Netflix"
                "OneCalendar"
                "LinkedInforWindows"
                "HiddenCityMysteryofShadows"
                "Hulu"
                "HiddenCity"
                "AdobePhotoshopExpress"
                "HotspotShieldFreeVPN"

                #Optional: Typically not removed but you can if you need to
                "Advertising"
                #"MSPaint"
                #"MicrosoftStickyNotes"
                #"Windows.Photos"
                #"WindowsCalculator"
                #"WindowsStore"

                # HPBloatware Packages
                "HPJumpStarts"
                "HPPCHardwareDiagnosticsWindows"
                "HPPowerManager"
                "HPPrivacySettings"
                "HPSupportAssistant"
                "HPSureShieldAI"
                "HPSystemInformation"
                "HPQuickDrop"
                "HPWorkWell"
                "myHP"
                "HPDesktopSupportUtilities"
                "HPQuickTouch"
                "HPEasyClean"
                "HPSystemInformation"
            )

            ## Teams Removal - Source: https://github.com/asheroto/UninstallTeams
            function getUninstallString($match) {
                return (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$match*" }).UninstallString
            }
            
            $TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
            $TeamsUpdateExePath = [System.IO.Path]::Combine($TeamsPath, 'Update.exe')
            
            Write-Output "Stopping Teams process..."
            Stop-Process -Name "*teams*" -Force -ErrorAction SilentlyContinue
        
            Write-Output "Uninstalling Teams from AppData\Microsoft\Teams"
            if ([System.IO.File]::Exists($TeamsUpdateExePath)) {
                # Uninstall app
                $proc = Start-Process $TeamsUpdateExePath "-uninstall -s" -PassThru
                $proc.WaitForExit()
            }
        
            Write-Output "Removing Teams AppxPackage..."
            Get-AppxPackage "*Teams*" | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage "*Teams*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        
            Write-Output "Deleting Teams directory"
            if ([System.IO.Directory]::Exists($TeamsPath)) {
                Remove-Item $TeamsPath -Force -Recurse -ErrorAction SilentlyContinue
            }
        
            Write-Output "Deleting Teams uninstall registry key"
            # Uninstall from Uninstall registry key UninstallString
            $us = getUninstallString("Teams");
            if ($us.Length -gt 0) {
                $us = ($us.Replace("/I", "/uninstall ") + " /quiet").Replace("  ", " ")
                $FilePath = ($us.Substring(0, $us.IndexOf(".exe") + 4).Trim())
                $ProcessArgs = ($us.Substring($us.IndexOf(".exe") + 5).Trim().replace("  ", " "))
                $proc = Start-Process -FilePath $FilePath -Args $ProcessArgs -PassThru
                $proc.WaitForExit()
            }
            
            Write-Output "Restart computer to complete teams uninstall"
            
            Write-Host "Removing Bloatware"

            foreach ($Bloat in $Bloatware) {
                Get-AppxPackage "*$Bloat*" | Remove-AppxPackage -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$Bloat*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Write-Host "Trying to remove $Bloat."
            }

            Write-Host "Finished Removing Bloatware Apps"
            Write-Host "Removing Bloatware Programs"
            # Remove installed programs
            $InstalledPrograms = Get-Package | Where-Object { $UninstallPrograms -contains $_.Name }
            $InstalledPrograms | ForEach-Object {

                Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."

                Try {
                    $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction SilentlyContinue
                    Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
                }
                Catch {
                    Write-Warning -Message "Failed to uninstall: [$($_.Name)]"
                }
            }
            Write-Host "Finished Removing Bloatware Programs"
            $WPFEssTweaksDeBloat.IsChecked = $false
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
    
$WPFAddUltPerf.Add_Click({
        Write-Host "Adding Ultimate Performance Profile"
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "Profile added"
     }
)

$WPFRemoveUltPerf.Add_Click({
        Write-Host "Removing Ultimate Performance Profile"
        powercfg -delete e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "Profile Removed"
     }
)
    
$WPFEnableDarkMode.Add_Click({
        Write-Host "Enabling Dark Mode"
        $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty $Theme AppsUseLightTheme -Value 0
        Set-ItemProperty $Theme SystemUsesLightTheme -Value 0
        Write-Host "Enabled"
    }
)

$WPFDisableDarkMode.Add_Click({
        Write-Host "Disabling Dark Mode"
        $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty $Theme AppsUseLightTheme -Value 1
        Set-ItemProperty $Theme SystemUsesLightTheme -Value 1
        Write-Host "Disabled"
    }
)
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
        Write-Host "Enabling Notifications and Action Center"
        Remove-Item -Path HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Force
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"
        Write-Host "Restoring Default Right Click Menu Layout"
        Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Confirm:$false -Force

        Write-Host "Reset News and Interests"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 1
        # Remove "News and Interest" from taskbar
        Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 0
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
$WPFPanelAutologin.Add_Click({
        curl.exe -ss "https://live.sysinternals.com/Autologon.exe" -o autologin.exe # Official Microsoft recommendation https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
        cmd /c autologin.exe
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
Get-FormVariables
$Form.ShowDialog() | out-null

