function Test-WinUtilRegistryValueMatch {
    <#
    .SYNOPSIS
        Compares registry values with sentinel, null, hex, and type-aware handling.
    #>
    param(
        [AllowNull()]
        $CurrentValue,
        $ExpectedValue,
        [string]$Type = 'String'
    )

    if ($ExpectedValue -eq '<RemoveEntry>') {
        return ($null -eq $CurrentValue) -or ($CurrentValue -eq '<RemoveEntry>')
    }

    if ($null -eq $CurrentValue -or $CurrentValue -eq '<RemoveEntry>') {
        return $false
    }

    switch ($Type) {
        'DWord' {
            return (ConvertTo-WinUtilRegistryNumericValue -Value $CurrentValue -NumericType 'DWord') -eq `
                (ConvertTo-WinUtilRegistryNumericValue -Value $ExpectedValue -NumericType 'DWord')
        }
        'QWord' {
            return (ConvertTo-WinUtilRegistryNumericValue -Value $CurrentValue -NumericType 'QWord') -eq `
                (ConvertTo-WinUtilRegistryNumericValue -Value $ExpectedValue -NumericType 'QWord')
        }
        default {
            return "$CurrentValue" -eq "$ExpectedValue"
        }
    }
}

function ConvertTo-WinUtilRegistryNumericValue {
    param(
        $Value,
        [ValidateSet('DWord', 'QWord')]
        [string]$NumericType
    )

    if ($null -eq $Value -or $Value -eq '<RemoveEntry>') {
        return $null
    }

    if ($Value -match '^0x[0-9a-fA-F]+$') {
        if ($NumericType -eq 'QWord') {
            return [long]$Value
        }
        return [int]$Value
    }

    if ($Value -match '^-?\d+$') {
        if ($NumericType -eq 'QWord') {
            return [long]$Value
        }
        return [int]$Value
    }

    throw "Invalid $NumericType value '$Value'"
}

function Resolve-WinUtilRegistryEffectiveValue {
    <#
    .SYNOPSIS
        Resolves the effective registry value when the property is absent.
    #>
    param(
        [AllowNull()]
        $CurrentValue,
        $DefaultState,
        $Value,
        $OriginalValue
    )

    if ($null -ne $CurrentValue) {
        return $CurrentValue
    }

    switch ($DefaultState) {
        'true'  { return $Value }
        'false' { return $OriginalValue }
        default { return $OriginalValue }
    }
}