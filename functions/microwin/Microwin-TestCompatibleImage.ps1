function Microwin-TestCompatibleImage() {
    <#
        .SYNOPSIS
            Checks the version of a Windows image and determines whether or not it is compatible with a specific feature depending on a desired version

        .PARAMETER Name
            imgVersion - The version of the Windows image
            desiredVersion - The version to compare the image version with
    #>

    param
    (
    [Parameter(Mandatory, position=0)]
    [string]$imgVersion,

    [Parameter(Mandatory, position=1)]
    [Version]$desiredVersion
    )

    try {
        $version = [Version]$imgVersion
        return $version -ge $desiredVersion
    } catch {
        return $False
    }
}
