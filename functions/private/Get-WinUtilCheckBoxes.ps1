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
        $CheckBoxes = get-variable | Where-Object {$psitem.name -like "WPFInstall*" -and $psitem.value.GetType().name -eq "CheckBox"}
        Foreach ($CheckBox in $CheckBoxes){
            if($CheckBox.value.ischecked -eq $true){
                $sync.configs.applications.$($CheckBox.name).winget -split ";" | ForEach-Object {
                    $Output.Add($psitem)
                }
                if ($uncheck -eq $true){
                    $CheckBox.value.ischecked = $false
                }
                
            }
        }
    }
    if($Group -eq "WPFTweaks"){
        $CheckBoxes = get-variable | Where-Object {$psitem.name -like "WPF*Tweaks*" -and $psitem.value.GetType().name -eq "CheckBox"}
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
