function Get-WinUtilTweakDisplayName {
    <#
        .SYNOPSIS
            Returns the user-facing label for a tweak key

        .DESCRIPTION
            Status text should read the way the checkbox does ("Activity
            History - Disable"), not the preset key ("WPFTweaksActivity"). Falls
            back to the key itself when configs are unavailable (headless runs,
            tests) or the entry has no label, so callers need no existence
            checks. Pure data lookup, safe to call from a job worker.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )

    $entry = $null
    if ($null -ne $sync -and $null -ne $sync.configs -and $null -ne $sync.configs.tweaks) {
        $entry = $sync.configs.tweaks.$Key
    }

    if ($null -ne $entry -and -not [string]::IsNullOrWhiteSpace($entry.Content)) {
        return $entry.Content
    }

    return $Key
}
