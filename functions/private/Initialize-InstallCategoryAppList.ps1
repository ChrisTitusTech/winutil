function Initialize-InstallCategoryAppList {
    <#
        .SYNOPSIS
            Clears the Target Element and sets up a "Loading" message. This is done, because loading of all apps can take a bit of time in some scenarios
            Iterates through all Categories and Apps and adds them to the UI
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Element into which the Categories and Apps should be placed
        .PARAMETER Apps
            The Hashtable of Apps to be added to the UI
            The Categories are also extracted from the Apps Hashtable

    #>
        param(
            $TargetElement,
            $Apps
        )
        function Add-Category {
            param(
                [string]$Category,
                [Windows.Controls.ItemsControl]$TargetElement
            )

            $toggleButton = New-Object Windows.Controls.Primitives.ToggleButton
            $toggleButton.Content = "$Category"
            $toggleButton.Tag = "CategoryToggleButton"
            $toggleButton.Cursor = [System.Windows.Input.Cursors]::Hand
            $toggleButton.SetResourceReference([Windows.Controls.Control]::StyleProperty, "CategoryToggleButtonStyle")
            $sync.Buttons.Add($toggleButton)
            $toggleButton.Add_Checked({
                # Clear the search bar when a category is clicked
                $sync.SearchBar.Text = ""
                Set-CategoryVisibility -Category $this.Content -overrideState Expand
            })
            $toggleButton.Add_Unchecked({
                Set-CategoryVisibility -Category $this.Content -overrideState Collapse
            })
            $null = $TargetElement.Items.Add($toggleButton)
        }

        $loadingLabel = New-Object Windows.Controls.Label
        $loadingLabel.Content = "Loading, please wait..."
        $loadingLabel.HorizontalAlignment = "Center"
        $loadingLabel.VerticalAlignment = "Center"
        $loadingLabel.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
        $loadingLabel.FontWeight = [Windows.FontWeights]::Bold
        $loadingLabel.Foreground = [Windows.Media.Brushes]::Gray
        $sync.LoadingLabel = $loadingLabel

        $TargetElement.Items.Clear()
        $null = $TargetElement.Items.Add($sync.LoadingLabel)
        # Use the Dispatcher to make sure the Loading message is shown before the logic loading the apps starts, and only is removed when the loading is complete and the apps are added to the UI
        $TargetElement.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{

            $TargetElement.Items.Clear() # Remove the loading message

            # Pre-group apps by category
            $appsByCategory = @{}
            foreach ($appKey in $Apps.Keys) {
                $category = $Apps.$appKey.Category
                if (-not $appsByCategory.ContainsKey($category)) {
                    $appsByCategory[$category] = @()
                }
                $appsByCategory[$category] += $appKey
            }
            foreach ($category in $($appsByCategory.Keys | Sort-Object)) {
                Add-Category -Category $category -TargetElement $TargetElement
                $wrapPanel = New-Object Windows.Controls.WrapPanel
                $wrapPanel.Orientation = "Horizontal"
                $wrapPanel.HorizontalAlignment = "Stretch"
                $wrapPanel.VerticalAlignment = "Center"
                $wrapPanel.Margin = New-Object Windows.Thickness(0, 0, 0, 20)
                $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                $wrapPanel.Tag = "CategoryWrapPanel_$category"
                $null = $TargetElement.Items.Add($wrapPanel)
                $appsByCategory[$category] | ForEach-Object {
                    $sync.$_ =  $(Initialize-InstallAppEntry -TargetElement $wrapPanel -AppKey $_)
            }
        }
    })
    }
