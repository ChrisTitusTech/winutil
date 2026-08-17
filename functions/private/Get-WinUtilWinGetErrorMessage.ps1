function Get-WinUtilWinGetErrorMessage {
    <#
        .SYNOPSIS
            Turns a WinGet result code into something a person can act on

        .DESCRIPTION
            The winget command line prints a sentence explaining a failure; the client module
            returns only an HRESULT, so the same failure reads as
            "System.Runtime.InteropServices.COMException (0x8A15007D)". Both report the same
            number, so the hex form and Microsoft's own list of what it means serve both paths.
            Restating that list here would only be a copy to keep in step with it.

        .PARAMETER Code
            The exit code or HRESULT, as a signed 32 bit integer.
    #>
    param(
        [Parameter(Mandatory)]
        [int]$Code
    )

    if ($Code -eq 0) {
        return $null
    }

    return ("WinGet reported 0x{0:X8}. See https://learn.microsoft.com/windows/package-manager/winget/returnCodes" -f $Code)
}
