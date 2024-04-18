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
        $columncount=1
    )
    $jsonfileitems = (Get-Content ".\config\$($tabname).json").replace("'","''") | convertfrom-json
    # $jsonfileitems = (Get-Content ".\config\$($tabname).json") | convertfrom-json
    if ($null -eq $columncount) {$columncount=1}
    # Iterate through JSON data and organize by panel and category
    $sort = if ($columncount -eq 1) {$false} else {$true}
    $appnames = if ($sort)
        { $jsonfileitems | Get-Member -Type  NoteProperty | Sort-Object -Property @{Expression={$jsonfileitems.$($_.Name).category}},Name | ForEach-Object {$_.Name}}
    else
        { $jsonfileitems.PSObject.Properties.Name }
    $linecount=($jsonfileitems.PsObject.Properties.value.category | Sort-Object | Get-Unique).count + $appnames.count
    $maxlinecount = [Math]::Round( $linecount / $columncount + 0.5)
    $count=0
    $currentpanel=0
    $currentcategory=""
    $tabXml="`n<Border Grid.Row=`"1`" Grid.Column=`"0`">`n<StackPanel Background=`"{MainBackgroundColor}`" SnapsToDevicePixels=`"True`">"
    $addpanel={ $count++
        if ($appname -like "panel*" -or $count -ge $maxlinecount) {
            $currentpanel++
            $tabXml+="`n</StackPanel>`n</Border>`n<Border Grid.Row=`"1`" Grid.Column=`"$currentpanel`">`n<StackPanel Background=`"{MainBackgroundColor}`" SnapsToDevicePixels=`"True`">"
            $count=0
        }
    }
    foreach ($appName in $appnames) {
        $appInfo = $jsonfileitems.$appName
        if ($appname -like "category*" -or ($sort -and $appInfo.category -ne $currentcategory)) {
            $tabXml += "`n<Label Content=`"$($appInfo.category)`" FontSize=`"16`"/>"
            Invoke-Command -ScriptBlock $addpanel -NoNewScope
        }
        $tabXml += (ConvertTo-xaml $appInfo $appName)
        Invoke-Command -ScriptBlock $addpanel -NoNewScope
        $currentcategory=$appInfo.category
    }
    $columndefs ="`n<Grid.ColumnDefinitions>`n"+("<ColumnDefinition Width=`"*`"/>`n"*($currentpanel+1))+"</Grid.ColumnDefinitions>"
    return "$($columndefs)`n$($tabXml)`n</StackPanel>`n</Border>"
}
function ConvertTo-xaml {
    param( [Parameter(Mandatory=$true)]
        $appInfo,
        $appName = ""
    )
    if ($null -ne $appInfo.Content) {
        switch -regex ($appInfo.Type) {
            "Toggle" {
                return "`n<StackPanel Orientation=`"Horizontal`" Margin=`"0,10,0,0`">`n<Label Content=`"$($appInfo.Content)`" Style=`"{StaticResource labelfortweaks}`" ToolTip=`"$($appInfo.Description)`" />`n<CheckBox Name=`"$appName`" Style=`"{StaticResource ColorfulToggleSwitchStyle}`" Margin=`"2.5,0`"/>`n</StackPanel>"
            }
            "Combobox" {
                $addfirst="IsSelected=`"True`""
                $rt = "`n<StackPanel Orientation=`"Horizontal`" Margin=`"0,5,0,0`">`n`<Label Content=`"$($appInfo.Content)`" HorizontalAlignment=`"Left`" VerticalAlignment=`"Center`"/>`n<ComboBox Name=`"$appName`"  Height=`"32`" Width=`"186`" HorizontalAlignment=`"Left`" VerticalAlignment=`"Center`" Margin=`"5,5`">"
                foreach ($comboitem in ($appInfo.ComboItems -split " ")) {
                        $rt += "`n<ComboBoxItem $addfirst Content=`"$comboitem`"/>"
                        $addfirst=""
                    }
                    return "$rt`n</ComboBox>`n</StackPanel>"
                }
            "Tab" {
                return "`n<ToggleButton HorizontalAlignment=`"Left`" Height=`"{ToggleButtonHeight}`" Width=`"100`"`nBackground=`"{Button$($appInfo.color)BackgroundColor}`" Foreground=`"{Button$($appInfo.color)ForegroundColor}`" FontWeight=`"Bold`" Name=`"$appName`">`n<ToggleButton.Content>`n<TextBlock Background=`"Transparent`" Foreground=`"{Button$($appInfo.color)ForegroundColor}`" >`n$($appInfo.Content)`n</TextBlock>`n</ToggleButton.Content>`n</ToggleButton>"
            }
            # If it is a digit, type is button and button length is digits
            "^[\d\.]+$" {
                if ($null -ne $appInfo.textblock) {
                    return "`n<Button Name=`"$appName`" FontSize=`"16`" Content=`"$($appInfo.Content)`" Margin=`"20,4,20,10`" Padding=`"10`"/>`n<TextBlock Margin=`"20,0,20,0`" Padding=`"10`" TextWrapping=`"WrapWithOverflow`" MaxWidth=`"300`">$($appInfo.textblock -replace "\r?\n","<LineBreak/>")</TextBlock>"
                } else {
                    return "`n<Button Name=`"$appName`" Content=`"$($appInfo.Content)`" HorizontalAlignment = `"Left`" Width=`"$($appInfo.Type)`" Margin=`"5`" Padding=`"20,5`" />"
                }

            }
            "Button"   {return "`n<Button Name=`"$appname`" Content=`"$($appInfo.Content)`" Margin=`"1`"/>"}
            "Label"    {return "`n<Label Content=`"$($appInfo.Content)`" $FontSize VerticalAlignment=`"Center`"/>"}
            "TextBlock"{return "`n<TextBlock Padding=`"10`">`n$($appInfo.Content -replace "\r?\n","`n<LineBreak/>")`n</TextBlock>"}
            # else it is a checkbox
            Default {
                $checkedStatus = if ($($appInfo.Checked -ne "True")) {""} else {"IsChecked=`"True`" "}
                if ($null -eq $appInfo.Link) {
                    return "`n<CheckBox Name=`"$appName`" Content=`"$($appInfo.Content)`" $($checkedStatus)Margin=`"5,0`"  ToolTip=`"$($appInfo.Description)`"/>"
                }
                else {
                    return "`n<StackPanel Orientation=`"Horizontal`">`n<CheckBox Name=`"$appName`" Content=`"$($appInfo.Content)`" $($checkedStatus)ToolTip=`"$($appInfo.Description)`" Margin=`"0,0,2,0`"/><TextBlock Name=`"$($appName)Link`" Style=`"{StaticResource HoverTextBlockStyle}`" Text=`"(?)`" ToolTip=`"$($appInfo.Link)`" />`n</StackPanel>"
                }
            }
        }
    }
}