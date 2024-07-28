<#

    .DESCRIPTION
    This script generates markdown files for the development documentation based on the existing JSON files.
    Create table of content.

#>

# Load the JSON files
$tweaks = Get-Content -Path "config/tweaks.json" | ConvertFrom-Json
$features = Get-Content -Path "config/feature.json" | ConvertFrom-Json

# Create the output directories if they don't exist
$tweaksOutputDir = "docs/dev/tweaks"
$featuresOutputDir = "docs/dev/features"

if (-Not (Test-Path -Path $tweaksOutputDir)) {
    New-Item -ItemType Directory -Path $tweaksOutputDir | Out-Null
}

if (-Not (Test-Path -Path $featuresOutputDir)) {
    New-Item -ItemType Directory -Path $featuresOutputDir | Out-Null
}

# Function to generate markdown files
function Generate-MarkdownFiles($data, $outputDir, $jsonFilePath, $type) {
    $tocEntries = @()

    foreach ($itemName in $data.PSObject.Properties.Name) {
        $itemDetails = $data.$itemName
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-' # Sanitize category name for directory
        $categoryDir = "$outputDir/$category"

        # Create the category directory if it doesn't exist
        if (-Not (Test-Path -Path $categoryDir)) {
            New-Item -ItemType Directory -Path $categoryDir | Out-Null
        }

        # Remove "WPF", "WinUtil" prefix and category from the name
        $displayName = $itemName -replace 'WPF', ''
        $displayName = $displayName -replace 'WinUtil', ''
        $displayName = $displayName -replace 'Toggle', ''
        $displayName = $displayName -replace 'Disable', ''
        $displayName = $displayName -replace 'Enable', ''
        $displayName = $displayName -replace $category, ''
        $displayName = $displayName -replace 'Features', ''
        $displayName = $displayName -replace 'Tweaks', ''
        $displayName = $displayName -replace 'Panel', ''
        $displayName = $displayName -replace 'Fixes', ''

        $filename = "$categoryDir/$displayName.md"
        $relativePath = "$outputDir/$category/$displayName.md" -replace '^docs/', ''

        # Collect paths for TOC
        $tocEntries += @{
            Category = $category
            Path = $relativePath
            Name = $displayName
            Type = $type
        }

        # Create the markdown content
        $header = "# $([string]$itemDetails.Content)`n"
        $autoupdatenotice = "
!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**`n`n"
        $description = "## Description`n`n$([string]$itemDetails.Description)`n"
        $jsonContent = $itemDetails | ConvertTo-Json -Depth 10
        $codeBlock = "
<details>
<summary>Preview Code</summary>

``````json`n$jsonContent`n``````
</details>
"
        $InvokeScript = ""
        if ($itemDetails.InvokeScript -ne $null) {
            $InvokeScriptContent = $itemDetails.InvokeScript | Out-String
            $InvokeScript = @"
## Invoke Script

``````json`n$InvokeScriptContent`n``````
"@
        }

        $UndoScript = ""
        if ($itemDetails.UndoScript -ne $null) {
            $UndoScriptContent = $itemDetails.UndoScript | Out-String
            $UndoScript = @"
## Undo Script

``````json`n$UndoScriptContent`n``````
"@
        }

        $registryDocs = ""
        if ($itemDetails.registry -ne $null) {
            $registryDocs += "## Registry Changes`n"
            $registryDocs += "Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.`n`n"
            $registryDocs += "You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).`n"

            foreach ($regEntry in $itemDetails.registry) {
                $registryDocs += "### Registry Key: $($regEntry.Name)`n"
                $registryDocs += "**Type:** $($regEntry.Type)`n`n"
                $registryDocs += "**Original Value:** $($regEntry.OriginalValue)`n`n"
                $registryDocs += "**New Value:** $($regEntry.Value)`n`n"
            }
        }

        $serviceDocs = ""
        if ($itemDetails.service -ne $null) {
            $serviceDocs += "## Service Changes`n"
            $serviceDocs += "Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.`n`n"
            $serviceDocs += "You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).`n"

            foreach ($service in $itemDetails.service) {
                $serviceDocs += "### Service Name: $($service.Name)`n"
                $serviceDocs += "**Startup Type:** $($service.StartupType)`n`n"
                $serviceDocs += "**Original Type:** $($service.OriginalType)`n`n"
            }
        }

        $jsonLink = "`n[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/$jsonFilePath)`n"

        # Check for existing custom content
        $customContentStartTag = "<!-- BEGIN CUSTOM CONTENT -->"
        $customContentEndTag = "<!-- END CUSTOM CONTENT -->"
        $secondCustomContentStartTag = "<!-- BEGIN SECOND CUSTOM CONTENT -->"
        $secondCustomContentEndTag = "<!-- END SECOND CUSTOM CONTENT -->"
        $customContent = ""
        $secondCustomContent = ""
        if (Test-Path -Path $filename) {
            $existingContent = Get-Content -Path $filename -Raw
            $customContentPattern = "(?s)$customContentStartTag(.*?)$customContentEndTag"
            $secondCustomContentPattern = "(?s)$secondCustomContentStartTag(.*?)$secondCustomContentEndTag"
            if ($existingContent -match $customContentPattern) {
                $customContent = $matches[1].Trim()
            }
            if ($existingContent -match $secondCustomContentPattern) {
                $secondCustomContent = $matches[1].Trim()
            }
        }

        # Write to the markdown file
        Set-Content -Path $filename -Value $header -Encoding utf8
        Add-Content -Path $filename -Value $autoupdatenotice -Encoding utf8
        if ($itemDetails.Description) {
            Add-Content -Path $filename -Value $description -Encoding utf8
        }
        Add-Content -Path $filename -Value $customContentStartTag -Encoding utf8
        Add-Content -Path $filename -Value $customContent -Encoding utf8
        Add-Content -Path $filename -Value $customContentEndTag -Encoding utf8
        Add-Content -Path $filename -Value $codeBlock -Encoding utf8
        if ($itemDetails.InvokeScript) {
            Add-Content -Path $filename -Value $InvokeScript -Encoding utf8
        }
        if ($itemDetails.UndoScript) {
            Add-Content -Path $filename -Value $UndoScript -Encoding utf8
        }
        if ($itemDetails.registry) {
            Add-Content -Path $filename -Value $registryDocs -Encoding utf8
        }
        if ($itemDetails.service) {
            Add-Content -Path $filename -Value $serviceDocs -Encoding utf8
        }
        Add-Content -Path $filename -Value $secondCustomContentStartTag -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContent -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContentEndTag -Encoding utf8
        Add-Content -Path $filename -Value $jsonLink -Encoding utf8
    }

    return $tocEntries
}

