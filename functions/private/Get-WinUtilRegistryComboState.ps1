function Get-WinUtilRegistryComboState {
    <#
    .SYNOPSIS
        Finds the configured combo-box state matching the current registry values.

    .PARAMETER Registry
        Registry settings containing a value mapping for each supported state.

    .OUTPUTS
        The name of the matching state.
    #>
    param(
        [Parameter(Mandatory)]
        $Registry
    )

    foreach ($state in $Registry[0].Values.PSObject.Properties) {
        $stateMatches = $true
        foreach ($setting in @($Registry)) {
            $currentValue = Get-WinUtilRegistryComboValue -Setting $setting
            $actualValue = if ($currentValue.Exists -and $null -ne $currentValue.Value) { $currentValue.Value } else { $setting.DefaultValue }
            $configuredValue = $setting.Values.PSObject.Properties[$state.Name].Value
            # Removal represents the effective Windows default when matching the current state.
            $expectedValue = if ($configuredValue -eq "<RemoveEntry>") { $setting.DefaultValue } else { $configuredValue }
            if ([string]$actualValue -ne [string]$expectedValue) {
                $stateMatches = $false
                break
            }
        }
        if ($stateMatches) {
            return $state.Name
        }
    }

    throw "Registry values do not match a supported state."
}
