function Invoke-WPFFixesNetwork {
    netsh winsock reset
    netsh winhttp reset proxy
    netsh int ip reset

    Write-Host "Network Configuration has been Reset Please restart your computer."
}
