# ID of the plan to duplicate
$sourceGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"

# Duplicate the power plan
$duplicateOutput = powercfg /duplicatescheme $sourceGUID

$guid = $null
$nameFromFile = "ChrisTitus - Ultimate Power Plan"
$description = "Ultimate Power Plan, added via WinUtils"

# Extract the GUID directly from the duplicateOutput
foreach ($line in $duplicateOutput) {
    if ($line -match "GUID du mode de gestion de l'alimentation\s*:\s*([a-fA-F0-9\-]+)") {
        $guid = $matches[1]
        Write-Output "GUID: $guid has been extracted and stored in the variable."
        break
    }
}

if (-not $guid) {
    Write-Output "No GUID found in the duplicateOutput. Check the output format."
    exit 1
}

# Execute commands to change the plan name and set the plan as active
try {
    if ($guid) {
        # Change the name of the power plan and set its description
        $changeNameOutput = powercfg /changename $guid "$nameFromFile" "$description"
        Write-Output "The power plan name and description have been changed. Output:"
        Write-Output $changeNameOutput

        # Set the power plan as active
        $setActiveOutput = powercfg /setactive $guid
        Write-Output "The power plan has been set as active. Output:"
        Write-Output $setActiveOutput
    } else {
        Write-Output "GUID is missing. Ensure that the GUID was properly extracted."
    }
} catch {
    Write-Error "Error executing powercfg commands: $_"
}
