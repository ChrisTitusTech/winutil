$inputPath = "$1"
$outputPath = "$2"
$json = Get-Content $inputPath -Raw | ConvertFrom-Json
$sorted = [ordered]@{}

foreach ($key in ($json.PSObject.Properties.Name | Sort-Object)) {
    $sorted[$key] = $json.$key
}

$sortedJson = $sorted | ConvertTo-Json -Depth 10
$sortedJson | Out-File $outputPath -Encoding UTF8
Write-Host "JSON sorted and saved to '$outputPath'."
