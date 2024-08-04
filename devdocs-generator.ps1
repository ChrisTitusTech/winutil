<#
    .DESCRIPTION
    This script generates markdown files for the development documentation based on the existing JSON files.
    Create table of content and archive any files in the dev folder not modified by this script.
    This script is not meant to be used manually, it is called by the github action workflow.
#>

function Update-Progress {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$StatusMessage,

	[Parameter(Mandatory, position=1)]
	[ValidateRange(0,100)]
        [int]$Percent,

	[Parameter(position=2)]
	[string]$Activity = "Compiling"
    )

    Write-Progress -Activity $Activity -Status $StatusMessage -PercentComplete $Percent
}

Update-Progress "Pre-req: Load JSON files" 1

# Load the JSON files
$tweaks = Get-Content -Path "config/tweaks.json" | ConvertFrom-Json
$features = Get-Content -Path "config/feature.json" | ConvertFrom-Json

Update-Progress "Pre-req: Get last modified dates of the JSON files" 10

# Get the last modified dates of the JSON files
$tweaksLastModified = (Get-Item "config/tweaks.json").LastWriteTime.ToString("yyyy-MM-dd") #  For more detail add " HH:mm:ss zzz"
$featuresLastModified = (Get-Item "config/feature.json").LastWriteTime.ToString("yyyy-MM-dd")

# Create the output directories if they don't exist
$tweaksOutputDir = "docs/dev/tweaks"
$featuresOutputDir = "docs/dev/features"
$archiveDir = "docs/archive"

# Load functions from private and public directories
$privateFunctionsDir = "functions/private"
$publicFunctionsDir = "functions/public"
$functions = @{}

$itemnametocut = "WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)"

Update-Progress "Pre-req: create Directories" 20

if (-Not (Test-Path -Path $tweaksOutputDir)) {
    New-Item -ItemType Directory -Path $tweaksOutputDir | Out-Null
}

if (-Not (Test-Path -Path $featuresOutputDir)) {
    New-Item -ItemType Directory -Path $featuresOutputDir | Out-Null
}

