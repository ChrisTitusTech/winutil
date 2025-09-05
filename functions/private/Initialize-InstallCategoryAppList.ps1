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

            $toggleButton = New-Object Windows.Controls.Label
            $toggleButton.Content = "$Category"
            $toggleButton.Tag = "CategoryToggleButton"
            $toggleButton.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "HeaderFontSize")
            $toggleButton.SetResourceReference([Windows.Controls.Control]::FontFamilyProperty, "HeaderFontFamily")
            $sync.$Category = $toggleButton

            $null = $TargetElement.Items.Add($toggleButton)
        }


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
            $wrapPanel.Visibility = [Windows.Visibility]::Visible
            $wrapPanel.Tag = "CategoryWrapPanel_$category"
            $null = $TargetElement.Items.Add($wrapPanel)
            $appsByCategory[$category] |Sort-Object | ForEach-Object {
                $sync.$_ =  $(Initialize-InstallAppEntry -TargetElement $wrapPanel -AppKey $_)
            }
        }
    }
