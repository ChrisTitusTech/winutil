function Invoke-WPFFixesNetwork {
    netsh winsock reset
    netsh int ip reset
    ipconfig /flushdns
    Write-Host "Network Configuration has been Reset Please restart your computer."
}
