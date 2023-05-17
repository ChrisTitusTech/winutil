function Invoke-WPFFixesNetwork {
    <#
    
        .DESCRIPTION
        PlaceHolder
    
    #>
    Write-Host "Reseting Network with netsh"
    netsh int ip reset
    netsh winsock reset
}