<#
    .DESCRIPTION
    Generates Hugo-compatible markdown files for the development documentation
    based on config/tweaks.json and config/feature.json.
    Each JSON entry gets its own .md file with the raw JSON snippet or PowerShell function embedded.
    Called by the GitHub Actions docs workflow before Hugo build.
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
    <#
        .SYNOPSIS
        Extracts the raw JSON text for a specific item from a JSON file's lines.
        Returns the line number and raw text, excluding the "link" property and closing brace.
    #>
    param (
        [Parameter(Mandatory)]
        [string]$ItemName,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$JsonLines
    )

    $escapedName = [regex]::Escape($ItemName)
    $startIndex = -1
    $startIndent = ""

    # Find the line containing "ItemName": {
    for ($i = 0; $i -lt $JsonLines.Count; $i++) {
        if ($JsonLines[$i] -match "^(\s*)`"$escapedName`"\s*:\s*\{") {
            $startIndex = $i
            $startIndent = $matches[1]
            break
        }
    }

    if ($startIndex -eq -1) {
        Write-Warning "Could not find '$ItemName' in JSON"
        return $null
    }

    # Find the closing } at the same indentation level
    $escapedIndent = [regex]::Escape($startIndent)
    $endIndex = -1
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

    # Walk backwards from closing brace to exclude "link" property and empty lines
    $lastContentIndex = $endIndex - 1
    while ($lastContentIndex -gt $startIndex) {
        $trimmed = $JsonLines[$lastContentIndex].Trim()
        if ($trimmed -eq "" -or $trimmed -match '^"link"') {
            $lastContentIndex--
        } else {
            break
        }
    }

    $rawLines = $JsonLines[$startIndex..$lastContentIndex]
    $rawText = $rawLines -join "`r`n"

    return @{
        LineNumber = $startIndex + 1  # 1-based
        RawText    = $rawText
    }
}

function Get-ButtonFunctionMapping {
    <#
        .SYNOPSIS
        Parses Invoke-WPFButton.ps1 to build a hashtable mapping button names to function names.
    #>
    param (
        [Parameter(Mandatory)]
        [string]$ButtonFilePath
    )

    $mapping = @{}
    $lines = Get-Content -Path $ButtonFilePath
    foreach ($line in $lines) {
        if ($line -match '^\s*"(\w+)"\s*\{(Invoke-\w+)') {
            $mapping[$matches[1]] = $matches[2]
        }
    }
    return $mapping
}

function Add-LinkAttributeToJson {
    <#
        .SYNOPSIS
        Updates the "link" property on each top-level entry in a JSON config file
        to point to the corresponding documentation page URL.
    #>
    param (
        [Parameter(Mandatory)]
        [string]$JsonFilePath,
        [Parameter(Mandatory)]
        [string]$UrlPrefix,
        [Parameter(Mandatory)]
        [string]$ItemNameToCut
    )

    $jsonText = Get-Content -Path $JsonFilePath -Raw
    $jsonData = $jsonText | ConvertFrom-Json

    foreach ($item in $jsonData.PSObject.Properties) {
        $itemName = $item.Name
        $itemDetails = $item.Value
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-'
        $displayName = $itemName -replace $ItemNameToCut, ''
        $docLink = "$UrlPrefix/$($category.ToLower())/$($displayName.ToLower())"

        $itemDetails | Add-Member -NotePropertyName "link" -NotePropertyValue $docLink -Force
    }

    $jsonText = ($jsonData | ConvertTo-Json -Depth 100).replace('\n', "`n").replace('\r', "`r")
    Set-Content -Path $JsonFilePath -Value $jsonText -Encoding utf8
}

# ==============================================================================
# Main Script
# ==============================================================================

# Use PSScriptRoot if available (running as a script file), otherwise assume CWD is tools/
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$repoRoot = Resolve-Path "$scriptDir/.."

# Paths
$tweaksJsonPath    = "$repoRoot/config/tweaks.json"
$featuresJsonPath  = "$repoRoot/config/feature.json"
$tweaksOutputDir   = "$repoRoot/docs/content/dev/tweaks"
$featuresOutputDir = "$repoRoot/docs/content/dev/features"
$publicFunctionsDir  = "$repoRoot/functions/public"
$privateFunctionsDir = "$repoRoot/functions/private"

$itemnametocut = 'WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?'
$baseUrl = "https://winutil.christitus.com"

# Categories that should have generated documentation
$documentedCategories = @(
    "Essential Tweaks",
    "z__Advanced Tweaks - CAUTION",
    "Customize Preferences",
    "Performance Plans",
    "Features",
    "Fixes",
    "Legacy Windows Panels"
)

# --- Load data ---

Update-Progress "Loading JSON files" 10
$tweaks   = Get-Content -Path $tweaksJsonPath  -Raw | ConvertFrom-Json
$features = Get-Content -Path $featuresJsonPath -Raw | ConvertFrom-Json

# --- Load function files (content + relative path) ---

Update-Progress "Loading function files" 20
$functionFiles = @{}
Get-ChildItem -Path $publicFunctionsDir -Filter *.ps1 | ForEach-Object {
    $functionFiles[$_.BaseName] = @{
        Content      = (Get-Content -Path $_.FullName -Raw).TrimEnd()
        RelativePath = "functions/public/$($_.Name)"
    }
}
Get-ChildItem -Path $privateFunctionsDir -Filter *.ps1 | ForEach-Object {
    $functionFiles[$_.BaseName] = @{
        Content      = (Get-Content -Path $_.FullName -Raw).TrimEnd()
        RelativePath = "functions/private/$($_.Name)"
    }
}

# --- Build button-to-function mapping ---

Update-Progress "Building button-to-function mapping" 30
$buttonFunctionMap = Get-ButtonFunctionMapping -ButtonFilePath "$publicFunctionsDir/Invoke-WPFButton.ps1"

# --- Update link attributes in JSON files ---

Update-Progress "Updating documentation links in JSON" 40
Add-LinkAttributeToJson -JsonFilePath $tweaksJsonPath   -UrlPrefix "$baseUrl/dev/tweaks"   -ItemNameToCut $itemnametocut
Add-LinkAttributeToJson -JsonFilePath $featuresJsonPath  -UrlPrefix "$baseUrl/dev/features" -ItemNameToCut $itemnametocut

# Reload JSON lines after link update (so line numbers are accurate)
$tweaksLines   = Get-Content -Path $tweaksJsonPath
$featuresLines = Get-Content -Path $featuresJsonPath

# ==============================================================================
# Clean up old generated .md files (keep _index.md)
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

$tweakNames = $tweaks.PSObject.Properties.Name
$totalTweaks = $tweakNames.Count
$tweakCount = 0

foreach ($itemName in $tweakNames) {
    $item = $tweaks.$itemName
    $tweakCount++

    if ($item.category -notin $documentedCategories) { continue }

    $category    = $item.category -replace '[^a-zA-Z0-9]', '-'
    $displayName = $itemName -replace $itemnametocut, ''
    $categoryDir = "$tweaksOutputDir/$category"
    $filename    = "$categoryDir/$displayName.md"

    if (-Not (Test-Path -Path $categoryDir)) {
        New-Item -ItemType Directory -Path $categoryDir | Out-Null
    }

    # Hugo frontmatter
    $title = $item.Content -replace '"', '\"'
    $content = "---`r`ntitle: `"$title`"`r`ndescription: `"`"`r`n---`r`n"

    if ($item.Type -eq "Button") {
        # Button-type tweak: embed the mapped PowerShell function
        $funcName = $buttonFunctionMap[$itemName]
        if ($funcName -and $functionFiles.ContainsKey($funcName)) {
            $func = $functionFiles[$funcName]
            $content += "``````powershell {filename=`"$($func.RelativePath)`",linenos=inline,linenostart=1}`r`n"
            $content += $func.Content + "`r`n"
            $content += "```````r`n"
        }
    } else {
        # Standard tweak: embed raw JSON block
        $jsonBlock = Get-RawJsonBlock -ItemName $itemName -JsonLines $tweaksLines
        if ($jsonBlock) {
            $content += "``````json {filename=`"config/tweaks.json`",linenos=inline,linenostart=$($jsonBlock.LineNumber)}`r`n"
            $content += $jsonBlock.RawText + "`r`n"
            $content += "```````r`n"
        }

        # Registry Changes section
        if ($item.registry) {
            $content += "`r`n## Registry Changes`r`n`r`n"
            $content += "Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.`r`n`r`n"
            $content += "You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).`r`n"
        }

        # Service function reference
        if ($item.service -and $functionFiles.ContainsKey("Set-WinUtilService")) {
            $svcFunc = $functionFiles["Set-WinUtilService"]
            $content += "#Function`r`n"
            $content += "``````powershell {filename=`"$($svcFunc.RelativePath)`",linenos=inline,linenostart=1}`r`n"
            $content += $svcFunc.Content + "`r`n"
            $content += "```````r`n"
        }
    }

    Set-Content -Path $filename -Value $content -Encoding utf8 -NoNewline

    $percent = 50 + [int](($tweakCount / $totalTweaks) * 20)
    if ($percent -gt 70) { $percent = 70 }
    Update-Progress "Generating tweak documentation ($tweakCount/$totalTweaks)" $percent
}

# ==============================================================================
# Generate Feature Documentation
# ==============================================================================

Update-Progress "Generating feature documentation" 70

$featureNames = $features.PSObject.Properties.Name
$totalFeatures = $featureNames.Count
$featureCount = 0

foreach ($itemName in $featureNames) {
    $item = $features.$itemName
    $featureCount++

    if ($item.category -notin $documentedCategories) { continue }

    # Skip pure UI buttons that don't need docs
    if ($itemName -eq "WPFFeatureInstall") { continue }

    $category    = $item.category -replace '[^a-zA-Z0-9]', '-'
    $displayName = $itemName -replace $itemnametocut, ''
    $categoryDir = "$featuresOutputDir/$category"
    $filename    = "$categoryDir/$displayName.md"

    if (-Not (Test-Path -Path $categoryDir)) {
        New-Item -ItemType Directory -Path $categoryDir | Out-Null
    }

    $title = $item.Content -replace '"', '\"'
    $content = "---`r`ntitle: `"$title`"`r`ndescription: `"`"`r`n---`r`n"

    if ($item.category -eq "Fixes" -or $item.category -eq "Legacy Windows Panels") {
        # Embed the PowerShell function file
        $funcName = $buttonFunctionMap[$itemName]
        if ($funcName -and $functionFiles.ContainsKey($funcName)) {
            $func = $functionFiles[$funcName]
            $content += "``````powershell {filename=`"$($func.RelativePath)`",linenos=inline,linenostart=1}`r`n"
            $content += $func.Content + "`r`n"
            $content += "```````r`n"
        }
    } else {
        # Features category: embed raw JSON block
        $jsonBlock = Get-RawJsonBlock -ItemName $itemName -JsonLines $featuresLines
        if ($jsonBlock) {
            $content += "``````json {filename=`"config/feature.json`",linenos=inline,linenostart=$($jsonBlock.LineNumber)}`r`n"
            $content += $jsonBlock.RawText + "`r`n"
            $content += "```````r`n"
        }
    }

    Set-Content -Path $filename -Value $content -Encoding utf8 -NoNewline

    $percent = 70 + [int](($featureCount / $totalFeatures) * 20)
    if ($percent -gt 90) { $percent = 90 }
    Update-Progress "Generating feature documentation ($featureCount/$totalFeatures)" $percent
}

Update-Progress "Process Completed" 100
Write-Host "Documentation generation complete."
