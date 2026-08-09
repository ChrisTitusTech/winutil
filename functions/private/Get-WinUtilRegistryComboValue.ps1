function Get-WinUtilRegistryComboValue {
    <#
    .SYNOPSIS
        Reads one registry value for a registry-backed combo-box state.

    .PARAMETER Setting
        The registry setting from the combo-box configuration.
    #>
    param(
        [Parameter(Mandatory)]
        $Setting
    )

    try {
        $item = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction Stop
        $property = $item.PSObject.Properties[$Setting.Name]
        return [pscustomobject]@{ Exists = $null -ne $property; Value = $property.Value }
    } catch [System.Management.Automation.PSArgumentException] {
        # The registry provider uses PSArgumentException when a named value is absent.
        return [pscustomobject]@{ Exists = $false; Value = $null }
    } catch [System.Management.Automation.ItemNotFoundException] {
        return [pscustomobject]@{ Exists = $false; Value = $null }
    }
}
