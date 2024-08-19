function Get-WPFObjectName {
    <#
        .SYNOPSIS
            This is a helper function that generates an objectname with the prefix WPF that can be used as a Powershell Variable after compilation.
            To achieve this, all characters that are not a-z, A-Z or 0-9 are simply removed from the name.

        .PARAMETER type
            The type of object for which the name should be generated. (e.g. Label, Button, CheckBox...)

        .PARAMETER name
            The name or description to be used for the object. (invalid characters are removed)

        .OUTPUTS
            A string that can be used as a object/variable name in powershell.
            For example: WPFLabelMicrosoftTools

        .EXAMPLE
            Get-WPFObjectName -type Label -name "Microsoft Tools"
    #>

    param(
        [Parameter(Mandatory, position=0)]
        [string]$type,

        [Parameter(position=1)]
        [string]$name
    )

    $Output = $("WPF"+$type+$name) -replace '[^a-zA-Z0-9]', ''
    return $Output
}