# Generate markdown files for tweaks and features and collect TOC entries
$tweakTocEntries = Generate-MarkdownFiles -data $tweaks -outputDir $tweaksOutputDir -jsonFilePath "config/tweaks.json" -type "tweak"
$featureTocEntries = Generate-MarkdownFiles -data $features -outputDir $featuresOutputDir -jsonFilePath "config/feature.json" -type "feature"

# Combine TOC entries and group by type and category
$allTocEntries = $tweakTocEntries + $featureTocEntries
$tweakEntries = $allTocEntries | Where-Object { $_.Type -eq 'tweak' } | Sort-Object Category, Name
$featureEntries = $allTocEntries | Where-Object { $_.Type -eq 'feature' } | Sort-Object Category, Name

# Function to generate the content for each type section
function Generate-TypeSectionContent($entries) {
    $sectionContent = ""
    $categories = @{}
    foreach ($entry in $entries) {
        if (-Not $categories.ContainsKey($entry.Category)) {
            $categories[$entry.Category] = @()
        }
        $categories[$entry.Category] += $entry
    }
    foreach ($category in $categories.Keys) {
        $sectionContent += "### $category`n`n"
        foreach ($entry in $categories[$category]) {
            $sectionContent += "- [$($entry.Name)]($($entry.Path))`n"
        }
    }
    return $sectionContent
}

# Generate the devdocs.md content
$indexContent = "# Table of Contents`n`n"

# Add tweaks section
$indexContent += "## Tweaks`n`n"
$indexContent += Generate-TypeSectionContent $tweakEntries
$indexContent += "`n"

# Add features section
$indexContent += "## Features`n`n"
$indexContent += Generate-TypeSectionContent $featureEntries
$indexContent += "`n"

# Write the devdocs.md file
Set-Content -Path "docs/devdocs.md" -Value $indexContent -Encoding utf8
