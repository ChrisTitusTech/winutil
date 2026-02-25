function Compose-Config {
    <#
        .SYNOPSIS
        A function that combines multiple .json files into a single object. Intended to join many seperate config files.

        .Parameter Directory
        Directory to find the .json files in

        .PARAMETER Excluded
        A list of files/folders to not add to combined object.
    #>

    param (
        [string]$Directory,
        [array]$ExcludedFiles
    )

    $fullJsonAsObject = [PSCustomObject]@{}

    Get-ChildItem $Directory -Recurse -Exclude $ExcludedFiles | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
        $json = (Get-Content $psitem.FullName -Raw)
        $jsonAsObject = $json | ConvertFrom-Json

        # Add 'WPFInstall' as a prefix to every entry-name in 'applications' folder
        if ($Directory -eq "config\applications") {
            foreach ($appEntryName in $jsonAsObject.PSObject.Properties.Name) {
                $appEntryContent = $jsonAsObject.$appEntryName
                $jsonAsObject.PSObject.Properties.Remove($appEntryName)
                $jsonAsObject | Add-Member -MemberType NoteProperty -Name "WPFInstall$appEntryName" -Value $appEntryContent
            }
        }

        foreach ($item in $jsonAsObject.PSObject.Properties) {
            $fullJsonAsObject | Add-Member -Name $item.Name -Value $item.Value -MemberType $item.MemberType
        }
    }

    # Lines below require no whitespace inside the here-strings, to keep formatting of the JSON in the final script.
    $finalJson = @"
$($fullJsonAsObject | ConvertTo-Json -Depth 3)
"@
    return $finalJson
}
