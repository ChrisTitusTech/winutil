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
        Title="Chris Titus Tech's Windows Utility" Height="450" Width="800">
    <Viewbox>
        <Grid Background="#777777" ShowGridLines="False" Name="MainGrid">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*"/>
                <ColumnDefinition Width="7*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0">
                <Image Height="100" Width="170" Name="Icon" SnapsToDevicePixels="True" Source="https://github.com/ChrisTitusTech/win10script/raw/master/titus-toolbox.png" Margin="0,10,0,10"/>
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
                        </Grid.ColumnDefinitions>
                        <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="0" Margin="10">
                            <Label Content="Browsers" FontSize="16" Margin="5,0"/>
                            <CheckBox Name="brave" Content="Brave" Margin="5,0"/>
                            <CheckBox Name="chrome" Content="Google Chrome" Margin="5,0"/>
                            <CheckBox Name="firefox" Content="Firefox" Margin="5,0"/>
                            <Label Content="Document Tools" FontSize="16" Margin="5,0"/>
                            <CheckBox Name="adobe" Content="Adobe Reader DC" Margin="5,0"/>
                            <CheckBox Name="notepadplus" Content="Notepad++" Margin="5,0"/>
                            <CheckBox Name="sumatra" Content="Sumatra PDF" Margin="5,0"/>
                            <CheckBox Name="vscode" Content="VS Code" Margin="5,0"/>
                            <CheckBox Name="vscodium" Content="VS Codium" Margin="5,0"/>
                            <Label Content="Video and Image Tools" FontSize="16" Margin="5,0"/>
                            <CheckBox Name="gimp" Content="GIMP (Image Editor)" Margin="5,0"/>
                            <CheckBox Name="imageglass" Content="ImageGlass (Image Viewer)" Margin="5,0"/>
                            <CheckBox Name="mpc" Content="Media Player Classic (Video Player)" Margin="5,0"/>
                            <CheckBox Name="sharex" Content="ShareX (Screenshots)" Margin="5,0"/>
                            <CheckBox Name="vlc" Content="VLC (Video Player)" Margin="5,0,5,5"/>
                        </StackPanel>
                        <StackPanel Background="#777777" SnapsToDevicePixels="True" Grid.Column="1" Margin="10">
                            <Label Content="Utilities" FontSize="16" Margin="5,0"/>
                            <CheckBox Name="sevenzip" Content="7-Zip" Margin="5,0"/>
                            <CheckBox Name="advancedip" Content="Advanced IP Scanner" Margin="5,0"/>
                            <CheckBox Name="autohotkey" Content="AutoHotkey" Margin="5,0"/>
                            <CheckBox Name="discord" Content="Discord" Margin="5,0"/>
                            <CheckBox Name="etcher" Content="Etcher USB Creator" Margin="5,0"/>
                            <CheckBox Name="esearch" Content="Everything Search" Margin="5,0"/>
                            <CheckBox Name="githubdesktop" Content="GitHub Desktop" Margin="5,0"/>
                            <CheckBox Name="powertoys" Content="Microsoft Powertoys" Margin="5,0"/>
                            <CheckBox Name="putty" Content="Putty and WinSCP" Margin="5,0"/>
                            <CheckBox Name="ttaskbar" Content="Translucent Taskbar" Margin="5,0"/>
                            <CheckBox Name="terminal" Content="Windows Terminal" Margin="5,0"/>
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
                        <StackPanel Orientation="Horizontal" Grid.Row="0" HorizontalAlignment="Center" Grid.ColumnSpan="2">
                            <Button Name="desktop" Content="Desktop" Margin="5"/>
                            <Button Name="laptop" Content="Laptop" Margin="5"/>
                            <Button Name="minimal" Content="Minimal" Margin="5"/>
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
                            <CheckBox Name="EssTweaksDeBloat" Content="Remove MS Store Apps" Margin="5,0"/>
                            <Button Name="essentialtweaks" Background="AliceBlue" Content="Run Essential Tweaks" Margin="0"/>
                            
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
                            <CheckBox Name="MiscTweaks" Content="" Margin="5,0"/>
                            
                            <Button Name="misctweaks" Background="AliceBlue" Content="Run Misc. Tweaks" Margin="0"/><Button Name="undoall" Background="AliceBlue" Content="Undo All Tweaks" Margin="20"/>
                        </StackPanel>
                    </Grid>
                </TabItem>
                <TabItem Header="Config" Visibility="Collapsed" Name="Tab3">
                    <Grid Background="#333333">
                        <TextBlock HorizontalAlignment="Center" VerticalAlignment="Top" TextWrapping="Wrap" Text="Config" FontSize="14" FontWeight="Bold" Height="21" Foreground="#ffffff"/>
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

    If ( $WPFadobe.IsChecked -eq $true ) { 
        winget install -e --id Adobe.Acrobat.Reader.64-bit | Out-Host
        $WPFadobe.IsChecked = $false
    }
    If ( $WPFadvancedip.IsChecked -eq $true ) { 
        winget install -e Famatech.AdvancedIPScanner | Out-Host
        $WPFadvancedip.IsChecked = $false
    }
    If ( $WPFautohotkey.IsChecked -eq $true ) { 
        winget install -e Lexikos.AutoHotkey | Out-Host
        $WPFautohotkey.IsChecked = $false
    }  
    If ( $WPFbrave.IsChecked -eq $true ) { 
        winget install -e BraveSoftware.BraveBrowser | Out-Host
        $WPFbrave.IsChecked = $false
    }
    If ( $WPFchrome.IsChecked -eq $true ) { 
        winget install -e Google.Chrome | Out-Host
        $WPFchrome.IsChecked = $false
    }
    If ( $WPFdiscord.IsChecked -eq $true ) { 
        winget install -e Discord.Discord | Out-Host
        $WPFdiscord.IsChecked = $false
    }
    If ( $WPFesearch.IsChecked -eq $true ) { 
        winget install -e voidtools.Everything --source winget | Out-Host
        $WPFesearch.IsChecked = $false
    }
    If ( $WPFetcher.IsChecked -eq $true ) { 
        winget install -e Balena.Etcher | Out-Host
        $WPFetcher.IsChecked = $false
    }
    If ( $WPFfirefox.IsChecked -eq $true ) { 
        winget install -e Mozilla.Firefox | Out-Host
        $WPFfirefox.IsChecked = $false
    }
    If ( $WPFgimp.IsChecked -eq $true ) { 
        winget install -e GIMP.GIMP | Out-Host
        $WPFgimp.IsChecked = $false
    }
    If ( $WPFgithubdesktop.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e GitHub.GitHubDesktop | Out-Host
        $WPFgithubdesktop.IsChecked = $false
    }
    If ( $WPFimageglass.IsChecked -eq $true ) { 
        winget install -e DuongDieuPhap.ImageGlass | Out-Host
        $WPFimageglass.IsChecked = $false
    }
    If ( $WPFmpc.IsChecked -eq $true ) { 
        winget install -e clsid2.mpc-hc | Out-Host
        $WPFmpc.IsChecked = $false
    }
    If ( $WPFnotepadplus.IsChecked -eq $true ) { 
        winget install -e Notepad++.Notepad++ | Out-Host
        $WPFnotepadplus.IsChecked = $false
    }
    If ( $WPFpowertoys.IsChecked -eq $true ) { 
        winget install -e Microsoft.PowerToys | Out-Host
        $WPFpowertoys.IsChecked = $false
    }
    If ( $WPFputty.IsChecked -eq $true ) { 
        winget install -e PuTTY.PuTTY | Out-Host
        winget install -e WinSCP.WinSCP | Out-Host
        $WPFputty.IsChecked = $false
    }
    If ( $WPFsevenzip.IsChecked -eq $true ) { 
        winget install -e 7zip.7zip | Out-Host
        $WPFsevenzip.IsChecked = $false
    }
    If ( $WPFsharex.IsChecked -eq $true ) { 
        winget install -e ShareX.ShareX | Out-Host
        $WPFsharex.IsChecked = $false
    }
    If ( $WPFsumatra.IsChecked -eq $true ) { 
        winget install -e SumatraPDF.SumatraPDF | Out-Host
        $WPFsumatra.IsChecked = $false
    }
    If ( $WPFterminal.IsChecked -eq $true ) { 
        winget install -e Microsoft.WindowsTerminal | Out-Host
        $WPFterminal.IsChecked = $false
    }
    If ( $WPFttaskbar.IsChecked -eq $true ) { 
        winget install -e TranslucentTB.TranslucentTB | Out-Host
        $WPFttaskbar.IsChecked = $false
    }
    If ( $WPFvlc.IsChecked -eq $true ) { 
        winget install -e VideoLAN.VLC | Out-Host
        $WPFvlc.IsChecked = $false
    }
    If ( $WPFvscode.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e Microsoft.VisualStudioCode --source winget | Out-Host
        $WPFvscode.IsChecked = $false
    }
    If ( $WPFvscodium.IsChecked -eq $true ) { 
        winget install -e Git.Git | Out-Host
        winget install -e VSCodium.VSCodium | Out-Host
        $WPFvscodium.IsChecked = $false
    }
})

#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null