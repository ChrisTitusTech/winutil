function Invoke-WPFMinimizeButton {
    <#
    .SYNOPSIS
        Minimize the application window
    #>
    $sync["Form"].WindowState = [System.Windows.WindowState]::Minimized
}