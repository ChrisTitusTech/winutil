function Get-TabXaml {
    <#
    .SYNOPSIS
        Generates XAML for a tab in the WinUtil GUI
        This function is used to generate the XAML for the applications tab in the WinUtil GUI
        It takes the tabname and the number of columns to display the applications in as input and returns the XAML for the tab as output
    .PARAMETER tabname
        The name of the tab to generate XAML for
        Note: the 'tabname' parameter must equal one of the json files found in $sync.configs variable
              Otherwise, it'll throw an exception
    .PARAMETER columncount
        The number of columns to display the applications in, default is 0
    .OUTPUTS
        The XAML for the tab
    .EXAMPLE
        Get-TabXaml "applications" 3
    #>


    param(
        [Parameter(Mandatory, position=0)]
        [string]$tabname,

        [Parameter(position=1)]
        [ValidateRange(0,10)] # 10 panels as max number is more then enough
        [int]$columncount = 0
    )

    # Validate tabname
    if ($sync.configs.$tabname -eq $null) {
        throw "Invalid parameter passed, can't find '$tabname' in '`$sync.configs' variable, please double check any calls to 'Get-TabXaml' function."
    }

    $organizedData = @{}
    # Iterate through JSON data and organize by panel and category
    foreach ($appName in $sync.configs.$tabname.PSObject.Properties.Name) {
        $appInfo = $sync.configs.$tabname.$appName

        # Create an object for the application
        $appObject = [PSCustomObject]@{
            Name = $appName
            Category = $appInfo.Category
            Content = $appInfo.Content
            Choco = $appInfo.choco
            Winget = $appInfo.winget
            Panel = if ($columncount -gt 0 ) { "0" } else {$appInfo.panel}
            Link = $appInfo.link
            Description = $appInfo.description
            # Type is (Checkbox,Toggle,Button,Combobox ) (Default is Checkbox)
            Type = $appInfo.type
            ComboItems = $appInfo.ComboItems
            # Checked is the property to set startup checked status of checkbox (Default is false)
            Checked = $appInfo.Checked
            ButtonWidth = $appInfo.ButtonWidth
        }

        if (-not $organizedData.ContainsKey($appObject.panel)) {
            $organizedData[$appObject.panel] = @{}
        }

        if (-not $organizedData[$appObject.panel].ContainsKey($appObject.Category)) {
            $organizedData[$appObject.panel][$appObject.Category] = @{}
        }

        # Store application data in a sub-array under the category
        # Add Order property to keep the original order of tweaks and features
        $organizedData[$appObject.panel][$appInfo.Category]["$($appInfo.order)$appName"] = $appObject
    }

    # Same tab amount in last line of 'inputXML.xaml' file
    # TODO: Get the base repeat (amount) of tabs from last line (or even lines)
    #       so it can dynamicly react to whatever is before this generated XML string.
    #       .. may be solve this even before calling this function, and pass the result as a parameter?
    $tab_repeat = 7
    $spaces_per_tab = 4 # The convenction used across the code base
    $tab_as_spaces = $(" " * $spaces_per_tab)
    $precal_indent = $($tab_as_spaces * $tab_repeat)
    $precal_indent_p1 = $($tab_as_spaces * ($tab_repeat + 1))
    $precal_indent_p2 = $($tab_as_spaces * ($tab_repeat + 2))
    $precal_indent_m1 = $($tab_as_spaces * ($tab_repeat - 1))
    $precal_indent_m2 = $($tab_as_spaces * ($tab_repeat - 2))

    # Calculate the needed number of panels
    $panelcount = 0
    $paneltotal = $organizedData.Keys.Count
    if ($columncount -gt 0) {
        $appcount = $sync.configs.$tabname.PSObject.Properties.Name.count + $organizedData["0"].Keys.count
        $maxcount = [Math]::Round( $appcount / $columncount + 0.5)
        $paneltotal = $columncount
    }
    # add ColumnDefinitions to evenly draw colums
    $blockXml = "<Grid.ColumnDefinitions>"
    $blockXml += $("`r`n" + " " * ($spaces_per_tab * $tab_repeat) +
                 "<ColumnDefinition Width=""*""/>") * $paneltotal
    $blockXml += $("`r`n" + " " * ($spaces_per_tab * ($tab_repeat - 1))) +
                 "</Grid.ColumnDefinitions>" + "`r`n"

    # Iterate through 'organizedData' by panel, category, and application
    $count = 0
    foreach ($panel in ($organizedData.Keys | Sort-Object)) {
        $blockXml += $precal_indent_m1 + "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">" + "`r`n"
        $blockXml += $precal_indent + "<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">" + "`r`n"
        $panelcount++
        foreach ($category in ($organizedData[$panel].Keys | Sort-Object)) {
            $count++
            if ($columncount -gt 0) {
                $panelcount2 = [Int](($count)/$maxcount-0.5)
                if ($panelcount -eq $panelcount2 ) {
                    $blockXml += $precal_indent_p2 + "</StackPanel>" + "`r`n"
                    $blockXml += $precal_indent_p1 + "</Border>" + "`r`n"
                    $blockXml += $precal_indent_p1 + "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">" + "`r`n"
                    $blockXml += $precal_indent_p2 + "<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">" + "`r`n"
                    $panelcount++
                }
            }

            # Dot-source the Get-WPFObjectName function
            . .\functions\private\Get-WPFObjectName

            $categorycontent = $($category -replace '^.__', '')
            $categoryname = Get-WPFObjectName -type "Label" -name $categorycontent
            $blockXml += $("`r`n" + " " * ($spaces_per_tab * $tab_repeat)) +
                            "<Label Name=""$categoryname"" Content=""$categorycontent""" + " " +
                            "FontSize=""{FontSizeHeading}"" FontFamily=""{HeaderFontFamily}""/>" + "`r`n" + "`r`n"
            $sortedApps = $organizedData[$panel][$category].Keys | Sort-Object
            foreach ($appName in $sortedApps) {
                $count++

                if ($columncount -gt 0) {
                    $panelcount2 = [Int](($count)/$maxcount-0.5)
                    # Verify the indentation actually works...
                    if ($panelcount -eq $panelcount2 ) {
                        $blockXml += $precal_indent_m1 +
                                        "</StackPanel>" + "`r`n"
                        $blockXml += $precal_indent_m2 +
                                        "</Border>" + "`r`n"
                        $blockXml += $precal_indent_m2 +
                                        "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">" + "`r`n"
                        $blockXml += $precal_indent_m1 +
                                        "<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">" + "`r`n"
                        $panelcount++
                    }
                }

                $appInfo = $organizedData[$panel][$category][$appName]
                switch ($appInfo.Type) {
                    "Toggle" {
                        $blockXml += $precal_indent_m1 +
                                        "<DockPanel LastChildFill=""True"">" + "`r`n"
                        $blockXml += $precal_indent +
                                        "<CheckBox Name=""$($appInfo.Name)"" Style=""{StaticResource ColorfulToggleSwitchStyle}"" Margin=""4,0""" + " " +
                                        "HorizontalAlignment=""Right"" FontSize=""{FontSize}""/>" + "`r`n"
                        $blockXml += $precal_indent +
                                        "<Label Content=""$($appInfo.Content)"" ToolTip=""$($appInfo.Description)""" + " " +
                                        "HorizontalAlignment=""Left"" FontSize=""{FontSize}""/>" + "`r`n"
                        $blockXml += $precal_indent_m1 +
                                        "</DockPanel>" + "`r`n"
                    }

                    "Combobox" {
                        $blockXml += $precal_indent_m1 +
                                        "<StackPanel Orientation=""Horizontal"" Margin=""0,5,0,0"">" + "`r`n"
                        $blockXml += $precal_indent + "<Label Content=""$($appInfo.Content)"" HorizontalAlignment=""Left""" + " " +
                                        "VerticalAlignment=""Center"" FontSize=""{FontSize}""/>" + "`r`n"
                        $blockXml += $precal_indent +
                                        "<ComboBox Name=""$($appInfo.Name)""  Height=""32"" Width=""186"" HorizontalAlignment=""Left""" + " " +
                                        "VerticalAlignment=""Center"" Margin=""5,5"" FontSize=""{FontSize}"">" + "`r`n"

                        $addfirst="IsSelected=""True"""
                        foreach ($comboitem in ($appInfo.ComboItems -split " ")) {
                            $blockXml += $precal_indent_p1 +
                                            "<ComboBoxItem $addfirst Content=""$comboitem"" FontSize=""{FontSize}""/>" + "`r`n"
                            $addfirst=""
                        }

                        $blockXml += $precal_indent_p1 + "</ComboBox>" + "`r`n"
                        $blockXml += $precal_indent + "</StackPanel>" + "`r`n"
                    }

                    "Button" {
                        if ($appInfo.ButtonWidth -ne $null) {
                            $ButtonWidthStr = "Width=""$($appInfo.ButtonWidth)"""
                        }
                        $blockXml += $precal_indent +
                                        "<Button Name=""$($appInfo.Name)"" Content=""$($appInfo.Content)""" + " " +
                                        "HorizontalAlignment=""Left"" Margin=""5"" Padding=""20,5"" $($ButtonWidthStr)/>" + "`r`n"
                    }

                    # else it is a checkbox
                    default {
                        $checkedStatus = If ($appInfo.Checked -eq $null) {""} Else {" IsChecked=""$($appInfo.Checked)"""}
                        if ($appInfo.Link -eq $null) {
                            $blockXml += $precal_indent +
                                            "<CheckBox Name=""$($appInfo.Name)"" Content=""$($appInfo.Content)""$($checkedStatus) Margin=""5,0""" + " " +
                                            "ToolTip=""$($appInfo.Description)""/>" + "`r`n"
                        } else {
                            $blockXml += $precal_indent +
                                            "<StackPanel Orientation=""Horizontal"">" + "`r`n"
                            $blockXml += $precal_indent_p1 +
                                            "<CheckBox Name=""$($appInfo.Name)"" Content=""$($appInfo.Content)""$($checkedStatus)" + " " +
                                            "ToolTip=""$($appInfo.Description)"" Margin=""0,0,2,0""/>" + "`r`n"
                            $blockXml += $precal_indent_p1 +
                                            "<TextBlock Name=""$($appInfo.Name)Link"" Style=""{StaticResource HoverTextBlockStyle}"" Text=""(?)""" + " " +
                                            "ToolTip=""$($appInfo.Link)""/>" + "`r`n"
                            $blockXml += $precal_indent +
                                            "</StackPanel>" + "`r`n"
                        }
                    }
                }
            }
        }

        $blockXml += $precal_indent_p1 + "</StackPanel>" + "`r`n"
        $blockXml += $precal_indent + "</Border>" + "`r`n"
    }
    return ($blockXml)
}
