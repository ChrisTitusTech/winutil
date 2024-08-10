# PowerShell script to fix the power plan applied across all languages based on the GUID of the new power plan.
# This is necessary because when Windows is in a different language, the power plan might not be applied correctly.
# This script changes the name and description of the power plan.
#Video : https://youtu.be/00aUECZNvbA

# ID of the plan to duplicate
$sourceGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$guid = $null
$nameFromFile = "ChrisTitus - Ultimate Power Plan"
$description = "Ultimate Power Plan , added via WinUtils"

$scriptPath = $MyInvocation.MyCommand.Path
$directoryPath = Split-Path -Path $scriptPath -Parent

$guidFilePath = Join-Path -Path $directoryPath -ChildPath "guid.txt"

$duplicateOutput = powercfg /duplicatescheme $sourceGUID

try {
    $duplicateOutput | Out-File -FilePath $guidFilePath -Append -Encoding utf8 -Force

    Write-Output "The output of 'powercfg /duplicatescheme' has been added to $guidFilePath."
} catch {
    Write-Error "Error writing to the file: $_"
}
$content = Get-Content -Path $guidFilePath -Encoding utf8

# Extract the GUID from the content
foreach ($line in $content) {
    if ($line -match "GUID du mode de gestion de l'alimentation\s*:\s*([a-fA-F0-9\-]+)") {
        $guid = $matches[1]
        # Write the GUID to guid.txt (overwrite existing content)
        $guid | Out-File -FilePath $guidFilePath -Encoding utf8 -Force

        Write-Output "GUID: $guid has been saved to $guidFilePath"
    }
}

if (-not $guid) {
    Write-Output "No GUID found in $guidFilePath. Check the content format."
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
        Write-Output "GUID is missing. Ensure that guid.txt contains the necessary information."
    }
} catch {
    Write-Error "Error executing powercfg commands: $_"
}
