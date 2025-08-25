Function Get-WinUtilToggleStatusSafe {
    <#
    .SYNOPSIS
        Safely gets the toggle status without showing error messages for missing registry entries

    .PARAMETER ToggleSwitch
        The name of the toggle to check

    .OUTPUTS
        Boolean to set the toggle's status to, or $false if there are any errors
    #>

    Param($ToggleSwitch)

    try {
        # Completely suppress all error output streams and capture result
        $result = & {
            $ErrorActionPreference = 'SilentlyContinue'
            $WarningPreference = 'SilentlyContinue'
            $VerbosePreference = 'SilentlyContinue'
            $DebugPreference = 'SilentlyContinue'
            $InformationPreference = 'SilentlyContinue'

            # Redirect all output streams to null and only capture the return value
            Get-WinUtilToggleStatus $ToggleSwitch 2>$null 3>$null 4>$null 5>$null 6>$null
        }

        # Only return if we got a valid boolean result
        if ($result -is [bool]) {
            return $result
        } else {
            return $false
        }
    } catch {
        # Return false for any errors
        return $false
    }
}
