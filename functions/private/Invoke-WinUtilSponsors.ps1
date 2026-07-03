Function Invoke-WinUtilSponsors {
    $sponsors = ([regex]::Matches(([regex]::Match((Invoke-RestMethod https://github.com/sponsors/ChrisTitusTech),'(?s)(?<=Current sponsors).*?(?=Past sponsors)')).Value,'(?<=alt="@)[^"]+')).Value | Where-Object {$_ -ne "ChrisTitusTech"}
    return $sponsors
}
