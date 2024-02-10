function Invoke-WPFMaximizeButton {
    <#
    .SYNOPSIS
        Alternates between Maximized and Minimized window
    #>
    if ($sync["Form"].WindowState -eq [System.Windows.WindowState]::Maximized) {
        $sync["Form"].WindowState = [System.Windows.WindowState]::Normal
    } else {
        $sync["Form"].WindowState = [System.Windows.WindowState]::Maximized
    }
}