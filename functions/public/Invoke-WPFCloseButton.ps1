function Invoke-CloseButton {

    <#

    .SYNOPSIS
        Close application

    .PARAMETER Button
    #>
    $sync["Form"].Close()
    Write-Host "Bye bye!"
}