if (-Not (Test-Path -Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

Update-Progress "Pre-req: Load existing Functions" 30

function Load-Functions($dir) {
    Get-ChildItem -Path $dir -Filter *.ps1 | ForEach-Object {
        $functionName = $_.BaseName
        $functionContent = Get-Content -Path $_.FullName -Raw
        $functions[$functionName] = $functionContent
    }
}

Load-Functions -dir $privateFunctionsDir
Load-Functions -dir $publicFunctionsDir

# Function to check if a function is called in a script recursively
function Get-CalledFunctions {
    Param (
        [string]$scriptContent,
        [hashtable]$functionList,
        [ref]$processedFunctions
    )

    $calledFunctions = @()
    foreach ($functionName in $functionList.Keys) {
        if ($scriptContent -match "\b$functionName\b" -and -not $processedFunctions.Value.Contains($functionName)) {
            $calledFunctions += $functionName
            $processedFunctions.Value.Add($functionName)
            if ($functionList[$functionName]) {
                $nestedFunctions = Get-CalledFunctions -scriptContent $functionList[$functionName] -functionList $functionList -processedFunctions $processedFunctions
                $calledFunctions += $nestedFunctions
            }
        }
    }
    return $calledFunctions
}

# Function to get additional functions from Invoke-WPFToggle
function Get-AdditionalFunctionsFromToggle {
    Param ([string]$buttonName)

    $invokeWpfToggleContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFToggle.ps1" -Raw
    $lines = $invokeWpfToggleContent -split "`r`n"
    foreach ($line in $lines) {
        # Match the line with the button name and extract the function name
        if ($line -match "`"$buttonName`" \{Invoke-(WinUtil[a-zA-Z]+)") {
            return $matches[1]  # Return the matched function name
        }
    }
    return $null
}

# Function to get additional functions from Invoke-WPFButton
function Get-AdditionalFunctionsFromButton {
    Param ([string]$buttonName)

    $invokeWpfButtonContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFButton.ps1" -Raw
    $lines = $invokeWpfButtonContent -split "`r`n"
    foreach ($line in $lines) {
        # Match the line with the button name and extract the function name
        if ($line -match "`"$buttonName`" \{Invoke-(WPF[a-zA-Z]+)") {
            return $matches[1]  # Return the matched function name
        }
    }
    return $null
}

# Function to generate markdown files
function Generate-MarkdownFiles($data, $outputDir, $jsonFilePath, $lastModified, $type) {
    $tocEntries = @()
    $processedFiles = @()

    foreach ($itemName in $data.PSObject.Properties.Name) {
        $itemDetails = $data.$itemName
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-' # Sanitize category name for directory
        $categoryDir = "$outputDir/$category"

        # Create the category directory if it doesn't exist
        if (-Not (Test-Path -Path $categoryDir)) {
            New-Item -ItemType Directory -Path $categoryDir | Out-Null
        }

        # Preserve the full name for matching purposes
        $fullItemName = $itemName

        # Remove prefixes from the name for display
        $displayName = $itemName -replace $itemnametocut, ''

        $filename = "$categoryDir/$displayName.md"
        $relativePath = "$outputDir/$category/$displayName.md" -replace '^docs/', ''

        # Ensure the file exists before adding to processed files
        if (-Not (Test-Path -Path $filename)) {
            Set-Content -Path $filename -Value "" -Encoding utf8
        }

        # Collect paths for TOC
        $tocEntries += @{
            Category = $category
            Path = $relativePath
            Name = $itemDetails.Content
            Type = $type
        }

        # Track processed files
        $processedFiles += (Get-Item $filename).FullName

        # Create the markdown content
        $header = "# $([string]$itemDetails.Content)`r`n"
        $lastUpdatedNotice = "Last Updated: $lastModified`r`n"
        $autoupdatenotice = "
!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**`r`n`r`n"
        $description = "## Description`r`n`r`n$([string]$itemDetails.Description)`r`n"
        $jsonContent = ($itemDetails | ConvertTo-Json -Depth 10).replace('\r\n',"`r`n")
        $codeBlock = "
<details>
<summary>Preview Code</summary>

``````json`r`n$jsonContent`r`n``````
</details>
"
        $InvokeScript = ""
        if ($itemDetails.InvokeScript -ne $null) {
            $InvokeScriptContent = $itemDetails.InvokeScript | Out-String
            $InvokeScript = @"
## Invoke Script

``````powershell`r`n$InvokeScriptContent`r`n``````
"@
        }

        $UndoScript = ""
        if ($itemDetails.UndoScript -ne $null) {
            $UndoScriptContent = $itemDetails.UndoScript | Out-String
            $UndoScript = @"
## Undo Script

``````powershell`r`n$UndoScriptContent`r`n``````
"@
        }

        $ToggleScript = ""
        if ($itemDetails.ToggleScript -ne $null) {
            $ToggleScriptContent = $itemDetails.ToggleScript | Out-String
            $ToggleScript = @"
## Toggle Script

``````powershell`r`n$ToggleScriptContent`r`n``````
"@
        }

        $ButtonScript = ""
        if ($itemDetails.ButtonScript -ne $null) {
            $ButtonScriptContent = $itemDetails.ButtonScript | Out-String
            $ButtonScript = @"
## Button Script

``````powershell`r`n$ButtonScriptContent`r`n``````
"@
        }

        $FunctionDetails = ""
        $processedFunctions = New-Object 'System.Collections.Generic.HashSet[System.String]'
        $allScripts = @($itemDetails.InvokeScript, $itemDetails.UndoScript, $itemDetails.ToggleScript, $itemDetails.ButtonScript)
        foreach ($script in $allScripts) {
            if ($script -ne $null) {
                $calledFunctions = Get-CalledFunctions -scriptContent $script -functionList $functions -processedFunctions ([ref]$processedFunctions)
                foreach ($functionName in $calledFunctions) {
                    if ($functions.ContainsKey($functionName)) {
                        $FunctionDetails += "## Function: $functionName`r`n"
                        $FunctionDetails += "``````powershell`r`n$($functions[$functionName])`r`n``````
`r`n"
                    }
                }
            }
        }
        # Check for additional functions from Invoke-WPFToggle
        $additionalFunctionToggle = Get-AdditionalFunctionsFromToggle -buttonName $fullItemName
        if ($additionalFunctionToggle -ne $null) {
            $additionalFunctionNameToggle = "Invoke-$additionalFunctionToggle"
            if ($functions.ContainsKey($additionalFunctionNameToggle) -and -not $processedFunctions.Contains($additionalFunctionNameToggle)) {
                $FunctionDetails += "## Function: $additionalFunctionNameToggle`r`n"
                $FunctionDetails += "``````powershell`r`n$($functions[$additionalFunctionNameToggle])`r`n``````
`r`n"
                $processedFunctions.Add($additionalFunctionNameToggle)
            }
        }

        # Check for additional functions from Invoke-WPFButton
        $additionalFunctionButton = Get-AdditionalFunctionsFromButton -buttonName $fullItemName
        if ($additionalFunctionButton -ne $null) {
            $additionalFunctionNameButton = "Invoke-$additionalFunctionButton"
            if ($functions.ContainsKey($additionalFunctionNameButton) -and -not $processedFunctions.Contains($additionalFunctionNameButton)) {
                $FunctionDetails += "## Function: $additionalFunctionNameButton`r`n"
                $FunctionDetails += "``````powershell`r`n$($functions[$additionalFunctionNameButton])`r`n``````
`r`n"
                $processedFunctions.Add($additionalFunctionNameButton)
            }
        }

        $registryDocs = ""
        if ($itemDetails.registry -ne $null) {
            $registryDocs += "## Registry Changes`r`n"
            $registryDocs += "Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.`r`n`r`n"
            $registryDocs += "You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).`r`n"

            foreach ($regEntry in $itemDetails.registry) {
                $registryDocs += "### Registry Key: $($regEntry.Name)`r`n"
                $registryDocs += "**Type:** $($regEntry.Type)`r`n`r`n"
                $registryDocs += "**Original Value:** $($regEntry.OriginalValue)`r`n`r`n"
                $registryDocs += "**New Value:** $($regEntry.Value)`r`n`r`n"
            }
        }

        $serviceDocs = ""
        if ($itemDetails.service -ne $null) {
            $serviceDocs += "## Service Changes`r`n"
            $serviceDocs += "Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.`r`n`r`n"
            $serviceDocs += "You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).`r`n"

            foreach ($service in $itemDetails.service) {
                $serviceDocs += "### Service Name: $($service.Name)`r`n"
                $serviceDocs += "**Startup Type:** $($service.StartupType)`r`n`r`n"
                $serviceDocs += "**Original Type:** $($service.OriginalType)`r`n`r`n"
            }
        }

        $scheduledTaskDocs = ""
        if ($itemDetails.ScheduledTask -ne $null) {
            $scheduledTaskDocs += "## Scheduled Task Changes`r`n"
            $scheduledTaskDocs += "Windows scheduled tasks are used to run scripts or programs at specific times or events. Disabling unnecessary tasks can improve system performance and reduce unwanted background activity.`r`n`r`n"
            $scheduledTaskDocs += "You can find information about scheduled tasks on [Wikipedia](https://www.wikiwand.com/en/Windows_Task_Scheduler) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/desktop/taskschd/about-the-task-scheduler).`r`n"

            foreach ($task in $itemDetails.ScheduledTask) {
                $scheduledTaskDocs += "### Task Name: $($task.Name)`r`n"
                $scheduledTaskDocs += "**State:** $($task.State)`r`n`r`n"
                $scheduledTaskDocs += "**Original State:** $($task.OriginalState)`r`n`r`n"
            }
        }

        $jsonLink = "`r`n[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/$jsonFilePath)`r`n"

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
        Add-Content -Path $filename -Value $lastUpdatedNotice -Encoding utf8
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
        if ($itemDetails.ToggleScript) {
            Add-Content -Path $filename -Value $ToggleScript -Encoding utf8
        }
        if ($itemDetails.ButtonScript) {
            Add-Content -Path $filename -Value $ButtonScript -Encoding utf8
        }
        if ($FunctionDetails) {
            Add-Content -Path $filename -Value $FunctionDetails -Encoding utf8
        }
        if ($itemDetails.registry) {
            Add-Content -Path $filename -Value $registryDocs -Encoding utf8
        }
        if ($itemDetails.service) {
            Add-Content -Path $filename -Value $serviceDocs -Encoding utf8
        }
        if ($itemDetails.ScheduledTask) {
            Add-Content -Path $filename -Value $scheduledTaskDocs -Encoding utf8
        }
        Add-Content -Path $filename -Value $secondCustomContentStartTag -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContent -Encoding utf8
        Add-Content -Path $filename -Value $secondCustomContentEndTag -Encoding utf8
        Add-Content -Path $filename -Value $jsonLink -Encoding utf8
    }

    return [PSCustomObject]@{
        TocEntries = $tocEntries
        ProcessedFiles = $processedFiles
    }
}

Update-Progress "Generate content for documentation" 20

# Generate markdown files for tweaks and features and collect TOC entries
$tweakResult = Generate-MarkdownFiles -data $tweaks -outputDir $tweaksOutputDir -jsonFilePath "config/tweaks.json" -lastModified $tweaksLastModified -type "tweak"
$featureResult = Generate-MarkdownFiles -data $features -outputDir $featuresOutputDir -jsonFilePath "config/feature.json" -lastModified $featuresLastModified -type "feature"

# Combine TOC entries and group by type and category
$allTocEntries = $tweakResult.TocEntries + $featureResult.TocEntries
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
        $sectionContent += "### $category`r`n`r`n"
        foreach ($entry in $categories[$category]) {
            $sectionContent += "- [$($entry.Name)]($($entry.Path))`r`n"
        }
    }
    return $sectionContent
}

# Generate the devdocs.md content
$indexContent = "# Table of Contents`r`n`r`n"

# Add tweaks section
$indexContent += "## Tweaks`r`n`r`n"
$indexContent += Generate-TypeSectionContent $tweakEntries
$indexContent += "`r`n"

# Add features section
$indexContent += "## Features`r`n`r`n"
$indexContent += Generate-TypeSectionContent $featureEntries
$indexContent += "`r`n"

# Write the devdocs.md file
Set-Content -Path "docs/devdocs.md" -Value $indexContent -Encoding utf8

Update-Progress "Write documentation links to json files" 90

# Function to add or update the link attribute in the JSON file text
function Add-LinkAttributeToJson {
    Param (
        [string]$jsonFilePath,
        [string]$outputDir
    )

    # Read the JSON file as text
    $jsonText = Get-Content -Path $jsonFilePath -Raw

    # Process each item to determine its correct path
    $jsonData = $jsonText | ConvertFrom-Json
    foreach ($item in $jsonData.PSObject.Properties) {
        $itemName = $item.Name
        $itemDetails = $item.Value
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-'
        $displayName = $itemName -replace $itemnametocut, ''
        $relativePath = "$outputDir/$category/$displayName" -replace '^docs/', ''
        $docLink = "https://christitustech.github.io/winutil/$relativePath"

        $jsonData.$itemName.link = $docLink
    }

    # Convert Json Data to Text, so we could write it to `$jsonFilePath`
    $jsonText = ($jsonData | ConvertTo-Json -Depth 10).replace('\r\n',"`r`n")

    # Write the modified text back to the JSON file without empty rows
    Set-Content -Path $jsonFilePath -Value ($jsonText) -Encoding utf8
}

# Add link attribute to tweaks and features JSON files
Add-LinkAttributeToJson -jsonFilePath "config/tweaks.json" -outputDir "dev/tweaks"
Add-LinkAttributeToJson -jsonFilePath "config/feature.json" -outputDir "dev/features"

Update-Progress "Archive unused documentation" 95

# Archive unmodified files
function Archive-UnmodifiedFiles {
    Param (
        [string]$outputDir,
        [array]$processedFiles,
        [string]$archiveDir
    )

    $allFiles = Get-ChildItem -Path $outputDir -Recurse -File
    $processedFilesHashSet = @{}
    $processedFiles | ForEach-Object { $processedFilesHashSet[$_] = $true }

    $filesToMove = @()
    foreach ($file in $allFiles) {
        if (-Not $processedFilesHashSet.ContainsKey($file.FullName)) {
            $filesToMove += $file
        }
    }

    # Create necessary directories and move files
    foreach ($file in $filesToMove) {
        $relativePath = $file.FullName -replace [regex]::Escape((Get-Item $outputDir).FullName), ''
        $archivePath = Join-Path -Path $archiveDir -ChildPath $relativePath.TrimStart('\')

        # Handle file name conflicts
        $newArchivePath = $archivePath
        $count = 1
        while (Test-Path -Path $newArchivePath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($archivePath)
            $extension = [System.IO.Path]::GetExtension($archivePath)
            $newArchivePath = Join-Path -Path $archiveDirectory -ChildPath "$baseName($count)$extension"
            $count++
        }

        # Move the file
        Move-Item -Path $file.FullName -Destination $newArchivePath
    }
}

Archive-UnmodifiedFiles -outputDir $tweaksOutputDir -processedFiles $tweakResult.ProcessedFiles -archiveDir $archiveDir
Archive-UnmodifiedFiles -outputDir $featuresOutputDir -processedFiles $featureResult.ProcessedFiles -archiveDir $archiveDir
