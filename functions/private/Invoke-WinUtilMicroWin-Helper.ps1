function Test-CompatibleImage() {
    <#
        .SYNOPSIS
            Checks the version of a Windows image and determines whether or not it is compatible with a specific feature depending on a desired version

        .PARAMETER Name
            imgVersion - The version of the Windows image
            desiredVersion - The version to compare the image version with
    #>

    param
    (
    [Parameter(Mandatory, position=0)]
    [string]$imgVersion,

    [Parameter(Mandatory, position=1)]
    [Version]$desiredVersion
    )

    try {
        $version = [Version]$imgVersion
        return $version -ge $desiredVersion
    } catch {
        return $False
    }
}

function Remove-Features() {
    <#
        .SYNOPSIS
            Removes certain features from ISO image

        .PARAMETER Name
            No Params

        .EXAMPLE
            Remove-Features
    #>
    try {
        $featlist = (Get-WindowsOptionalFeature -Path $scratchDir)

        $featlist = $featlist | Where-Object {
            $_.FeatureName -NotLike "*Defender*" -AND
            $_.FeatureName -NotLike "*Printing*" -AND
            $_.FeatureName -NotLike "*TelnetClient*" -AND
            $_.FeatureName -NotLike "*PowerShell*" -AND
            $_.FeatureName -NotLike "*NetFx*" -AND
            $_.FeatureName -NotLike "*Media*" -AND
            $_.FeatureName -NotLike "*NFS*" -AND
            $_.FeatureName -NotLike "*SearchEngine*" -AND
            $_.State -ne "Disabled"
        }

        foreach($feature in $featlist) {
            $status = "Removing feature $($feature.FeatureName)"
            Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$featlist.Count*100)
            Write-Debug "Removing feature $($feature.FeatureName)"
            Disable-WindowsOptionalFeature -Path "$scratchDir" -FeatureName $($feature.FeatureName) -Remove  -ErrorAction SilentlyContinue -NoRestart
        }
        Write-Progress -Activity "Removing features" -Status "Ready" -Completed
        Write-Host "You can re-enable the disabled features at any time, using either Windows Update or the SxS folder in <installation media>\Sources."
    } catch {
        Write-Host "Unable to get information about the features. MicroWin processing will continue, but features will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Remove-Packages {
    try {
        $pkglist = (Get-WindowsPackage -Path "$scratchDir").PackageName

        $pkglist = $pkglist | Where-Object {
                $_ -NotLike "*ApplicationModel*" -AND
                $_ -NotLike "*indows-Client-LanguagePack*" -AND
                $_ -NotLike "*LanguageFeatures-Basic*" -AND
                $_ -NotLike "*Package_for_ServicingStack*" -AND
                $_ -NotLike "*.NET*" -AND
                $_ -NotLike "*Store*" -AND
                $_ -NotLike "*VCLibs*" -AND
                $_ -NotLike "*AAD.BrokerPlugin",
                $_ -NotLike "*LockApp*" -AND
                $_ -NotLike "*Notepad*" -AND
                $_ -NotLike "*immersivecontrolpanel*" -AND
                $_ -NotLike "*ContentDeliveryManager*" -AND
                $_ -NotLike "*PinningConfirMationDialog*" -AND
                $_ -NotLike "*SecHealthUI*" -AND
                $_ -NotLike "*SecureAssessmentBrowser*" -AND
                $_ -NotLike "*PrintDialog*" -AND
                $_ -NotLike "*AssignedAccessLockApp*" -AND
                $_ -NotLike "*OOBENetworkConnectionFlow*" -AND
                $_ -NotLike "*Apprep.ChxApp*" -AND
                $_ -NotLike "*CBS*" -AND
                $_ -NotLike "*OOBENetworkCaptivePortal*" -AND
                $_ -NotLike "*PeopleExperienceHost*" -AND
                $_ -NotLike "*ParentalControls*" -AND
                $_ -NotLike "*Win32WebViewHost*" -AND
                $_ -NotLike "*InputApp*" -AND
                $_ -NotLike "*AccountsControl*" -AND
                $_ -NotLike "*AsyncTextService*" -AND
                $_ -NotLike "*CapturePicker*" -AND
                $_ -NotLike "*CredDialogHost*" -AND
                $_ -NotLike "*BioEnrollMent*" -AND
                $_ -NotLike "*ShellExperienceHost*" -AND
                $_ -NotLike "*DesktopAppInstaller*" -AND
                $_ -NotLike "*WebMediaExtensions*" -AND
                $_ -NotLike "*WMIC*" -AND
                $_ -NotLike "*UI.XaML*" -AND
                $_ -NotLike "*Ethernet*" -AND
                $_ -NotLike "*Wifi*"
            }

        $failedCount = 0

        foreach ($pkg in $pkglist) {
            try {
                $status = "Removing $pkg"
                Write-Progress -Activity "Removing Apps" -Status $status -PercentComplete ($counter++/$pkglist.Count*100)
                Remove-WindowsPackage -Path "$scratchDir" -PackageName $pkg -NoRestart -ErrorAction SilentlyContinue
            } catch {
                # This can happen if the package that is being removed is a permanent one, like FodMetadata
                Write-Host "Could not remove OS package $($pkg)"
                $failedCount += 1
                continue
            }
        }
        Write-Progress -Activity "Removing Apps" -Status "Ready" -Completed
        if ($failedCount -gt 0)
        {
            Write-Host "Some packages could not be removed. Do not worry: your image will still work fine. This can happen if the package is permanent or has been superseded by a newer one."
        }
    } catch {
        Write-Host "Unable to get information about the packages. MicroWin processing will continue, but packages will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Remove-ProvisionedPackages() {
    <#
        .SYNOPSIS
        Removes AppX packages from a Windows image during MicroWin processing

        .PARAMETER Name
        No Params

        .EXAMPLE
        Remove-ProvisionedPackages
    #>
    try
    {
        $appxProvisionedPackages = Get-AppxProvisionedPackage -Path "$($scratchDir)" | Where-Object {
                $_.PackageName -NotLike "*AppInstaller*" -AND
                $_.PackageName -NotLike "*Store*" -and
                $_.PackageName -NotLike "*dism*" -and
                $_.PackageName -NotLike "*Foundation*" -and
                $_.PackageName -NotLike "*FodMetadata*" -and
                $_.PackageName -NotLike "*LanguageFeatures*" -and
                $_.PackageName -NotLike "*Notepad*" -and
                $_.PackageName -NotLike "*Printing*" -and
                $_.PackageName -NotLike "*Foundation*" -and
                $_.PackageName -NotLike "*YourPhone*" -and
                $_.PackageName -NotLike "*Xbox*" -and
                $_.PackageName -NotLike "*WindowsTerminal*" -and
                $_.PackageName -NotLike "*Calculator*" -and
                $_.PackageName -NotLike "*Photos*" -and
                $_.PackageName -NotLike "*VCLibs*" -and
                $_.PackageName -NotLike "*Paint*" -and
                $_.PackageName -NotLike "*Gaming*" -and
                $_.PackageName -NotLike "*Extension*" -and
                $_.PackageName -NotLike "*SecHealthUI*" -and
                $_.PackageName -NotLike "*ScreenSketch*"
        }

        $counter = 0
        foreach ($appx in $appxProvisionedPackages) {
            $status = "Removing Provisioned $($appx.PackageName)"
            Write-Progress -Activity "Removing Provisioned Apps" -Status $status -PercentComplete ($counter++/$appxProvisionedPackages.Count*100)
            try {
                Remove-AppxProvisionedPackage -Path "$scratchDir" -PackageName $appx.PackageName -ErrorAction SilentlyContinue
            } catch {
                Write-Host "Application $($appx.PackageName) could not be removed"
                continue
            }
        }
        Write-Progress -Activity "Removing Provisioned Apps" -Status "Ready" -Completed
    }
    catch
    {
        # This can happen if getting AppX packages fails
        Write-Host "Unable to get information about the AppX packages. MicroWin processing will continue, but AppX packages will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Copy-ToUSB([string]$fileToCopy) {
    foreach ($volume in Get-Volume) {
        if ($volume -and $volume.FileSystemLabel -ieq "ventoy") {
            $destinationPath = "$($volume.DriveLetter):\"
            #Copy-Item -Path $fileToCopy -Destination $destinationPath -Force
            # Get the total size of the file
            $totalSize = (Get-Item "$fileToCopy").length

            Copy-Item -Path "$fileToCopy" -Destination "$destinationPath" -Verbose -Force -Recurse -Container -PassThru |
                ForEach-Object {
                    # Calculate the percentage completed
                    $completed = ($_.BytesTransferred / $totalSize) * 100

                    # Display the progress bar
                    Write-Progress -Activity "Copying File" -Status "Progress" -PercentComplete $completed -CurrentOperation ("{0:N2} MB / {1:N2} MB" -f ($_.BytesTransferred / 1MB), ($totalSize / 1MB))
                }

            Write-Host "File copied to Ventoy drive $($volume.DriveLetter)"
            return
        }
    }
    Write-Host "Ventoy USB Key is not inserted"
}

function Remove-FileOrDirectory([string]$pathToDelete, [string]$mask = "", [switch]$Directory = $false) {
    if(([string]::IsNullOrEmpty($pathToDelete))) { return }
    if (-not (Test-Path -Path "$($pathToDelete)")) { return }

    $yesNo = Get-LocalizedYesNo
    Write-Host "[INFO] In Your local takeown expects '$($yesNo[0])' as a Yes answer."

    $itemsToDelete = [System.Collections.ArrayList]::new()

    if ($mask -eq "") {
        Write-Debug "Adding $($pathToDelete) to array."
        [void]$itemsToDelete.Add($pathToDelete)
    } else {
        Write-Debug "Adding $($pathToDelete) to array and mask is $($mask)"
        if ($Directory) { $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse -Directory } else { $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse }
    }

    foreach($itemToDelete in $itemsToDelete) {
        $status = "Deleting $($itemToDelete)"
        Write-Progress -Activity "Removing Items" -Status $status -PercentComplete ($counter++/$itemsToDelete.Count*100)

        if (Test-Path -Path "$($itemToDelete)" -PathType Container) {
            $status = "Deleting directory: $($itemToDelete)"

            takeown /r /d $yesNo[0] /a /f "$($itemToDelete)"
            icacls "$($itemToDelete)" /q /c /t /reset
            icacls $itemToDelete /setowner "*S-1-5-32-544"
            icacls $itemToDelete /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
            Remove-Item -Force -Recurse "$($itemToDelete)"
        }
        elseif (Test-Path -Path "$($itemToDelete)" -PathType Leaf) {
            $status = "Deleting file: $($itemToDelete)"

            takeown /a /f "$($itemToDelete)"
            icacls "$($itemToDelete)" /q /c /t /reset
            icacls "$($itemToDelete)" /setowner "*S-1-5-32-544"
            icacls "$($itemToDelete)" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
            Remove-Item -Force "$($itemToDelete)"
        }
    }
    Write-Progress -Activity "Removing Items" -Status "Ready" -Completed
}

function New-Unattend {

    param (
        [Parameter(Mandatory, Position = 0)] [string]$userName,
        [Parameter(Position = 1)] [string]$userPassword
    )

    $unattend = @'
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <#REPLACEME#>
        <settings pass="auditUser">
            <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <RunSynchronous>
                    <RunSynchronousCommand wcm:action="add">
                        <Order>1</Order>
                        <CommandLine>CMD /C echo LAU GG&gt;C:\Windows\LogAuditUser.txt</CommandLine>
                        <Description>StartMenu</Description>
                    </RunSynchronousCommand>
                </RunSynchronous>
            </component>
        </settings>
        <settings pass="oobeSystem">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <UserAccounts>
                    <LocalAccounts>
                        <LocalAccount wcm:action="add">
                            <Name>USER-REPLACEME</Name>
                            <Group>Administrators</Group>
                            <Password>
                                <Value>PW-REPLACEME</Value>
                                <PlainText>true</PlainText>
                            </Password>
                        </LocalAccount>
                    </LocalAccounts>
                </UserAccounts>
                <AutoLogon>
                    <Username>USER-REPLACEME</Username>
                    <Enabled>true</Enabled>
                    <LogonCount>1</LogonCount>
                    <Password>
                        <Value>PW-REPLACEME</Value>
                        <PlainText>true</PlainText>
                    </Password>
                </AutoLogon>
                <OOBE>
                    <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                    <SkipUserOOBE>true</SkipUserOOBE>
                    <SkipMachineOOBE>true</SkipMachineOOBE>
                    <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                    <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                    <HideEULAPage>true</HideEULAPage>
                    <ProtectYourPC>3</ProtectYourPC>
                </OOBE>
                <FirstLogonCommands>
                    <SynchronousCommand wcm:action="add">
                        <Order>1</Order>
                        <CommandLine>reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoLogonCount /t REG_DWORD /d 0 /f</CommandLine>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>2</Order>
                        <CommandLine>cmd.exe /c echo 23&gt;c:\windows\csup.txt</CommandLine>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>3</Order>
                        <CommandLine>CMD /C echo GG&gt;C:\Windows\LogOobeSystem.txt</CommandLine>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>4</Order>
                        <CommandLine>powershell -ExecutionPolicy Bypass -File c:\windows\FirstStartup.ps1</CommandLine>
                    </SynchronousCommand>
                </FirstLogonCommands>
            </component>
        </settings>
    </unattend>
'@
    $specPass = @'
<settings pass="specialize">
        <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CEIPEnabled>0</CEIPEnabled>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ConfigureChatAutoInstall>false</ConfigureChatAutoInstall>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Runonce" /v "UninstallCopilot" /t REG_SZ /d "powershell.exe -NoProfile -Command \"Get-AppxPackage -Name 'Microsoft.Windows.Ai.Copilot.Provider' | Remove-AppxPackage;\"" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Path>reg.exe unload "HKU\DefaultUser"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>6</Order>
                    <Path>reg.exe delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>7</Order>
                    <Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>8</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Notepad" /v ShowStoreBanner /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>9</Order>
                    <Path>reg.exe unload "HKU\DefaultUser"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>10</Order>
                    <Path>cmd.exe /c "del "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk""</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>11</Order>
                    <Path>cmd.exe /c "del "C:\Windows\System32\OneDriveSetup.exe""</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>12</Order>
                    <Path>cmd.exe /c "del "C:\Windows\SysWOW64\OneDriveSetup.exe""</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>13</Order>
                    <Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>14</Order>
                    <Path>reg.exe delete "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>15</Order>
                    <Path>reg.exe unload "HKU\DefaultUser"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>16</Order>
                    <Path>reg.exe delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>17</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v ConfigureChatAutoInstall /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>18</Order>
                    <Path>powershell.exe -NoProfile -Command "$xml = [xml]::new(); $xml.Load('C:\Windows\Panther\unattend.xml'); $sb = [scriptblock]::Create( $xml.unattend.Extensions.ExtractScript ); Invoke-Command -ScriptBlock $sb -ArgumentList $xml;"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>19</Order>
                    <Path>powershell.exe -NoProfile -Command "Get-Content -LiteralPath 'C:\Windows\Temp\remove-packages.ps1' -Raw | Invoke-Expression;"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>20</Order>
                    <Path>powershell.exe -NoProfile -Command "Get-Content -LiteralPath 'C:\Windows\Temp\remove-caps.ps1' -Raw | Invoke-Expression;"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>21</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start" /v ConfigureStartPins /t REG_SZ /d "{ \"pinnedList\": [] }" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>22</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start" /v ConfigureStartPins_ProviderSet /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>23</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start" /v ConfigureStartPins_WinningProvider /t REG_SZ /d B5292708-1619-419B-9923-E5D9F3925E71 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>24</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" /v ConfigureStartPins /t REG_SZ /d "{ \"pinnedList\": [] }" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>25</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" /v ConfigureStartPins_LastWrite /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>26</Order>
                    <Path>net.exe accounts /maxpwage:UNLIMITED</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>27</Order>
                    <Path>reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>28</Order>
                    <Path>reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>29</Order>
                    <Path>reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>30</Order>
                    <Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>31</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>32</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>33</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OEMPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>34</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>35</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>36</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>37</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>38</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>39</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>40</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>41</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>42</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>43</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>44</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>45</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>46</Order>
                    <Path>reg.exe unload "HKU\DefaultUser"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>47</Order>
                    <Path>reg.exe add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>48</Order>
                    <Path>reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>49</Order>
                    <Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>50</Order>
                    <Path>reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Runonce" /v "ClassicContextMenu" /t REG_SZ /d "reg.exe add \"HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32\" /ve /f" /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>51</Order>
                    <Path>reg.exe unload "HKU\DefaultUser"</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
'@
    if ((Test-CompatibleImage $imgVersion $([System.Version]::new(10,0,22000,1))) -eq $false) {
    # Replace the placeholder text with an empty string to make it valid for Windows 10 Setup
    $unattend = $unattend.Replace("<#REPLACEME#>", "").Trim()
    } else {
    # Replace the placeholder text with the Specialize pass
    $unattend = $unattend.Replace("<#REPLACEME#>", $specPass).Trim()
    }
    # Replace default User and Password values with the provided parameters
    $unattend = $unattend.Replace("USER-REPLACEME", $userName).Trim()
    $unattend = $unattend.Replace("PW-REPLACEME", $userPassword).Trim()

    # Save unattended answer file with UTF-8 encoding
    $unattend | Out-File -FilePath "$env:temp\unattend.xml" -Force -Encoding utf8
}

function New-CheckInstall {

    # using here string to embedd firstrun
    $checkInstall = @'
    @echo off
    if exist "C:\windows\cpu.txt" (
        echo C:\windows\cpu.txt exists
    ) else (
        echo C:\windows\cpu.txt does not exist
    )
    if exist "C:\windows\SerialNumber.txt" (
        echo C:\windows\SerialNumber.txt exists
    ) else (
        echo C:\windows\SerialNumber.txt does not exist
    )
    if exist "C:\unattend.xml" (
        echo C:\unattend.xml exists
    ) else (
        echo C:\unattend.xml does not exist
    )
    if exist "C:\Windows\Setup\Scripts\SetupComplete.cmd" (
        echo C:\Windows\Setup\Scripts\SetupComplete.cmd exists
    ) else (
        echo C:\Windows\Setup\Scripts\SetupComplete.cmd does not exist
    )
    if exist "C:\Windows\Panther\unattend.xml" (
        echo C:\Windows\Panther\unattend.xml exists
    ) else (
        echo C:\Windows\Panther\unattend.xml does not exist
    )
    if exist "C:\Windows\System32\Sysprep\unattend.xml" (
        echo C:\Windows\System32\Sysprep\unattend.xml exists
    ) else (
        echo C:\Windows\System32\Sysprep\unattend.xml does not exist
    )
    if exist "C:\Windows\FirstStartup.ps1" (
        echo C:\Windows\FirstStartup.ps1 exists
    ) else (
        echo C:\Windows\FirstStartup.ps1 does not exist
    )
    if exist "C:\Windows\winutil.ps1" (
        echo C:\Windows\winutil.ps1 exists
    ) else (
        echo C:\Windows\winutil.ps1 does not exist
    )
    if exist "C:\Windows\LogSpecialize.txt" (
        echo C:\Windows\LogSpecialize.txt exists
    ) else (
        echo C:\Windows\LogSpecialize.txt does not exist
    )
    if exist "C:\Windows\LogAuditUser.txt" (
        echo C:\Windows\LogAuditUser.txt exists
    ) else (
        echo C:\Windows\LogAuditUser.txt does not exist
    )
    if exist "C:\Windows\LogOobeSystem.txt" (
        echo C:\Windows\LogOobeSystem.txt exists
    ) else (
        echo C:\Windows\LogOobeSystem.txt does not exist
    )
    if exist "c:\windows\csup.txt" (
        echo c:\windows\csup.txt exists
    ) else (
        echo c:\windows\csup.txt does not exist
    )
    if exist "c:\windows\LogFirstRun.txt" (
        echo c:\windows\LogFirstRun.txt exists
    ) else (
        echo c:\windows\LogFirstRun.txt does not exist
    )
'@
    $checkInstall | Out-File -FilePath "$env:temp\checkinstall.cmd" -Force -Encoding Ascii
}

function New-FirstRun {

    # using here string to embedd firstrun
    $firstRun = @'
    # Set the global error action preference to continue
    $ErrorActionPreference = "Continue"
    function Remove-RegistryValue {
        param (
            [Parameter(Mandatory = $true)]
            [string]$RegistryPath,

            [Parameter(Mandatory = $true)]
            [string]$ValueName
        )

        # Check if the registry path exists
        if (Test-Path -Path $RegistryPath) {
            $registryValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue

            # Check if the registry value exists
            if ($registryValue) {
                # Remove the registry value
                Remove-ItemProperty -Path $RegistryPath -Name $ValueName -Force
                Write-Host "Registry value '$ValueName' removed from '$RegistryPath'."
            } else {
                Write-Host "Registry value '$ValueName' not found in '$RegistryPath'."
            }
        } else {
            Write-Host "Registry path '$RegistryPath' not found."
        }
    }

    "FirstStartup has worked" | Out-File -FilePath c:\windows\LogFirstRun.txt -Append -NoClobber

    $taskbarPath = "$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    # Delete all files on the Taskbar
    Get-ChildItem -Path $taskbarPath -File | Remove-Item -Force
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesRemovedChanges"
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesChanges"
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "Favorites"

    # Delete Edge Icon from the desktop
    $edgeShortcutFiles = Get-ChildItem -Path $desktopPath -Filter "*Edge*.lnk"
    # Check if Edge shortcuts exist on the desktop
    if ($edgeShortcutFiles) {
        foreach ($shortcutFile in $edgeShortcutFiles) {
            # Remove each Edge shortcut
            Remove-Item -Path $shortcutFile.FullName -Force
            Write-Host "Edge shortcut '$($shortcutFile.Name)' removed from the desktop."
        }
    }
    Remove-Item -Path "$env:USERPROFILE\Desktop\*.lnk"
    Remove-Item -Path "C:\Users\Default\Desktop\*.lnk"

    # ************************************************
    # Create WinUtil shortcut on the desktop
    #
    $desktopPath = "$($env:USERPROFILE)\Desktop"
    # Specify the target PowerShell command
    $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://christitus.com/win | iex'"
    # Specify the path for the shortcut
    $shortcutPath = Join-Path $desktopPath 'winutil.lnk'
    # Create a shell object
    $shell = New-Object -ComObject WScript.Shell

    # Create a shortcut object
    $shortcut = $shell.CreateShortcut($shortcutPath)

    if (Test-Path -Path "c:\Windows\cttlogo.png") {
        $shortcut.IconLocation = "c:\Windows\cttlogo.png"
    }

    # Set properties of the shortcut
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
    # Save the shortcut
    $shortcut.Save()

    # Make the shortcut have 'Run as administrator' property on
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    # Set byte value at position 0x15 in hex, or 21 in decimal, from the value 0x00 to 0x20 in hex
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)

    Write-Host "Shortcut created at: $shortcutPath"
    #
    # Done create WinUtil shortcut on the desktop
    # ************************************************

    Start-Process explorer

'@
    $firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force
}
