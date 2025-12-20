function Invoke-WinUtilExplorerUpdate {
    <#
    .SYNOPSIS
        Restarts Windows Explorer
    #>

    Stop-Process -Name explorer
}
