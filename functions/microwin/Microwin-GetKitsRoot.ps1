function Microwin-GetKitsRoot {
    <#
        .SYNOPSIS
            Gets the kits root path for the Windows Assessment and Deployment Kit (ADK)
        .PARAMETER wow64environment
            Determines whether to search in a WOW64 compatibility environment (HKLM\SOFTWARE\WOW6432Node)
        .OUTPUTS
            The path to the kits root
    #>

    param (
        [Parameter(Mandatory = $true, Position = 0)] [bool]$wow64environment
    )

    $adk10KitsRoot = ""

    # if we set the wow64 bit on and we're on a 32-bit system, then we prematurely return the value
    if (($wow64environment -eq $true) -and (-not [Environment]::Is64BitOperatingSystem)) {
        return $adk10KitsRoot
    }

    $regPath = ""
    if ($wow64environment) {
        $regPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
    } else {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
    }

    if ((Test-Path "$regPath") -eq $false) {
        return $adk10KitsRoot
    }

    try {
        $adk10KitsRoot = Get-ItemPropertyValue -Path $regPath -Name "KitsRoot10" -ErrorAction Stop
    } catch {
        Write-Debug "Could not find ADK."
    }

    return $adk10KitsRoot
}
