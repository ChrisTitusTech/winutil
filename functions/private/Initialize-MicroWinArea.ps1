function Initialize-MicroWinArea {
    <#
        .SYNOPSIS
            Enhanced visual styling for MicroWin section with improved typography, spacing, and modern visual elements.
            Applies consistent styling without changing functionality.

        .PARAMETER TargetElement
            The name of the target element (should be "MicrowinMain")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TargetElement = "MicrowinMain"
    )

    Write-Host "Applying enhanced styling to MicroWin section..." -ForegroundColor Green

    try {
        # Apply direct visual enhancements to MicroWin elements
        Enhance-MicroWinISOPanel
        Enhance-MicroWinOptionsPanel
        Enhance-MicroWinControls
        Write-Host "Successfully applied MicroWin enhancements!" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to apply MicroWin enhancements: $($_.Exception.Message)"
    }
}

function Enhance-MicroWinISOPanel {
    <#
        .SYNOPSIS
            Enhances the visual styling of the MicroWin ISO selection panel
    #>

    $isoPanel = $sync.Form.FindName("MicrowinISOPanel")
    if (-not $isoPanel) { return }

    # Find and enhance all TextBlocks (section headers and descriptions)
    $textBlocks = $isoPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
    foreach ($textBlock in $textBlocks) {
        if ($textBlock.Text -like "*Scratch directory settings*") {
            # Enhanced section header
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $textBlock.FontWeight = "SemiBold"
            $textBlock.Margin = "8,16,8,8"
        } elseif ($textBlock.Text -like "*Choose a Windows ISO*") {
            # Enhanced description text
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "ComboBoxForegroundColor")
            $textBlock.Margin = "8,8,8,12"
            $textBlock.FontStyle = "Normal"
        }
    }

    # Find and enhance all Rectangles (replace basic separators with styled ones)
    $rectangles = $isoPanel.Children | Where-Object { $_ -is [System.Windows.Shapes.Rectangle] }
    foreach ($rectangle in $rectangles) {
        if ($rectangle.Height -eq 2) {
            # Create modern separator border
            $separatorBorder = New-Object System.Windows.Controls.Border
            $separatorBorder.Height = 1
            $separatorBorder.HorizontalAlignment = "Stretch"
            $separatorBorder.Margin = "16,12,16,12"
            $separatorBorder.SetResourceReference([System.Windows.Controls.Control]::BackgroundProperty, "BorderColor")
            $separatorBorder.Opacity = 0.5
            $separatorBorder.CornerRadius = "1"

            # Replace rectangle with border
            $index = $isoPanel.Children.IndexOf($rectangle)
            $isoPanel.Children.RemoveAt($index)
            $isoPanel.Children.Insert($index, $separatorBorder)
        }
    }

    # Enhance CheckBoxes
    $checkBoxes = $isoPanel.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] }
    foreach ($checkBox in $checkBoxes) {
        $checkBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $checkBox.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $checkBox.Margin = "12,8,12,8"
        $checkBox.Padding = "8,4,8,4"
    }

    # Enhance RadioButtons
    $radioButtons = $isoPanel.Children | Where-Object { $_ -is [System.Windows.Controls.RadioButton] }
    foreach ($radioButton in $radioButtons) {
        $radioButton.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $radioButton.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $radioButton.Margin = "12,6,12,6"
        $radioButton.Padding = "8,4,8,4"
    }

    # Enhance TextBoxes
    $textBoxes = $isoPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TextBox] }
    foreach ($textBox in $textBoxes) {
        $textBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $textBox.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "LabelboxForegroundColor")
        $textBox.Margin = "12,6,12,8"
        $textBox.Padding = "8,6,8,6"
        $textBox.BorderThickness = "1"
        # Add subtle rounded corners
        try { $textBox.CornerRadius = "3" } catch { }
    }

    # Enhance main Get ISO button
    $getIsoButton = $sync.Form.FindName("WPFGetIso")
    if ($getIsoButton) {
        $getIsoButton.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $getIsoButton.Margin = "16,16,16,12"
        $getIsoButton.Padding = "20,10,20,10"
        $getIsoButton.FontWeight = "SemiBold"
        # Add subtle rounded corners
        try { $getIsoButton.CornerRadius = "4" } catch { }
    }
}

