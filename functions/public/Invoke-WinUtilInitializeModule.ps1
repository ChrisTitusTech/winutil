function Invoke-WinUtilInitializeModule {
    <#
    .SYNOPSIS
        Initializes and imports a specified PowerShell module.

    .PARAMETER module
        The name of the module to be installed and imported. If the module is not already available, it will be installed for the current user.

    #>

    param (
        [string]$module
    )

    Invoke-WPFRunspace -ArgumentList $module -DebugPreference $DebugPreference -ScriptBlock {
        param ($module)
        try {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Host "Installing $module module..."
                Install-Module -Name $module -Force -Scope CurrentUser
            }
            Import-Module $module -ErrorAction Stop
            Write-Host "Imported $module module successfully"
        } catch {
            Write-Host "Error importing $module module: $_" -ForegroundColor Red
        }
    }
}
