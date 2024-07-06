# PowerShell script to modify Microsoft Edge, Windows Explorer, and Group Policy settings

# Function to disable CoPilot feature in Edge
function DisableEdgeCoPilot {
    $edgeRegistryPath = "HKCU:\Software\Microsoft\Edge"

    if (Test-Path $edgeRegistryPath) {
        # Disable CoPilot feature
        New-ItemProperty -Path $edgeRegistryPath -Name "ShowCoPilot" -Value 0 -PropertyType "DWORD" -Force | Out-Null
        Write-Host "CoPilot feature disabled in Edge browser."
    } else {
        Write-Host "Edge browser registry path not found. Please verify Edge installation."
    }
}

# Function to disable Bing AI suggestions in Edge
function DisableBingAI {
    $edgeRegistryPath = "HKCU:\Software\Microsoft\Edge"

    if (Test-Path $edgeRegistryPath) {
        # Disable Bing AI suggestions
        New-ItemProperty -Path $edgeRegistryPath -Name "ShowBingAI" -Value 0 -PropertyType "DWORD" -Force | Out-Null
        Write-Host "Bing AI suggestions disabled in Edge browser."
    } else {
        Write-Host "Edge browser registry path not found. Please verify Edge installation."
    }
}

# Function to disable search box suggestions in Windows Explorer
function DisableSearchBoxSuggestions {
    $explorerRegistryPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"

    # Create Explorer registry path if it doesn't exist
    if (!(Test-Path $explorerRegistryPath)) {
        New-Item -Path $explorerRegistryPath -Force | Out-Null
    }

    # Set registry key to disable search box suggestions
    Set-ItemProperty -Path $explorerRegistryPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force | Out-Null
    Write-Host "Search box suggestions disabled in Windows Explorer."
}

# Function to configure Group Policy to remove CoPilot from taskbar
function ConfigureGroupPolicyToRemoveCoPilot {
    $gpRegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    # Create Explorer policies registry path if it doesn't exist
    if (!(Test-Path $gpRegistryPath)) {
        New-Item -Path $gpRegistryPath -Force | Out-Null
    }

    # Set registry key to remove CoPilot from taskbar
    Set-ItemProperty -Path $gpRegistryPath -Name "NoWindowsCopilotTaskbar" -Value 1 -Type DWord -Force | Out-Null
    Write-Host "CoPilot removed from taskbar via Group Policy."
}

# Main script execution
DisableEdgeCoPilot
DisableBingAI
DisableSearchBoxSuggestions
ConfigureGroupPolicyToRemoveCoPilot

Write-Host "Edge browser, Windows Explorer, and Group Policy settings modified successfully."
