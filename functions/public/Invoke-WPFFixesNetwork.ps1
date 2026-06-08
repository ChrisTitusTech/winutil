function Invoke-WPFFixesNetwork {
    netsh winsock reset
    netsh int ip reset
    # Flush DNS cache
    ipconfig /flushdns
    Write-Host "Network Configuration has been Reset Please restart your computer."
}
