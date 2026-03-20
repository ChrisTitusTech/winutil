<#
    .DESCRIPTION
    Generates Hugo markdown docs from config/tweaks.json and config/feature.json.
    Run by the GitHub Actions docs workflow before Hugo build.
#>

function Update-Progress {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$StatusMessage,
        [Parameter(Mandatory, position=1)]
        [ValidateRange(0,100)]
        [int]$Percent
    )
    Write-Progress -Activity "Generating Dev Docs" -Status $StatusMessage -PercentComplete $Percent
}

function Get-RawJsonBlock {
    # Returns the raw JSON text and 1-based start line for an item, excluding the "link" property.
    param (
        [Parameter(Mandatory)]
        [string]$ItemName,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$JsonLines
    )

    $escapedName = [regex]::Escape($ItemName)
    $startIndex  = -1
    $startIndent = ""

    for ($i = 0; $i -lt $JsonLines.Count; $i++) {
        if ($JsonLines[$i] -match "^(\s*)`"$escapedName`"\s*:\s*\{") {
            $startIndex  = $i
            $startIndent = $matches[1]
            break
        }
    }

    if ($startIndex -eq -1) {
        Write-Warning "Could not find '$ItemName' in JSON"
        return $null
    }

    $escapedIndent = [regex]::Escape($startIndent)
    $endIndex      = -1
    for ($i = ($startIndex + 1); $i -lt $JsonLines.Count; $i++) {
        if ($JsonLines[$i] -match "^$escapedIndent\}") {
            $endIndex = $i
            break
        }
    }

    if ($endIndex -eq -1) {
        Write-Warning "Could not find closing brace for '$ItemName'"
        return $null
    }

    # Strip trailing "link" property and blank lines before returning
    $lastContentIndex = $endIndex - 1
    while ($lastContentIndex -gt $startIndex) {
        $trimmed = $JsonLines[$lastContentIndex].Trim()
        if ($trimmed -eq "" -or $trimmed -match '^"link"') {
            $lastContentIndex--
        } else {
            break
        }
    }

    return @{
        LineNumber = $startIndex + 1
        RawText    = ($JsonLines[$startIndex..$lastContentIndex] -join "`r`n")
    }
}

function Get-ButtonFunctionMapping {
    # Parses Invoke-WPFButton.ps1 and returns a hashtable of button name -> function name.
    param (
        [Parameter(Mandatory)]
        [string]$ButtonFilePath
    )

    $mapping = @{}
    foreach ($line in (Get-Content -Path $ButtonFilePath)) {
        if ($line -match '^\s*"(\w+)"\s*\{(Invoke-\w+)') {
            $mapping[$matches[1]] = $matches[2]
        }
    }
    return $mapping
}

function Add-LinkAttributeToJson {
    # Updates only the "link" property for each entry in a JSON config file.
    # Reads via ConvertFrom-Json for metadata, then edits lines directly to avoid reformatting.
    param (
        [Parameter(Mandatory)]
        [string]$JsonFilePath,
        [Parameter(Mandatory)]
        [string]$UrlPrefix,
        [Parameter(Mandatory)]
        [string]$ItemNameToCut
    )

    $jsonData = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json
    $lines    = [System.Collections.Generic.List[string]](Get-Content -Path $JsonFilePath)

    foreach ($item in $jsonData.PSObject.Properties) {
        $itemName    = $item.Name
        $category    = $item.Value.category -replace '[^a-zA-Z0-9]', '-'
        $displayName = $itemName -replace $ItemNameToCut, ''
        $newLink     = "$UrlPrefix/$($category.ToLower())/$($displayName.ToLower())"
        $escapedName = [regex]::Escape($itemName)

        # Find item start line
        $startIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^\s*`"$escapedName`"\s*:\s*\{") {
                $startIdx = $i
                break
            }
        }
        if ($startIdx -eq -1) { continue }

        # Derive indentation: propIndent is one level deeper than the item start.
        # Used to target only top-level properties and skip nested object braces.
        $null          = $lines[$startIdx] -match '^(\s*)'
        $propIndent    = $matches[1] + '  '
        $propIndentLen = $propIndent.Length
        $escapedPropIndent = [regex]::Escape($propIndent)

        # Scan forward: update existing "link" or find the closing brace to insert one.
        # Closing brace is matched by indent <= propIndentLen to handle inconsistent formatting.
        $linkUpdated   = $false
        $closeBraceIdx = -1
        for ($j = $startIdx + 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match "^$escapedPropIndent`"link`"\s*:") {
                $lines[$j] = $lines[$j] -replace '"link"\s*:\s*"[^"]*"', "`"link`": `"$newLink`""
                $linkUpdated = $true
                break
            }
            if ($lines[$j] -match '^\s*\}') {
                $null = $lines[$j] -match '^(\s*)'
                if ($matches[1].Length -le $propIndentLen) {
                    $closeBraceIdx = $j
                    break
                }
            }
        }

        if (-not $linkUpdated -and $closeBraceIdx -ne -1) {
            # Insert "link" before the closing brace
            $prevPropIdx = $closeBraceIdx - 1
            while ($prevPropIdx -gt $startIdx -and $lines[$prevPropIdx].Trim() -eq '') { $prevPropIdx-- }

            if ($lines[$prevPropIdx] -notmatch ',\s*$') {
                $lines[$prevPropIdx] = $lines[$prevPropIdx].TrimEnd() + ','
            }
            $lines.Insert($closeBraceIdx, "$propIndent`"link`": `"$newLink`"")
        }
    }

    Set-Content -Path $JsonFilePath -Value $lines -Encoding utf8
}

