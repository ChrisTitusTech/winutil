function Invoke-WPFCloseButton {

    <#

    .SYNOPSIS
        Close application

    .PARAMETER Button
    #>
    $sync["Form"].Close()
    Write-Host "Bye bye!"
}
