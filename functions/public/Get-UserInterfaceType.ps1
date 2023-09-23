function Get-UserInterfaceType {
    $PSBoundParameters = Get-Variable -Name "PSBoundParameters" -Scope "Script"
    if ($PSBoundParameters.Count -gt 0) {
        return "CLI"
    }
    else {
        return "WPF"
    }
}