function Enhance-MicroWinOptionsPanel {
    <#
        .SYNOPSIS
            Enhances the visual styling of the MicroWin options configuration panel
    #>

    $optionsPanel = $sync.Form.FindName("MicrowinOptionsPanel")
    if (-not $optionsPanel) { return }

    # Find and enhance all TextBlocks (section headers and labels)
    $textBlocks = $optionsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
    foreach ($textBlock in $textBlocks) {
        if ($textBlock.FontWeight -eq "Bold" -or $textBlock.Text -like "*Bold*") {
            # Enhanced section headers
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $textBlock.FontWeight = "SemiBold"
            $textBlock.Margin = "8,16,8,8"
        } else {
            # Enhanced labels and descriptions
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
            $textBlock.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $textBlock.Margin = "12,6,12,4"
        }
    }

    # Replace Rectangle separators with modern styled borders
    $rectangles = $optionsPanel.Children | Where-Object { $_ -is [System.Windows.Shapes.Rectangle] }
    foreach ($rectangle in $rectangles) {
        if ($rectangle.Height -eq 2) {
            # Create modern separator border
            $separatorBorder = New-Object System.Windows.Controls.Border
            $separatorBorder.Height = 1
            $separatorBorder.HorizontalAlignment = "Stretch"
            $separatorBorder.Margin = "16,12,16,12"
            $separatorBorder.SetResourceReference([System.Windows.Controls.Control]::BackgroundProperty, "BorderColor")
            $separatorBorder.Opacity = 0.5
            $separatorBorder.CornerRadius = "1"

            # Replace rectangle with border
            $index = $optionsPanel.Children.IndexOf($rectangle)
            $optionsPanel.Children.RemoveAt($index)
            $optionsPanel.Children.Insert($index, $separatorBorder)
        }
    }

    # Enhance CheckBoxes
    $checkBoxes = $optionsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] }
    foreach ($checkBox in $checkBoxes) {
        $checkBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $checkBox.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $checkBox.Margin = "12,8,12,8"
        $checkBox.Padding = "8,4,8,4"
    }

    # Enhance TextBoxes
    $textBoxes = $optionsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TextBox] }
    foreach ($textBox in $textBoxes) {
        $textBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $textBox.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "LabelboxForegroundColor")
        $textBox.Margin = "12,4,12,8"
        $textBox.Padding = "8,6,8,6"
        $textBox.BorderThickness = "1"
        # Add subtle rounded corners
        try { $textBox.CornerRadius = "3" } catch { }
    }

    # Enhance PasswordBox
    $passwordBoxes = $optionsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.PasswordBox] }
    foreach ($passwordBox in $passwordBoxes) {
        $passwordBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $passwordBox.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "LabelboxForegroundColor")
        $passwordBox.Margin = "12,4,12,8"
        $passwordBox.Padding = "8,6,8,6"
        $passwordBox.BorderThickness = "1"
        # Add subtle rounded corners
        try { $passwordBox.CornerRadius = "3" } catch { }
    }

    # Enhance ComboBox
    $comboBox = $sync.Form.FindName("MicrowinWindowsFlavors")
    if ($comboBox) {
        $comboBox.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $comboBox.Margin = "12,4,12,12"
        $comboBox.Padding = "8,6,8,6"
    }

    # Enhance main Start Process button
    $startButton = $sync.Form.FindName("WPFMicrowin")
    if ($startButton) {
        $startButton.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        $startButton.Margin = "16,16,16,12"
        $startButton.Padding = "20,10,20,10"
        $startButton.FontWeight = "SemiBold"
        # Add subtle rounded corners
        try { $startButton.CornerRadius = "4" } catch { }
    }
}

function Enhance-MicroWinControls {
    <#
        .SYNOPSIS
            Enhances styling of individual MicroWin controls and elements
    #>

    # Enhance Back button
    $backButton = $sync.Form.FindName("WPFMicrowinPanelBack")
    if ($backButton) {
        $backButton.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
        # Add subtle rounded corners
        try { $backButton.CornerRadius = "4" } catch { }
    }

    # Enhance Panel 2 Title
    $panelTitle = $sync.Form.FindName("MicrowinPanel2Title")
    if ($panelTitle) {
        $panelTitle.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
        $panelTitle.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
        $panelTitle.FontWeight = "SemiBold"
        $panelTitle.Margin = "12,4,12,8"
    }

    # Enhance all file dialog buttons
    $fileButtons = @("MicrowinScratchDirBT", "MicrowinAutoConfigBtn")
    foreach ($buttonName in $fileButtons) {
        $button = $sync.Form.FindName($buttonName)
        if ($button) {
            $button.SetResourceReference([System.Windows.Controls.Control]::FontSizeProperty, "FontSize")
            $button.Padding = "8,6,8,6"
            # Add subtle rounded corners
            try { $button.CornerRadius = "3" } catch { }
        }
    }

    Write-Host "Enhanced styling applied to MicroWin section successfully!" -ForegroundColor Green
}
