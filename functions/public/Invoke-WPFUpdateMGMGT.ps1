function Invoke-WPFUpdateMGMT {
    param (
        [switch]$Selected,
        [switch]$All
    )

    if ($Selected) {
        write-host "Installing selected updates"
    } elseif ($All) {
        Write-Host "Installing all available updates"
    }

}
