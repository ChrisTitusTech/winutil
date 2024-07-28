<#

    .DESCRIPTION
    This script generates markdown files for the development documentation based on the existing JSON files.

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
function Generate-MarkdownFiles($data, $outputDir, $jsonFilePath) {
    foreach ($itemName in $data.PSObject.Properties.Name) {
        $itemDetails = $data.$itemName
        $filename = "$outputDir/$itemName.md"

        # Create the markdown content
        $header = "# $([string]$itemDetails.Content)`n"
        $autoupdatenotice = "
!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**`n`n"
        $description = "## Description`n`n$([string]$itemDetails.Description)`n"
        $jsonContent = $itemDetails | ConvertTo-Json -Depth 10
        $codeBlock = "
<details>
<summary>Preview Code</summary>

``````json`n$jsonContent`n``````
</details>
"
        $registryDocs = ""
        if ($itemDetails.registry -ne $null) {
            $registryDocs += "## Registry Changes`n"
            $registryDocs += "Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.`n`n"
            $registryDocs += "You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).`n"
            $registryDocs += "### Walkthrough.`n"

            foreach ($regEntry in $itemDetails.registry) {
                $registryDocs += "#### Registry Key: $($regEntry.Name)`n"
                $registryDocs += "**Path:** $($regEntry.Path)`n`n"
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
            $registryDocs += "### Walkthrough.`n"

            foreach ($service in $itemDetails.service) {
                $serviceDocs += "#### Service Name: $($service.Name)`n"
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
        Add-Content -Path $filename -Value $description -Encoding utf8
        Add-Content -Path $filename -Value $customContentStartTag -Encoding utf8
        Add-Content -Path $filename -Value $customContent -Encoding utf8
        Add-Content -Path $filename -Value $customContentEndTag -Encoding utf8
        Add-Content -Path $filename -Value $codeBlock -Encoding utf8
        Add-Content -Path $filename -Value $registryDocs -Encoding utf8
        Add-Content -Path $filename -Value $serviceDocs -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContentStartTag -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContent -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContentEndTag -Encoding utf8
        Add-Content -Path $filename -Value $jsonLink -Encoding utf8
    }
}

# Generate markdown files for tweaks
Generate-MarkdownFiles -data $tweaks -outputDir $tweaksOutputDir -jsonFilePath "config/tweaks.json"

# Generate markdown files for features
Generate-MarkdownFiles -data $features -outputDir $featuresOutputDir -jsonFilePath "config/feature.json"
