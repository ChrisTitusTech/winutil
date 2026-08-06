function Get-WinUtilWinGetErrorMessage {
    <#
        .SYNOPSIS
            Turns a WinGet result code into something a person can act on

        .DESCRIPTION
            The winget command line prints a sentence explaining a failure; the client module
            returns only an HRESULT, so the same failure reads as
            "System.Runtime.InteropServices.COMException (0x8A15007D)". Both report the same
            number, so one table serves both paths.

            Unknown codes still get their hex form back, which is what a search needs.

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

    $messages = @{
        -1978335226 = "The installer ran but reported a failure."
        -1978335224 = "The installer could not be downloaded."
        -1978335216 = "No installer in this package applies to this machine."
        -1978335215 = "The downloaded installer did not match the expected hash, so it was rejected."
        -1978335212 = "No package matched that id."
        -1978335189 = "There is no newer version to upgrade to."
        -1978335135 = "The package is already installed."
        -1978335107 = "The package was installed for a single user and cannot be removed while WinUtil is running as administrator. Remove it from Settings > Apps, or run winget from a normal, unelevated terminal."
    }

    $hex = "0x{0:X8}" -f $Code
    if ($messages.ContainsKey($Code)) {
        return "$($messages[$Code]) ($hex)"
    }

    return "WinGet reported $hex. See https://learn.microsoft.com/windows/package-manager/winget/returnCodes"
}
