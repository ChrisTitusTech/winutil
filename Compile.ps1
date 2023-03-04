$OFS = "`r`n"
$scriptname = "runspace.ps1"


Remove-Item .\$scriptname

Write-output '
################################################################################################################
###                                                                                                          ###
### WARNING: This file is automatically generated DO NOT modify this file directly as it will be overwritten ###
###                                                                                                          ###
################################################################################################################
' | Out-File ./$scriptname -Append

Get-Content .\scripts\start.ps1 | Out-File ./$scriptname -Append

Get-ChildItem .\functions -Recurse -File | ForEach-Object {
    Get-Content $psitem.FullName | Out-File ./$scriptname -Append
}

Get-ChildItem .\xaml | ForEach-Object {
    $xaml = (Get-Content $psitem.FullName).replace("'","''")
    
    Write-output "`$$($psitem.BaseName) = '$xaml'" | Out-File ./$scriptname -Append
}

Get-ChildItem .\config | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
    $json = (Get-Content $psitem.FullName).replace("'","''")
    
    Write-output "`$sync.configs.$($psitem.BaseName) = '$json' `| convertfrom-json" | Out-File ./$scriptname -Append
}

Get-Content .\scripts\main.ps1 | Out-File ./$scriptname -Append