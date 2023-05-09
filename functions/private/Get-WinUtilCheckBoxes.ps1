Function Get-WinUtilCheckBoxes {

    <#

        .DESCRIPTION
        Function is meant to find all checkboxes that are checked on the specefic tab and input them into a script.

        Outputed data will be the names of the checkboxes that were checked

        .EXAMPLE

        Get-WinUtilCheckBoxes "WPFInstall"

    #>

    Param(
        $Group,
        [boolean]$unCheck = $true
    )


    $Output = New-Object System.Collections.Generic.List[System.Object]

    if($Group -eq "WPFInstall"){
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPFInstall*"}
        $CheckBoxes = $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter}
        Foreach ($CheckBox in $CheckBoxes){
            if($CheckBox.value.ischecked -eq $true){
                $sync.configs.applications.$($CheckBox.Name).winget -split ";" | ForEach-Object {
                    $Output.Add($psitem)
                }
                if ($uncheck -eq $true){
                    $CheckBox.value.ischecked = $false
                }
                
            }
        }
    }
    
    if($Group -eq "WPFTweaks"){
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPF*Tweaks*"}
        $CheckBoxes = $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter}
        Foreach ($CheckBox in $CheckBoxes){
            if($CheckBox.value.ischecked -eq $true){
                $Output.Add($Checkbox.Name)
                
                if ($uncheck -eq $true){
                    $CheckBox.value.ischecked = $false
                }
            }
        }
    }

    if($Group -eq "WPFFeature"){
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPF*Feature*"}
        $CheckBoxes = $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter}
        Foreach ($CheckBox in $CheckBoxes){
            if($CheckBox.value.ischecked -eq $true){
                $Output.Add($Checkbox.Name)
                
                if ($uncheck -eq $true){
                    $CheckBox.value.ischecked = $false
                }
            }
        }
    }

    Write-Output $($Output | Select-Object -Unique)
}
