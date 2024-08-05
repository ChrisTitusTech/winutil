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

function Load-Functions {
    param (
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

function Get-AdditionalFunctionsFromToggle {
    param (
        [string]$buttonName
    )
    $invokeWpfToggleContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFToggle.ps1" -Raw
    $lines = $invokeWpfToggleContent -split "`r`n"
    foreach ($line in $lines) {
        if ($line -match "`"$buttonName`" \{Invoke-(WinUtil[a-zA-Z]+)") {
            return $matches[1]
        }
    }
    return $null
}

function Get-AdditionalFunctionsFromButton {
    param (
        [string]$buttonName
    )
    $invokeWpfButtonContent = Get-Content -Path "$publicFunctionsDir/Invoke-WPFButton.ps1" -Raw
    $lines = $invokeWpfButtonContent -split "`r`n"
    foreach ($line in $lines) {
        if ($line -match "`"$buttonName`" \{Invoke-(WPF[a-zA-Z]+)") {
            return $matches[1]
        }
    }
    return $null
}

function Add-LinkAttribute {
    param (
        [Parameter(Mandatory = $true)]
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
        [PSCustomObject]$data,
        [string]$outputDir,
        [string]$jsonFilePath,
        [string]$lastModified,
        [string]$type,
        [int]$initialProgress
    )

    $totalItems = ($data.PSObject.Properties | Measure-Object).Count
    $progressIncrement = 10 / $totalItems
    $currentProgress = $initialProgress

    $tocEntries = @()
    $processedFiles = @()
    foreach ($itemName in $data.PSObject.Properties.Name) {
        $itemDetails = $data.$itemName
        $category = $itemDetails.category -replace '[^a-zA-Z0-9]', '-'
        $categoryDir = "$outputDir/$category"
        if (-Not (Test-Path -Path $categoryDir)) {
            New-Item -ItemType Directory -Path $categoryDir | Out-Null
        }
        $fullItemName = $itemName
        $displayName = $itemName -replace $itemnametocut, ''
        $filename = "$categoryDir/$displayName.md"
        $relativePath = "$outputDir/$category/$displayName.md" -replace '^docs/', ''
        if (-Not (Test-Path -Path $filename)) {
            Set-Content -Path $filename -Value "" -Encoding utf8
        }
        $tocEntries += @{
            Category = $category
            Path = $relativePath
            Name = $itemDetails.Content
            Type = $type
        }
        $processedFiles += (Get-Item $filename).FullName
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
        $FeaturesDocs = ""
        if ($itemDetails.feature -ne $null) {
            $FeaturesDocs += "## Features`r`n`r`n"
            $FeaturesDocs += "Optional Windows Features are additional functionalities or components in the Windows operating system that users can choose to enable or disable based on their specific needs and preferences.`r`n`r`n"
            $FeaturesDocs += "You can find information about Optional Windows Features on [Microsoft's Website for Optional Features](https://learn.microsoft.com/en-us/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11).`r`n"
            if (($itemDetails.feature).Count -gt 1) {
                $FeaturesDocs += "### Features to install`r`n"
            } else {
                $FeaturesDocs += "### Feature to install`r`n"
            }
            foreach ($feature in $itemDetails.feature) {
                $FeaturesDocs += "- $($feature)`r`n"
            }
        }
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
        if ($FeaturesDocs) {
            Add-Content -Path $filename -Value $FeaturesDocs -Encoding utf8
        }
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
        $displayName = $itemName -replace 'WPF(WinUtil|Toggle|Feature(s)?|Tweaks?|Panel|Fix(es)?)', ''
        $relativePath = "$outputDir/$category/$displayName" -replace '^docs/', ''
        $docLink = "https://christitustech.github.io/winutil/$relativePath"
        $jsonData.$itemName.link = $docLink

        $currentProgress += $progressIncrement
        $roundedProgress = [math]::Round($currentProgress)
        Update-Progress -StatusMessage "Adding documentation links to JSON" -Percent $roundedProgress
    }

    $jsonText = ($jsonData | ConvertTo-Json -Depth 10).replace('\n',"`n").replace('\r',"`r")
    Set-Content -Path $jsonFilePath -Value ($jsonText) -Encoding utf8
}

Update-Progress "Loading JSON files" 10
$tweaks = Get-Content -Path "config/tweaks.json" | ConvertFrom-Json
$features = Get-Content -Path "config/feature.json" | ConvertFrom-Json

Update-Progress "Getting last modified dates of the JSON files" 20
$tweaksLastModified = (Get-Item "config/tweaks.json").LastWriteTime.ToString("yyyy-MM-dd")
$featuresLastModified = (Get-Item "config/feature.json").LastWriteTime.ToString("yyyy-MM-dd")

$tweaksOutputDir = "docs/dev/tweaks"
$featuresOutputDir = "docs/dev/features"
$privateFunctionsDir = "functions/private"
$publicFunctionsDir = "functions/public"
$functions = @{}
$itemnametocut = "WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)"

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
$jsonPaths = @(".\config\feature.json", ".\config\tweaks.json")

# Loop through each JSON file path
foreach ($jsonPath in $jsonPaths) {
    # Load the JSON content
    $json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

    # Set the global root object to the current json object
    $global:rootObject = $json

    # Add the "link" attribute to the JSON
    Add-LinkAttribute -jsonObject $json

    # Convert back to JSON with the original formatting
    $jsonString = ($json | ConvertTo-Json -Depth 100).replace('\n',"`n").replace('\r',"`r")

    # Save the JSON back to the file
    Set-Content -Path $jsonPath -Value $jsonString
}

Add-LinkAttributeToJson -jsonFilePath "config/tweaks.json" -outputDir "dev/tweaks"
Add-LinkAttributeToJson -jsonFilePath "config/feature.json" -outputDir "dev/features"

Update-Progress "Generating content for documentation" 60
$tweakResult = Generate-MarkdownFiles -data $tweaks -outputDir $tweaksOutputDir -jsonFilePath "config/tweaks.json" -lastModified $tweaksLastModified -type "tweak" -initialProgress 60
$featureResult = Generate-MarkdownFiles -data $features -outputDir $featuresOutputDir -jsonFilePath "config/feature.json" -lastModified $featuresLastModified -type "feature" -initialProgress 70

Update-Progress "Generating table of contents" 80
$allTocEntries = $tweakResult.TocEntries + $featureResult.TocEntries
$tweakEntries = $allTocEntries | Where-Object { $_.Type -eq 'tweak' } | Sort-Object Category, Name
$featureEntries = $allTocEntries | Where-Object { $_.Type -eq 'feature' } | Sort-Object Category, Name

$indexContent = "# Table of Contents`r`n`r`n"
$indexContent += "## Tweaks`r`n`r`n"
$indexContent += Generate-TypeSectionContent $tweakEntries
$indexContent += "`r`n"
$indexContent += "## Features`r`n`r`n"
$indexContent += Generate-TypeSectionContent $featureEntries
$indexContent += "`r`n"
Set-Content -Path "docs/devdocs.md" -Value $indexContent -Encoding utf8

Update-Progress "Process Completed" 100
