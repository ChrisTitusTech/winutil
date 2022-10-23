Function Get-FormVariables {
    #If ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    

    write-host ""                                                                                                                             
    write-host "    CCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT   "
    write-host " CCC::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T   "
    write-host "CC:::::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T  "
    write-host "C:::::CCCCCCCC::::CT:::::TT:::::::TT:::::TT:::::TT:::::::TT:::::T "
    write-host "C:::::C       CCCCCCTTTTTT  T:::::T  TTTTTTTTTTTT  T:::::T  TTTTTT"
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C                     T:::::T                T:::::T        "
    write-host "C:::::C       CCCCCC        T:::::T                T:::::T        "
    write-host "C:::::CCCCCCCC::::C      TT:::::::TT            TT:::::::TT       "
    write-host "CC:::::::::::::::C       T:::::::::T            T:::::::::T       "
    write-host "CCC::::::::::::C         T:::::::::T            T:::::::::T       "
    write-host "  CCCCCCCCCCCCC          TTTTTTTTTTT            TTTTTTTTTTT       "
    write-host ""
    write-host "====Chris Titus Tech====="
    write-host "=====Windows Toolbox====="
                           
 
    #====DEBUG GUI Elements====

    #write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    #get-variable WPF*
}

Function Get-CheckBoxes {
    Param(
        $Group
    )

    $CheckBoxes = get-variable | Where-Object {$psitem.name -like "$Group*" -and $psitem.value.GetType().name -eq "CheckBox"}
    $Output = New-Object System.Collections.Generic.List[System.Object]

    if($Group -eq "WPFInstall"){
        Foreach ($CheckBox in $CheckBoxes){
            if($checkbox.value.ischecked -eq $true){
                $output.Add("$($configs.applications.install.$($checkbox.name).winget)")
                $checkbox.value.ischecked = $false
            }
        }
    }

    Write-Output $Output
}