# ==============================================================================
# Main
# ==============================================================================

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$repoRoot  = Resolve-Path "$scriptDir/.."

$tweaksJsonPath      = "$repoRoot/config/tweaks.json"
$featuresJsonPath    = "$repoRoot/config/feature.json"
$tweaksOutputDir     = "$repoRoot/docs/content/dev/tweaks"
$featuresOutputDir   = "$repoRoot/docs/content/dev/features"
$publicFunctionsDir  = "$repoRoot/functions/public"
$privateFunctionsDir = "$repoRoot/functions/private"

$itemnametocut = 'WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?'
$baseUrl       = "https://winutil.christitus.com"

# Categories with generated docs
$documentedCategories = @(
    "Essential Tweaks",
    "z__Advanced Tweaks - CAUTION",
    "Customize Preferences",
    "Performance Plans",
    "Features",
    "Fixes",
    "Legacy Windows Panels",
    "Powershell Profile Powershell 7+ Only",
    "Remote Access"
)

# Categories where Button entries embed a PS function instead of raw JSON
$functionEmbedCategories = @(
    "Fixes",
    "Powershell Profile Powershell 7+ Only",
    "Remote Access"
)

Update-Progress "Loading JSON files" 10
$tweaks   = Get-Content -Path $tweaksJsonPath   -Raw | ConvertFrom-Json
$features = Get-Content -Path $featuresJsonPath -Raw | ConvertFrom-Json

Update-Progress "Loading function files" 20
$functionFiles = @{}
Get-ChildItem -Path $publicFunctionsDir  -Filter *.ps1 | ForEach-Object {
    $functionFiles[$_.BaseName] = @{ Content = (Get-Content -Path $_.FullName -Raw).TrimEnd(); RelativePath = "functions/public/$($_.Name)" }
}
Get-ChildItem -Path $privateFunctionsDir -Filter *.ps1 | ForEach-Object {
    $functionFiles[$_.BaseName] = @{ Content = (Get-Content -Path $_.FullName -Raw).TrimEnd(); RelativePath = "functions/private/$($_.Name)" }
}

Update-Progress "Building button-to-function mapping" 30
$buttonFunctionMap = Get-ButtonFunctionMapping -ButtonFilePath "$publicFunctionsDir/Invoke-WPFButton.ps1"

Update-Progress "Updating documentation links in JSON" 40
Add-LinkAttributeToJson -JsonFilePath $tweaksJsonPath   -UrlPrefix "$baseUrl/dev/tweaks"   -ItemNameToCut $itemnametocut
Add-LinkAttributeToJson -JsonFilePath $featuresJsonPath -UrlPrefix "$baseUrl/dev/features" -ItemNameToCut $itemnametocut

# Reload lines after link update so line numbers in docs are accurate
$tweaksLines   = Get-Content -Path $tweaksJsonPath
$featuresLines = Get-Content -Path $featuresJsonPath

# ==============================================================================
# Clean up old generated .md files (preserve _index.md)
# ==============================================================================

Update-Progress "Cleaning up old generated docs" 45
foreach ($dir in @($tweaksOutputDir, $featuresOutputDir)) {
    Get-ChildItem -Path $dir -Recurse -Filter *.md | Where-Object {
        $_.Name -ne "_index.md"
    } | Remove-Item -Force
}

# ==============================================================================
# Generate Tweak Documentation
# ==============================================================================

