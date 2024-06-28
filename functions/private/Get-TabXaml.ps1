function Get-TabXaml {
    <#
    .SYNOPSIS
        Generates XAML for a tab in the WinUtil GUI
        This function is used to generate the XAML for the applications tab in the WinUtil GUI
        It takes the tabname and the number of columns to display the applications in as input and returns the XAML for the tab as output
    .PARAMETER tabname
        The name of the tab to generate XAML for
    .PARAMETER columncount
        The number of columns to display the applications in
    .OUTPUTS
        The XAML for the tab
    .EXAMPLE
        Get-TabXaml "applications" 3
    #>


    param( [Parameter(Mandatory=$true)]
        $tabname,
        $columncount = 0
    )
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
    $panelcount=0
    $paneltotal = $organizedData.Keys.Count
    if ($columncount -gt 0) {
        $appcount = $sync.configs.$tabname.PSObject.Properties.Name.count + $organizedData["0"].Keys.count
        $maxcount = [Math]::Round( $appcount / $columncount + 0.5)
        $paneltotal = $columncount
    }
    # add ColumnDefinitions to evenly draw colums
    $blockXml="<Grid.ColumnDefinitions>`r`n"+("<ColumnDefinition Width=""*""/>`r`n"*($paneltotal))+"</Grid.ColumnDefinitions>`r`n"
    # Iterate through organizedData by panel, category, and application
    $count = 0
    foreach ($panel in ($organizedData.Keys | Sort-Object)) {
        $blockXml += "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">`r`n<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">`r`n"
        $panelcount++
        foreach ($category in ($organizedData[$panel].Keys | Sort-Object)) {
            $count++
            if ($columncount -gt 0) {
                $panelcount2 = [Int](($count)/$maxcount-0.5)
                if ($panelcount -eq $panelcount2 ) {
                    $blockXml +="`r`n</StackPanel>`r`n</Border>`r`n"
                    $blockXml += "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">`r`n<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">`r`n"
                    $panelcount++
                }
            }

            # Dot-source the Get-WPFObjectName function
            . .\functions\private\Get-WPFObjectName

            $categorycontent = $($category -replace '^.__', '')
            $categoryname = Get-WPFObjectName -type "Label" -name $categorycontent
            $blockXml += "<Label Name=""$categoryname"" Content=""$categorycontent"" FontSize=""16""/>`r`n"
            $sortedApps = $organizedData[$panel][$category].Keys | Sort-Object
            foreach ($appName in $sortedApps) {
                $count++
                if ($columncount -gt 0) {
                    $panelcount2 = [Int](($count)/$maxcount-0.5)
                    if ($panelcount -eq $panelcount2 ) {
                        $blockXml +="`r`n</StackPanel>`r`n</Border>`r`n"
                        $blockXml += "<Border Grid.Row=""1"" Grid.Column=""$panelcount"">`r`n<StackPanel Background=""{MainBackgroundColor}"" SnapsToDevicePixels=""True"">`r`n"
                        $panelcount++
                    }
                }
                $appInfo = $organizedData[$panel][$category][$appName]
                if ("Toggle" -eq $appInfo.Type) {
                    $blockXml += "<DockPanel LastChildFill=`"True`">`r`n<Label Content=`"$($appInfo.Content)`" ToolTip=`"$($appInfo.Description)`" HorizontalAlignment=`"Left`"/>`r`n"
                    $blockXml += "<CheckBox Name=`"$($appInfo.Name)`" Style=`"{StaticResource ColorfulToggleSwitchStyle}`" Margin=`"2.5,0`" HorizontalAlignment=`"Right`"/>`r`n</DockPanel>`r`n"
                } elseif ("Combobox" -eq $appInfo.Type) {
                    $blockXml += "<StackPanel Orientation=`"Horizontal`" Margin=`"0,5,0,0`">`r`n<Label Content=`"$($appInfo.Content)`" HorizontalAlignment=`"Left`" VerticalAlignment=`"Center`"/>`r`n"
                    $blockXml += "<ComboBox Name=`"$($appInfo.Name)`"  Height=`"32`" Width=`"186`" HorizontalAlignment=`"Left`" VerticalAlignment=`"Center`" Margin=`"5,5`">`r`n"
                    $addfirst="IsSelected=`"True`""
                    foreach ($comboitem in ($appInfo.ComboItems -split " ")) {
                        $blockXml += "<ComboBoxItem $addfirst Content=`"$comboitem`"/>`r`n"
                        $addfirst=""
                    }
                    $blockXml += "</ComboBox>`r`n</StackPanel>"
                # If it is a digit, type is button and button length is digits
                } elseif ($appInfo.Type -match "^[\d\.]+$") {
                    $blockXml += "<Button Name=`"$($appInfo.Name)`" Content=`"$($appInfo.Content)`" HorizontalAlignment = `"Left`" Width=`"$($appInfo.Type)`" Margin=`"5`" Padding=`"20,5`" />`r`n"
                # else it is a checkbox
                } else {
                    $checkedStatus = If ($null -eq $appInfo.Checked) {""} Else {"IsChecked=`"$($appInfo.Checked)`" "}
                    if ($null -eq $appInfo.Link)
                    {
                        $blockXml += "<CheckBox Name=`"$($appInfo.Name)`" Content=`"$($appInfo.Content)`" $($checkedStatus)Margin=`"5,0`"  ToolTip=`"$($appInfo.Description)`"/>`r`n"
                    }
                    else
                    {
                        $blockXml += "<StackPanel Orientation=""Horizontal"">`r`n<CheckBox Name=""$($appInfo.Name)"" Content=""$($appInfo.Content)"" $($checkedStatus)ToolTip=""$($appInfo.Description)"" Margin=""0,0,2,0""/><TextBlock Name=""$($appInfo.Name)Link"" Style=""{StaticResource HoverTextBlockStyle}"" Text=""(?)"" ToolTip=""$($appInfo.Link)"" />`r`n</StackPanel>`r`n"
                    }
                }
            }
        }
        $blockXml +="`r`n</StackPanel>`r`n</Border>`r`n"
    }
    return ($blockXml)
}
