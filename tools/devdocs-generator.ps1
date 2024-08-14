<#
    .DESCRIPTION
    This script generates markdown files for the development documentation based on the existing JSON files.
    Create table of content and archive any files in the dev folder not modified by this script.
    This script is not meant to be used manually, it is called by the github action workflow.
#>

function Process-MultilineStrings {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$str
    )

    $lines = $str.Split("`r`n")
    $count = $lines.Count

    # Loop through every line, expect last line in the string
    # We'll add it after the for loop
    for ($i = 0; $i -lt ($count - 1); $i++) {
         $line = $lines[$i]
         $processedStr += $line -replace ('^\s*\\\\', '')
         # Add the previously removed NewLine character by 'Split' Method
         $processedStr += "`r`n"
    }

    # Add last line *without* a NewLine character.
    $processedStr += $lines[$($count - 1)] -replace ('^\s*\\\\', '')

    return $processedStr
}

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

function Load-Functions {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$dir
    )

    Get-ChildItem -Path $dir -Filter *.ps1 | ForEach-Object {
        $functionName = $_.BaseName
        $functionContent = Get-Content -Path $_.FullName -Raw
        $functions[$functionName] = $functionContent
    }
}

function Get-CalledFunctions {
    param (
        [Parameter(Mandatory, position=0)]
        $scriptContent,

        [Parameter(Mandatory, position=1)]
        [hashtable]$functionList,

        [Parameter(Mandatory, position=2)]
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

function Get-AdditionalFunctionsFromToggle {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$buttonName
    )

    $invokeWpfToggleContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFToggle.ps1" -Raw
    $lines = $invokeWpfToggleContent -split "`r`n"
    foreach ($line in $lines) {
        if ($line -match "`"$buttonName`" \{Invoke-(WinUtil[a-zA-Z]+)") {
            return $matches[1]
        }
    }
}

function Get-AdditionalFunctionsFromButton {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$buttonName
    )

    $invokeWpfButtonContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFButton.ps1" -Raw
    $lines = $invokeWpfButtonContent -split "`r`n"
    foreach ($line in $lines) {
        if ($line -match "`"$buttonName`" \{Invoke-(WPF[a-zA-Z]+)") {
            return $matches[1]
        }
    }
}

function Add-LinkAttribute {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$jsonObject
    )

    $totalProperties = ($jsonObject.PSObject.Properties | Measure-Object).Count
    $progressIncrement = 50 / $totalProperties
    $currentProgress = 50

    foreach ($property in $jsonObject.PSObject.Properties) {
        if ($property.Value -is [PSCustomObject]) {
            Add-LinkAttribute -jsonObject $property.Value
        } elseif ($property.Value -is [System.Collections.ArrayList]) {
            foreach ($item in $property.Value) {
                if ($item -is [PSCustomObject]) {
                    Add-LinkAttribute -jsonObject $item
                }
            }
        }
        $currentProgress += $progressIncrement
        $roundedProgress = [math]::Round($currentProgress)
        Update-Progress -StatusMessage "Adding documentation links" -Percent $roundedProgress
    }
    if ($jsonObject -ne $global:rootObject) {
        $jsonObject | Add-Member -NotePropertyName "link" -NotePropertyValue "" -Force
    }
}

function Generate-MarkdownFiles {
    param (
        [Parameter(Mandatory, position=0)]
        [PSCustomObject]$data,

        [Parameter(Mandatory, position=1)]
        [string]$outputDir,

        [Parameter(Mandatory, position=2)]
        [string]$jsonFilePath,

        [Parameter(Mandatory, position=3)]
        [string]$lastModified,

        [Parameter(Mandatory, position=4)]
        [string]$type,

        [Parameter(position=5)]
        [int]$initialProgress
    )

    # TODO: Make the function reference generation better by making a Graph, so it highlights
    #       Which function "depends" on which, and makes it clearer on a high-level for the reader
    #       to understand the general structure.

    $totalItems = ($data.PSObject.Properties | Measure-Object).Count
    $progressIncrement = 10 / $totalItems
    $currentProgress = [int]$initialProgress

    $tocEntries = @()
    $processedFiles = @()
    foreach ($itemName in $data.PSObject.Properties.Name) {
        # Create Category Directory if needed.
        $itemDetails = $data.$itemName
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-'
        $categoryDir = "$outputDir/$category"
        if (-Not (Test-Path -Path $categoryDir)) {
            New-Item -ItemType Directory -Path $categoryDir | Out-Null
        }

        # Create empty files with correct path
        $fullItemName = $itemName
        $displayName = $itemName -replace $itemnametocut, ''
        $filename = "$categoryDir/$displayName.md"
        $relativePath = "$outputDir/$category/$displayName.md" -replace '^docs/', ''
        if (-Not (Test-Path -Path $filename)) {
            Set-Content -Path $filename -Value "" -Encoding utf8
        }

        # Add the entry to 'tocEntries' so we can generate Table Of Content easily
        # And add the Full FileName of entry
        $tocEntries += @{
            Category = $category
            Path = $relativePath
            Name = $itemDetails.Content
            Type = $type
        }
        $processedFiles += (Get-Item $filename).FullName

        $header = "# $([string]$itemDetails.Content)" + "`r`n"
        $lastUpdatedNotice = "Last Updated: $lastModified" + "`r`n"
        $autoupdatenotice = Process-MultilineStrings @"
            \\!!! info
            \\     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
"@

        $description = Process-MultilineStrings @"
            \\## Description
            \\
            \\$([string]$itemDetails.Description)
"@

        $jsonContent = ($itemDetails | ConvertTo-Json -Depth 10).replace('\n',"`n").replace('\r', "`r")
        $codeBlock = Process-MultilineStrings @"
            \\<details>
            \\<summary>Preview Code</summary>
            \\
            \\``````json
            \\$jsonContent
            \\``````
            \\
            \\</details>
"@

        # Clear the variable before continuing, will cause problems otherwise
        $FeaturesDocs = ""
        if ($itemDetails.feature) {
            $FeaturesDocs += Process-MultilineStrings @"
                \\## Features
                \\
                \\
                \\Optional Windows Features are additional functionalities or components in the Windows operating system that users can choose to enable or disable based on their specific needs and preferences.
                \\
                \\
                \\You can find information about Optional Windows Features on [Microsoft's Website for Optional Features](https://learn.microsoft.com/en-us/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11).
                \\
                \\
"@
            if (($itemDetails.feature).Count -gt 1) {
                $FeaturesDocs += "### Features to install" + "`r`n"
            } else {
                $FeaturesDocs += "### Feature to install" + "`r`n"
            }
            foreach ($feature in $itemDetails.feature) {
                $FeaturesDocs += "- $($feature)" + "`r`n"
            }
        }

        # Clear the variable before continuing, will cause problems otherwise
        $InvokeScript = ""
        if ($itemDetails.InvokeScript) {
            $InvokeScriptContent = $itemDetails.InvokeScript | Out-String
            $InvokeScript = Process-MultilineStrings @"
                \\## Invoke Script
                \\
                \\``````powershell
                \\$InvokeScriptContent
                \\``````
"@
        }

        # Clear the variable before continuing, will cause problems otherwise
        $UndoScript = ""
        if ($itemDetails.UndoScript) {
            $UndoScriptContent = $itemDetails.UndoScript | Out-String
            $UndoScript = Process-MultilineStrings @"
                \\## Undo Script
                \\
                \\``````powershell
                \\$UndoScriptContent
                \\``````
"@
        }

        # Clear the variable before continuing, will cause problems otherwise
        $ToggleScript = ""
        if ($itemDetails.ToggleScript) {
            $ToggleScriptContent = $itemDetails.ToggleScript | Out-String
            $ToggleScript = Process-MultilineStrings @"
                \\## Toggle Script
                \\
                \\``````powershell
                \\$ToggleScriptContent
                \\``````
"@
        }

        # Clear the variable before continuing, will cause problems otherwise
        $ButtonScript = ""
        if ($itemDetails.ButtonScript) {
            $ButtonScriptContent = $itemDetails.ButtonScript | Out-String
            $ButtonScript = Process-MultilineStrings @"
                \\## Button Script
                \\
                \\``````powershell
                \\$ButtonScriptContent
                \\``````
"@
        }

        # Clear the variable before continuing, will cause problems otherwise
        $FunctionDetails = ""
        $processedFunctions = New-Object 'System.Collections.Generic.HashSet[System.String]'
        $allScripts = @($itemDetails.InvokeScript, $itemDetails.UndoScript, $itemDetails.ToggleScript, $itemDetails.ButtonScript)
        foreach ($script in $allScripts) {
            if ($script) {
                $calledFunctions = Get-CalledFunctions -scriptContent $script -functionList $functions -processedFunctions ([ref]$processedFunctions)
                foreach ($functionName in $calledFunctions) {
                    if ($functions.ContainsKey($functionName)) {
                        $FunctionDetails += Process-MultilineStrings @"
                            \\## Function: $functionName
                            \\
                            \\``````powershell
                            \\$($functions[$functionName])
                            \\``````
                            \\
"@
                    }
                }
            }
        }

        $additionalFunctionToggle = Get-AdditionalFunctionsFromToggle -buttonName $fullItemName
        if ($additionalFunctionToggle) {
            $additionalFunctionNameToggle = "Invoke-$additionalFunctionToggle"
            if ($functions.ContainsKey($additionalFunctionNameToggle) -and -not $processedFunctions.Contains($additionalFunctionNameToggle)) {
                $FunctionDetails += Process-MultilineStrings @"
                    \\## Function: $additionalFunctionNameToggle
                    \\
                    \\``````powershell
                    \\$($functions[$additionalFunctionNameToggle])
                    \\``````
                    \\
"@
                $processedFunctions.Add($additionalFunctionNameToggle)
            }
        }

        $additionalFunctionButton = Get-AdditionalFunctionsFromButton -buttonName $fullItemName
        if ($additionalFunctionButton) {
            $additionalFunctionNameButton = "Invoke-$additionalFunctionButton"
            if ($functions.ContainsKey($additionalFunctionNameButton) -and -not $processedFunctions.Contains($additionalFunctionNameButton)) {
                $FunctionDetails += Process-MultilineStrings @"
                    \\## Function: $additionalFunctionNameButton
                    \\
                    \\``````powershell
                    \\$($functions[$additionalFunctionNameButton])
                    \\``````
                    \\
"@
                $processedFunctions.Add($additionalFunctionNameButton)
            }
        }

        # Clear the variable before continuing, will cause problems otherwise
        $registryDocs = ""
        if ($itemDetails.registry) {
            $registryDocs += Process-MultilineStrings @"
                \\## Registry Changes
                \\Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.
                \\
                \\
                \\You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
                \\
                \\
"@
            foreach ($regEntry in $itemDetails.registry) {
                $registryDocs += Process-MultilineStrings @"
                    \\### Registry Key: $($regEntry.Name)
                    \\
                    \\**Type:** $($regEntry.Type)
                    \\
                    \\**Original Value:** $($regEntry.OriginalValue)
                    \\
                    \\**New Value:** $($regEntry.Value)
                    \\
                    \\
"@
            }
        }

        # Clear the variable before continuing, will cause problems otherwise
        $serviceDocs = ""
        if ($itemDetails.service) {
            $serviceDocs = Process-MultilineStrings @"
                \\## Service Changes
                \\
                \\Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.
                \\
                \\You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).
                \\
                \\
"@
            foreach ($service in $itemDetails.service) {
                $serviceDocs += Process-MultilineStrings @"
                    \\### Service Name: $($service.Name)
                    \\
                    \\**Startup Type:** $($service.StartupType)
                    \\
                    \\**Original Type:** $($service.OriginalType)
                    \\
                    \\
"@
            }
        }

        # Clear the variable before continuing, will cause problems otherwise
        $scheduledTaskDocs = ""
        if ($itemDetails.ScheduledTask) {
            $scheduledTaskDocs = Process-MultilineStrings @"
                \\## Scheduled Task Changes
                \\
                \\Windows scheduled tasks are used to run scripts or programs at specific times or events. Disabling unnecessary tasks can improve system performance and reduce unwanted background activity.
                \\
                \\
                \\You can find information about scheduled tasks on [Wikipedia](https://www.wikiwand.com/en/Windows_Task_Scheduler) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/desktop/taskschd/about-the-task-scheduler).
                \\
                \\
"@
            foreach ($task in $itemDetails.ScheduledTask) {
                $scheduledTaskDocs += Process-MultilineStrings @"
                    \\### Task Name: $($task.Name)
                    \\
                    \\**State:** $($task.State)
                    \\
                    \\**Original State:** $($task.OriginalState)
                    \\
                    \\
"@
            }
        }

        $jsonLink = "[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/$jsonFilePath)"
        $customContentStartTag = "<!-- BEGIN CUSTOM CONTENT -->"
        $customContentEndTag = "<!-- END CUSTOM CONTENT -->"
        $secondCustomContentStartTag = "<!-- BEGIN SECOND CUSTOM CONTENT -->"
        $secondCustomContentEndTag = "<!-- END SECOND CUSTOM CONTENT -->"

        if (Test-Path -Path "$filename") {
            $existingContent = Get-Content -Path "$filename" -Raw
            $customContentPattern = "(?s)$customContentStartTag(.*?)$customContentEndTag"
            $secondCustomContentPattern = "(?s)$secondCustomContentStartTag(.*?)$secondCustomContentEndTag"
            if ($existingContent -match $customContentPattern) {
                $customContent = $matches[1].Trim()
            }
            if ($existingContent -match $secondCustomContentPattern) {
                $secondCustomContent = $matches[1].Trim()
            }
        }

        $fileContent = Process-MultilineStrings @"
            \\$header
            \\$lastUpdatedNotice
            \\
            \\$autoupdatenotice
            \\$( if ($itemDetails.Description) { $description } )
            \\
            \\$customContentStartTag
            \\$customContent
            \\$customContentEndTag
            \\
            \\$codeBlock
            \\
            \\$(
               if ($FeaturesDocs) { $FeaturesDocs + "`r`n" }
               if ($itemDetails.InvokeScript) { $InvokeScript + "`r`n" }
               if ($itemDetails.UndoScript) { $UndoScript + "`r`n" }
               if ($itemDetails.ToggleScript) { $ToggleScript + "`r`n" }
               if ($itemDetails.ButtonScript) { $ButtonScript + "`r`n" }
               if ($FunctionDetails) { $FunctionDetails + "`r`n" }
               if ($itemDetails.registry) { $registryDocs + "`r`n" }
               if ($itemDetails.service) { $serviceDocs + "`r`n" }
               if ($itemDetails.ScheduledTask) { $scheduledTaskDocs + "`r`n" }
            )
            \\$secondCustomContentStartTag
            \\$secondCustomContent
            \\$secondCustomContentEndTag
            \\
            \\
            \\$jsonLink
"@

        Set-Content -Path "$filename" -Value "$fileContent" -Encoding utf8

        # TODO: For whatever reason, some headers have a space before them,
        #       so as a temporary fix.. we'll remove these it so mkdocs can render properly
        (Get-Content -Raw -Path "$filename").Replace(' ##', '##') | Set-Content "$filename"
        $currentProgress += $progressIncrement
        $roundedProgress = [math]::Round($currentProgress)
        Update-Progress -StatusMessage "Generating content for documentation" -Percent $roundedProgress
    }

    return [PSCustomObject]@{
        TocEntries = $tocEntries
        ProcessedFiles = $processedFiles
    }
}

function Generate-TypeSectionContent {
    param (
        [array]$entries
    )

    $totalEntries = $entries.Count
    $progressIncrement = 10 / $totalEntries
    $currentProgress = 90

    $sectionContent = ""
    $categories = @{}
    foreach ($entry in $entries) {
        if (-Not $categories.ContainsKey($entry.Category)) {
            $categories[$entry.Category] = @()
        }
        $categories[$entry.Category] += $entry

        $currentProgress += $progressIncrement
        $roundedProgress = [math]::Round($currentProgress)
        Update-Progress -StatusMessage "Generating table of contents" -Percent $roundedProgress
    }
    foreach ($category in $categories.Keys) {
        $sectionContent += "### $category`r`n`r`n"
        foreach ($entry in $categories[$category]) {
            $sectionContent += "- [$($entry.Name)]($($entry.Path))`r`n"
        }
    }
    return $sectionContent
}

function Add-LinkAttributeToJson {
    param (
        [string]$jsonFilePath,
        [string]$outputDir
    )

    $jsonText = Get-Content -Path $jsonFilePath -Raw
    $jsonData = $jsonText | ConvertFrom-Json

    $totalItems = ($jsonData.PSObject.Properties | Measure-Object).Count
    $progressIncrement = 20 / $totalItems
    $currentProgress = 70

    foreach ($item in $jsonData.PSObject.Properties) {
        $itemName = $item.Name
        $itemDetails = $item.Value
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-'
        $displayName = $itemName -replace "$itemnametocut", ''
        $relativePath = "$outputDir/$category/$displayName" -replace '^docs/', ''
        $docLink = "https://christitustech.github.io/winutil/$relativePath"
        $jsonData.$itemName.link = $docLink

        $currentProgress += $progressIncrement
        $roundedProgress = [math]::Round($currentProgress)
        Update-Progress -StatusMessage "Adding documentation links to JSON" -Percent $roundedProgress
    }

    $jsonText = ($jsonData | ConvertTo-Json -Depth 10).replace('\n',"`n").replace('\r', "`r")
    Set-Content -Path $jsonFilePath -Value ($jsonText) -Encoding utf8
}

Update-Progress "Loading JSON files" 10
$tweaks = Get-Content -Path "../config/tweaks.json" | ConvertFrom-Json
$features = Get-Content -Path "../config/feature.json" | ConvertFrom-Json

Update-Progress "Getting last modified dates of the JSON files" 20
$tweaksLastModified = (Get-Item "../config/tweaks.json").LastWriteTime.ToString("yyyy-MM-dd")
$featuresLastModified = (Get-Item "../config/feature.json").LastWriteTime.ToString("yyyy-MM-dd")

$tweaksOutputDir = "../docs/dev/tweaks"
$featuresOutputDir = "../docs/dev/features"
$privateFunctionsDir = "../functions/private"
$publicFunctionsDir = "../functions/public"
$functions = @{}
$itemnametocut = "WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?"

Update-Progress "Creating Directories" 30
if (-Not (Test-Path -Path $tweaksOutputDir)) {
    New-Item -ItemType Directory -Path $tweaksOutputDir | Out-Null
}
if (-Not (Test-Path -Path $featuresOutputDir)) {
    New-Item -ItemType Directory -Path $featuresOutputDir | Out-Null
}

Update-Progress "Loading existing Functions" 40
Load-Functions -dir $privateFunctionsDir
Load-Functions -dir $publicFunctionsDir

Update-Progress "Adding documentation links to JSON files" 50

# Define the JSON file paths
$jsonPaths = @("../config/feature.json", "../config/tweaks.json")

# Loop through each JSON file path
foreach ($jsonPath in $jsonPaths) {
    # Load the JSON content
    $json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

    # Set the global root object to the current json object
    $global:rootObject = $json

    # Add the "link" attribute to the JSON
    Add-LinkAttribute -jsonObject $json

    # Convert back to JSON with the original formatting
    $jsonString = ($json | ConvertTo-Json -Depth 100).replace('\n',"`n").replace('\r', "`r")

    # Save the JSON back to the file
    Set-Content -Path $jsonPath -Value $jsonString
}

Add-LinkAttributeToJson -jsonFilePath "../config/tweaks.json" -outputDir "dev/tweaks"
Add-LinkAttributeToJson -jsonFilePath "../config/feature.json" -outputDir "dev/features"

Update-Progress "Generating content for documentation" 60
$tweakResult = Generate-MarkdownFiles -data $tweaks -outputDir $tweaksOutputDir -jsonFilePath "../config/tweaks.json" -lastModified $tweaksLastModified -type "tweak" -initialProgress 60
$featureResult = Generate-MarkdownFiles -data $features -outputDir $featuresOutputDir -jsonFilePath "../config/feature.json" -lastModified $featuresLastModified -type "feature" -initialProgress 70

Update-Progress "Generating table of contents" 80
$allTocEntries = $tweakResult.TocEntries + $featureResult.TocEntries
$tweakEntries = ($allTocEntries).where{ $_.Type -eq 'tweak' } | Sort-Object Category, Name
$featureEntries = ($allTocEntries).where{ $_.Type -eq 'feature' } | Sort-Object Category, Name

$indexContent += Process-MultilineStrings @"
    \\# Table of Contents
    \\
    \\
    \\## Tweaks
    \\
    \\
"@
$indexContent += $(Generate-TypeSectionContent $tweakEntries) + "`r`n"
$indexContent += Process-MultilineStrings @"
    \\## Features
    \\
    \\
"@
$indexContent += $(Generate-TypeSectionContent $featureEntries) + "`r`n"
Set-Content -Path "../docs/devdocs.md" -Value $indexContent -Encoding utf8

Update-Progress "Process Completed" 100