Update-Progress "Generating tweak documentation" 50

$tweakNames  = $tweaks.PSObject.Properties.Name
$totalTweaks = $tweakNames.Count
$tweakCount  = 0

foreach ($itemName in $tweakNames) {
    $item = $tweaks.$itemName
    $tweakCount++

    if ($item.category -notin $documentedCategories) { continue }

    $category    = $item.category -replace '[^a-zA-Z0-9]', '-'
    $displayName = $itemName -replace $itemnametocut, ''
    $categoryDir = "$tweaksOutputDir/$category"
    $filename    = "$categoryDir/$displayName.md"

    if (-Not (Test-Path -Path $categoryDir)) { New-Item -ItemType Directory -Path $categoryDir | Out-Null }

    $title   = $item.Content -replace '"', '\"'
    $content = "---`r`ntitle: `"$title`"`r`ndescription: `"`"`r`n---`r`n`r`n"

    if ($item.Type -eq "Button") {
        $funcName = $buttonFunctionMap[$itemName]
        if ($funcName -and $functionFiles.ContainsKey($funcName)) {
            $func     = $functionFiles[$funcName]
            $content += "``````powershell {filename=`"$($func.RelativePath)`",linenos=inline,linenostart=1}`r`n"
            $content += $func.Content + "`r`n"
            $content += "```````r`n"
        }
    } else {
        $jsonBlock = Get-RawJsonBlock -ItemName $itemName -JsonLines $tweaksLines
        if ($jsonBlock) {
            $content += "``````json {filename=`"config/tweaks.json`",linenos=inline,linenostart=$($jsonBlock.LineNumber)}`r`n"
            $content += $jsonBlock.RawText + "`r`n"
            $content += "```````r`n"
        }

        if ($item.registry) {
            $content += "`r`n## Registry Changes`r`n`r`n"
            $content += "Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.`r`n`r`n"
            $content += "You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).`r`n"
        }
    }

    Set-Content -Path $filename -Value $content -Encoding utf8 -NoNewline

    $percent = [Math]::Min(70, 50 + [int](($tweakCount / $totalTweaks) * 20))
    Update-Progress "Generating tweak documentation ($tweakCount/$totalTweaks)" $percent
}

# ==============================================================================
# Generate Feature Documentation
# ==============================================================================

Update-Progress "Generating feature documentation" 70

$featureNames  = $features.PSObject.Properties.Name
$totalFeatures = $featureNames.Count
$featureCount  = 0

foreach ($itemName in $featureNames) {
    $item = $features.$itemName
    $featureCount++

    if ($item.category -notin $documentedCategories) { continue }
    if ($itemName -eq "WPFFeatureInstall") { continue }

    $category    = $item.category -replace '[^a-zA-Z0-9]', '-'
    $displayName = $itemName -replace $itemnametocut, ''
    $categoryDir = "$featuresOutputDir/$category"
    $filename    = "$categoryDir/$displayName.md"

    if (-Not (Test-Path -Path $categoryDir)) { New-Item -ItemType Directory -Path $categoryDir | Out-Null }

    $title   = $item.Content -replace '"', '\"'
    $content = "---`r`ntitle: `"$title`"`r`ndescription: `"`"`r`n---`r`n`r`n"

    if ($item.category -in $functionEmbedCategories) {
        $funcName = if ($item.function) { $item.function } else { $buttonFunctionMap[$itemName] }
        if ($funcName -and $functionFiles.ContainsKey($funcName)) {
            $func     = $functionFiles[$funcName]
            $content += "``````powershell {filename=`"$($func.RelativePath)`",linenos=inline,linenostart=1}`r`n"
            $content += $func.Content + "`r`n"
            $content += "```````r`n"
        }
    } else {
        $jsonBlock = Get-RawJsonBlock -ItemName $itemName -JsonLines $featuresLines
        if ($jsonBlock) {
            $content += "``````json {filename=`"config/feature.json`",linenos=inline,linenostart=$($jsonBlock.LineNumber)}`r`n"
            $content += $jsonBlock.RawText + "`r`n"
            $content += "```````r`n"
        }
    }

    Set-Content -Path $filename -Value $content -Encoding utf8 -NoNewline

    $percent = [Math]::Min(90, 70 + [int](($featureCount / $totalFeatures) * 20))
    Update-Progress "Generating feature documentation ($featureCount/$totalFeatures)" $percent
}

Update-Progress "Process Completed" 100
Write-Host "Documentation generation complete."
