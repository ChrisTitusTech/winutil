function Get-AppCategories {
    <#
    .SYNOPSIS
        Gets all unique application categories for navigation.

    .DESCRIPTION
        Extracts all unique categories from the applications configuration and returns them sorted.

    .OUTPUTS
        Array of unique category names
    #>

    $categories = @()

    # Extract categories from applications hashtable
    if ($sync.configs.applicationsHashtable) {
        $categories = $sync.configs.applicationsHashtable.Values |
            ForEach-Object { $_.category } |
            Sort-Object |
            Get-Unique
    }

    return $categories
}
