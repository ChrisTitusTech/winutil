function Invoke-WPFFixesWinget {

    <#

    .SYNOPSIS
        Fixes WinGet by running `choco install winget`
    .DESCRIPTION
        BravoNorris for the fantastic idea of a button to reinstall WinGet
    #>

    Step-WinUtilJob -Status "Repairing WinGet" -State "Indeterminate"
    Install-WinUtilWinget -Force
}
