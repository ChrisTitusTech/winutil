function Start-WinUtilUserInterface {
    <#
        .SYNOPSIS
            Builds the WinUtil window, wires its event handlers and runs it to completion

        .DESCRIPTION
            This is the whole interface. It runs on the dedicated STA interface runspace that
            main.ps1 starts, so the thread that owns the window does nothing but paint and
            dispatch: every long operation goes to the worker pool through Start-WinUtilJob.

            The call blocks until the window is closed, and the interface runspace is the only
            place that is allowed to touch controls directly.
    #>

    $buildClock = [System.Diagnostics.Stopwatch]::StartNew()

    Measure-WinUtilStep -Scope "UI" -Name "load WPF assemblies" -ScriptBlock {
        [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    }

    [xml]$XAML = $inputXML

    # Read the XAML file
    $readerOperationSuccessful = $false # There's more cases of failure then success.
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        Measure-WinUtilStep -Scope "UI" -Name "parse XAML" -ScriptBlock {
            $sync["Form"] = [Windows.Markup.XamlReader]::Load( $reader )
        }
        $readerOperationSuccessful = $true
    } catch [System.Management.Automation.MethodInvocationException] {
        Write-Host "We ran into a problem with the XAML code.  Check the syntax for this control..." -ForegroundColor Red
        Write-Host $error[0].Exception.Message -ForegroundColor Red

        If ($error[0].Exception.Message -like "*button*") {
            write-Host "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n" -ForegroundColor Red
        }
    } catch {
        Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." -ForegroundColor Red
    }

    if (-NOT ($readerOperationSuccessful)) {
        Write-Host "Failed to parse xaml content using Windows.Markup.XamlReader's Load Method." -ForegroundColor Red
        Write-Host "Quitting WinUtil..." -ForegroundColor Red
        Write-WinUtilLog -Level "ERROR" -Component "UI" -Message "Failed to parse the XAML content. WinUtil cannot start."
        return
    }

    # Setup the Window to follow listen for windows Theme Change events and update the winutil theme
    # throttle logic needed, because windows seems to send more than one theme change event per change
    $themeState = @{ LastChange = [datetime]::MinValue }
    $debounceInterval = [timespan]::FromSeconds(2)
    $sync.Form.Add_Loaded({
        $interopHelper = New-Object System.Windows.Interop.WindowInteropHelper $sync.Form
        $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($interopHelper.Handle)
        $hwndSource.AddHook({
            param (
                [System.IntPtr]$hwnd,
                [int]$msg,
                [System.IntPtr]$wParam,
                [System.IntPtr]$lParam,
                [ref]$handled
            )
            $null = $hwnd, $wParam, $lParam
            # Check for the Event WM_SETTINGCHANGE (0x1001A) and validate that Button shows the icon for "Auto" => [char]0xF08C
            if (($msg -eq 0x001A) -and $sync.ThemeButton.Content -eq [char]0xF08C) {
                $currentTime = [datetime]::Now
                if ($currentTime - $themeState.LastChange -gt $debounceInterval) {
                    Invoke-WinutilThemeChange -theme "Auto"
                    $themeState.LastChange = $currentTime
                    $handled = $true
                }
            }
            return 0
        })
    })

    Measure-WinUtilStep -Scope "UI" -Name "apply theme" -ScriptBlock {
        Invoke-WinutilThemeChange -theme $sync.preferences.theme
    }

    # Build only the default tab before first paint; other tabs initialize on first activation.
    $sync.InitializedTabs = @{}
    Measure-WinUtilStep -Scope "UI" -Name "build Install tab" -ScriptBlock {
        Initialize-WinUtilTabContent -TabName "Install"
    }

    #===========================================================================
    # Store Form Objects In PowerShell
    #===========================================================================

    Measure-WinUtilStep -Scope "UI" -Name "map named controls" -ScriptBlock {
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}
    }

    # How background work reaches the controls. Built here so it carries this runspace's
    # session state: posted work then runs as ordinary interface code instead of as a
    # cross-runspace nested pipeline, which is orders of magnitude slower. Invoke-WPFUIThread
    # is the caller-facing side of this.
    $sync.UIDispatchDelegate = [System.Func[object, object]]{
        param($Work)

        $body = [scriptblock]::Create($Work.Body)
        $parameters = $Work.Parameters
        if ($parameters -and $parameters.Count -gt 0) {
            & $body @parameters
        } else {
            & $body
        }
    }

    $sync.ChocoRadioButton.Add_Checked({
        $sync.preferences.packagemanager = "Choco"
    })
    $sync.WingetRadioButton.Add_Checked({
        $sync.preferences.packagemanager = "Winget"
    })

    switch ($sync.preferences.packagemanager) {
        "Choco" {$sync.ChocoRadioButton.IsChecked = $true; break}
        "Winget" {$sync.WingetRadioButton.IsChecked = $true; break}
    }

    Measure-WinUtilStep -Scope "UI" -Name "wire static button clicks" -ScriptBlock {
        $sync.keys | ForEach-Object {
            if($sync.$psitem) {
                if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -in @("ToggleButton", "Button")) {
                    if ($sync.Buttons -notcontains $psitem) {
                        $sync["$psitem"].Add_Click({
                            [System.Object]$Sender = $args[0]
                            Invoke-WPFButton $Sender.name
                        })
                        $sync.Buttons.Add($psitem) | Out-Null
                    }
                }
            }
        }
    }

    #===========================================================================
    # Setup and Show the Form
    #===========================================================================

    # Progress bar in taskbaritem > Set-WinUtilProgressbar
    $sync["Form"].TaskbarItemInfo = New-Object System.Windows.Shell.TaskbarItemInfo
    Set-WinUtilTaskbaritem -state "None"

    # Set the titlebar
    $sync["Form"].title = $sync["Form"].title + " " + $sync.version
    # Set the commands that will run when the form is closed
    $sync["Form"].Add_Closing({
        Write-WinUtilLog -Component "UI" -Message "Window closing, shutting down the worker pool."
        Close-WinUtilRunspacePool
        [System.GC]::Collect()
    })

    # Attach the event handler to the Click event
    $sync.SearchBarClearButton.Add_Click({
        $sync.SearchBar.Text = ""
        $sync.SearchBarClearButton.Visibility = "Collapsed"

        # Focus the search bar after clearing the text
        $sync.SearchBar.Focus()
        $sync.SearchBar.SelectAll()
    })

    # add some shortcuts for people that don't like clicking
    function Invoke-WinUtilFontScaleStep([double]$Step) { $sync.FontScalingSlider.Value = [math]::Max(0.75, [math]::Min(2.0, $sync.FontScalingSlider.Value + $Step)); Invoke-WinUtilFontScaling -ScaleFactor $sync.FontScalingSlider.Value }

    $commonKeyEvents = {
        # Prevent shortcuts from executing if a job is already running
        if ($sync.ActiveJob) {
            return
        }

        # Handle key presses of single keys
        switch ($_.Key) {
            "Escape" { $sync.SearchBar.Text = "" }
        }
        # Handle Alt key combinations for navigation
        if ($_.KeyboardDevice.Modifiers -eq "Alt") {
            $keyEventArgs = $_
            switch ($_.SystemKey) {
                "I" { Invoke-WPFButton "WPFTab1BT"; $keyEventArgs.Handled = $true } # Navigate to Install tab and suppress Windows Warning Sound
                "T" { Invoke-WPFButton "WPFTab2BT"; $keyEventArgs.Handled = $true } # Navigate to Tweaks tab
                "C" { Invoke-WPFButton "WPFTab3BT"; $keyEventArgs.Handled = $true } # Navigate to Config tab
                "U" { Invoke-WPFButton "WPFTab4BT"; $keyEventArgs.Handled = $true } # Navigate to Updates tab
                "W" { Invoke-WPFButton "WPFTab5BT"; $keyEventArgs.Handled = $true } # Navigate to Win11ISO tab
            }
        }
        # Handle Ctrl key combinations for specific actions
        if ($_.KeyboardDevice.Modifiers -eq "Ctrl") {
            $keyEventArgs = $_
            switch ($_.Key) {
                "F" { $sync.SearchBar.Focus() } # Focus on the search bar
                "Q" { $this.Close() } # Close the application
            }
        }
        $ctrlShiftModifiers = [Windows.Input.ModifierKeys]::Control -bor [Windows.Input.ModifierKeys]::Shift
        if ($_.KeyboardDevice.Modifiers -eq "Ctrl" -or $_.KeyboardDevice.Modifiers -eq $ctrlShiftModifiers) {
            $keyEventArgs = $_
            switch ($_.Key) {
                { $_ -in "OemPlus", "Add" } { Invoke-WinUtilFontScaleStep 0.05; $keyEventArgs.Handled = $true }
                { $_ -in "OemMinus", "Subtract" } { Invoke-WinUtilFontScaleStep -0.05; $keyEventArgs.Handled = $true }
            }
        }
    }
    $sync["Form"].Add_PreViewKeyDown($commonKeyEvents)
    $sync["Form"].Add_PreviewMouseWheel({
        if ([Windows.Input.Keyboard]::Modifiers -eq "Ctrl") { Invoke-WinUtilFontScaleStep $(if ($_.Delta -gt 0) { 0.05 } else { -0.05 }); $_.Handled = $true }
    })

    $sync["Form"].Add_MouseLeftButtonDown({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
        $sync["Form"].DragMove()
    })

    $sync["Form"].Add_MouseDoubleClick({
        if ($_.OriginalSource.Name -eq "NavDockPanel" -or
            $_.OriginalSource.Name -eq "GridBesideNavDockPanel") {
                if ($sync["Form"].WindowState -eq [Windows.WindowState]::Normal) {
                    [Windows.SystemCommands]::MaximizeWindow($sync.Form)
                }
                else{
                    [Windows.SystemCommands]::RestoreWindow($sync.Form)
                }
        }
    })

    $sync["Form"].Add_Deactivated({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
    })

    $sync["Form"].Add_ContentRendered({
        # Load the Windows Forms assembly
        Add-Type -AssemblyName System.Windows.Forms
        $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        # Check if the primary screen is found
        if ($primaryScreen) {
            # Extract screen width and height for the primary monitor
            $screenWidth = $primaryScreen.Bounds.Width
            $screenHeight = $primaryScreen.Bounds.Height
            $sync.Form.MinWidth = [Math]::Min([double]$sync.Form.MinWidth, [double]$screenWidth)

            # Compare with the primary monitor size
            if ($sync.Form.ActualWidth -gt $screenWidth -or $sync.Form.ActualHeight -gt $screenHeight) {
                $sync.Form.Left = 0
                $sync.Form.Top = 0
                $sync.Form.Width = $screenWidth
                $sync.Form.Height = $screenHeight
            }
        }

        if ($PARAM_OFFLINE) {
            # Show offline banner
            $sync.WPFOfflineBanner.Visibility = [System.Windows.Visibility]::Visible

            # Disable the install tab
            $sync.WPFTab1BT.IsEnabled = $false
            $sync.WPFTab1BT.Opacity = 0.5
            $sync.WPFTab1BT.ToolTip = "Internet connection required for installing applications."

            # Disable install-related buttons
            $sync.WPFInstall.IsEnabled = $false
            $sync.WPFUninstall.IsEnabled = $false
            $sync.WPFInstallUpgrade.IsEnabled = $false
            $sync.WPFGetInstalled.IsEnabled = $false

            # Show offline indicator
            Write-Host "Offline mode detected - Install tab disabled." -ForegroundColor Yellow

            # Optionally switch to a different tab if install tab was going to be default
            Invoke-WPFTab "WPFTab2BT"  # Switch to Tweaks tab instead
        }
        else {
            # Online - ensure install tab is enabled
            $sync.WPFTab1BT.IsEnabled = $true
            $sync.WPFTab1BT.Opacity = 1.0
            $sync.WPFTab1BT.ToolTip = $null
            Invoke-WPFTab "WPFTab1BT"  # Default to install tab
        }

        $sync["Form"].Focus()
        $sync["Form"].Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{ Initialize-WinUtilRunspacePool | Out-Null }) | Out-Null
        $sync["Form"].Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
            Set-WinUtilTaskbaritem -overlay "logo"
        }) | Out-Null
    })

    # The SearchBarTimer is used to delay the search operation until the user has stopped typing for a short period
    # This prevents the ui from stuttering when the user types quickly as it dosnt need to update the ui for every keystroke

    $searchBarTimer = New-Object System.Windows.Threading.DispatcherTimer
    $searchBarTimer.Interval = [TimeSpan]::FromMilliseconds(300)
    $searchBarTimer.IsEnabled = $false

    $searchBarTimer.add_Tick({
        $searchBarTimer.Stop()
        switch ($sync.currentTab) {
            "Install" {
                Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Category $sync.SearchBar.Tag
            }
            "Tweaks" {
                Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text
            }
            "AppX" {
                Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text
            }
        }
    })
    $sync["SearchBar"].Add_TextChanged({
        if ($sync.SearchBar.Tag -ne $sync.SearchBar.Text) {
            $sync.SearchBar.Tag = $null
        }

        if ($sync.SearchBar.Text -ne "") {
            $sync.SearchBarClearButton.Visibility = "Visible"
            $sync.SearchBarIcon.Visibility = "Collapsed"
        } else {
            $sync.SearchBarClearButton.Visibility = "Collapsed"
            $sync.SearchBarIcon.Visibility = "Visible"
        }

        # Category chip handlers apply their filter immediately.
        if ($sync.SearchBar.Tag -eq $sync.SearchBar.Text) {
            return
        }

        if ($searchBarTimer.IsEnabled) {
            $searchBarTimer.Stop()
        }
        $searchBarTimer.Start()
    })

    # Quick Category Search Chips
    $sync["WPFSearchChipAll"].Add_Click({ Set-WinUtilAppCategoryFilter })
    $sync["WPFSearchChipBrowsers"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Browsers" })
    $sync["WPFSearchChipCommunications"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Communications" })
    $sync["WPFSearchChipDevelopment"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Development" })
    $sync["WPFSearchChipDocument"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Document" })
    $sync["WPFSearchChipGames"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Games" })
    $sync["WPFSearchChipMicrosoftTools"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Microsoft Tools" })
    $sync["WPFSearchChipMultimediaTools"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Multimedia Tools" })
    $sync["WPFSearchChipProTools"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Pro Tools" })
    $sync["WPFSearchChipSelfhostedTools"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Selfhosted Tools" })
    $sync["WPFSearchChipUtilities"].Add_Click({ Set-WinUtilAppCategoryFilter -Category "Utilities" })

    $sync["Form"].Add_Loaded({
        param($e)
        $null = $e
        $sync.Form.MinWidth = "1150"
        $sync["Form"].MaxWidth = [Double]::PositiveInfinity
        $sync["Form"].MaxHeight = [Double]::PositiveInfinity
    })

    Measure-WinUtilStep -Scope "UI" -Name "build nav logo" -ScriptBlock {
        $NavLogoPanel = $sync["Form"].FindName("NavLogoPanel")
        $NavLogoPanel.Children.Add((Invoke-WinUtilAssets -Type "logo" -Size 25)) | Out-Null
    }

    $sync["Form"].Add_Activated({
        Set-WinUtilTaskbaritem -overlay "logo"
    })

    $sync["ThemeButton"].Add_Click({
        Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Toggle"; "FontScaling" = "Hide" }
    })
    $sync["AutoThemeMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
        Invoke-WinutilThemeChange -theme "Auto"
    })
    $sync["DarkThemeMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
        Invoke-WinutilThemeChange -theme "Dark"
    })
    $sync["LightThemeMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
        Invoke-WinutilThemeChange -theme "Light"
    })

    $sync["SettingsButton"].Add_Click({
        Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Toggle"; "Theme" = "Hide"; "FontScaling" = "Hide" }
    })
    $sync["ImportMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
        Invoke-WPFImpex -type "import"
    })
    $sync["ExportMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
        Invoke-WPFImpex -type "export"
    })
    $sync["AboutMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

        $authorInfo = @"
Author   : <a href="https://github.com/ChrisTitusTech">@ChrisTitusTech</a>
UI       : <a href="https://github.com/MyDrift-user">@MyDrift-user</a>, <a href="https://github.com/Marterich">@Marterich</a>
Runspace : <a href="https://github.com/DeveloperDurp">@DeveloperDurp</a>, <a href="https://github.com/Marterich">@Marterich</a>
GitHub   : <a href="https://github.com/ChrisTitusTech/winutil">ChrisTitusTech/winutil</a>
Version  : <a href="https://github.com/ChrisTitusTech/winutil/releases/tag/$($sync.version)">$($sync.version)</a>
"@
        Show-CustomDialog -Title "About" -Message $authorInfo
    })
    $sync["DocumentationMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
        Start-Process "https://winutil.christitus.com/"
    })
    $sync["SponsorMenuItem"].Add_Click({
        Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

        $authorInfo = @"
<a href="https://github.com/sponsors/ChrisTitusTech">Current sponsors for ChrisTitusTech:</a>
"@
        $authorInfo += "`n"
        try {
            $sponsors = Invoke-WinUtilSponsors
            foreach ($sponsor in $sponsors) {
                $authorInfo += "<a href=`"https://github.com/sponsors/ChrisTitusTech`">$sponsor</a>`n"
            }
        } catch {
            $authorInfo += "An error occurred while fetching or processing the sponsors: $_`n"
        }
        Show-CustomDialog -Title "Sponsors" -Message $authorInfo -EnableScroll $true
    })

    # Font Scaling Event Handlers
    $sync["FontScalingButton"].Add_Click({
        Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Hide"; "FontScaling" = "Toggle" }
    })

    $sync["FontScalingSlider"].Add_ValueChanged({
        param($slider)
        $percentage = [math]::Round($slider.Value * 100)
        $sync.FontScalingValue.Text = "$percentage%"
    })

    $sync["FontScalingResetButton"].Add_Click({
        $sync.FontScalingSlider.Value = 1.0
        $sync.FontScalingValue.Text = "100%"
    })

    $sync["FontScalingApplyButton"].Add_Click({
        $scaleFactor = $sync.FontScalingSlider.Value
        Invoke-WinUtilFontScaling -ScaleFactor $scaleFactor
        Invoke-WPFPopup -Action "Hide" -Popups @("FontScaling")
    })

    # Win11ISO Tab button handlers
    $sync["WPFWin11ISOBrowseButton"].Add_Click({
        Invoke-WinUtilISOBrowse
    })

    $sync["WPFWin11ISODownloadLink"].Add_Click({
        Start-Process "https://www.microsoft.com/software-download/windows11"
    })

    $sync["WPFWin11ISOMountButton"].Add_Click({
        Invoke-WinUtilISOMountAndVerify
    })

    $sync["WPFWin11ISOModifyButton"].Add_Click({
        Invoke-WinUtilISOModify
    })

    $sync["WPFWin11ISOChooseISOButton"].Add_Click({
        $sync["WPFWin11ISOOptionUSB"].Visibility = "Collapsed"
        Invoke-WinUtilISOExport
    })

    $sync["WPFWin11ISOChooseUSBButton"].Add_Click({
        $sync["WPFWin11ISOOptionUSB"].Visibility = "Visible"
        Invoke-WinUtilISORefreshUSBDrives
    })

    $sync["WPFWin11ISORefreshUSBButton"].Add_Click({
        Invoke-WinUtilISORefreshUSBDrives
    })

    $sync["WPFWin11ISOWriteUSBButton"].Add_Click({
        Invoke-WinUtilISOWriteUSB
    })

    $sync["WPFWin11ISOCleanResetButton"].Add_Click({
        Invoke-WinUtilISOCleanAndReset
    })

    $buildClock.Stop()
    Write-WinUtilLog -Component "UI" -Message "Interface built in $($buildClock.ElapsedMilliseconds) ms, showing the window."
    Write-WinUtilTimingSummary -Scope "UI" -TotalMilliseconds $buildClock.ElapsedMilliseconds

    # Input priority runs behind everything already queued, so this fires at the first moment
    # the window could actually service a click
    $sync["Form"].Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Input, [action]{
        $sinceStart = [int]((Get-Date) - $sync.StartedAt).TotalMilliseconds
        Write-WinUtilLog -Component "UI" -Message "timing: interface ready for input $sinceStart ms after start."
    }) | Out-Null

    $sync["Form"].ShowDialog() | Out-Null

    # ShowDialog returns once the window is gone; stop the dispatcher so this runspace can close
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
}
