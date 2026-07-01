#===========================================================================
# Tests - Config Files
#===========================================================================

$configRoot = Join-Path $PSScriptRoot "..\config"
$configCases = @(
    Get-ChildItem -Path $configRoot -Filter *.json | ForEach-Object {
        @{
            Name = $_.Name
            Path = $_.FullName
        }
    }
)

Describe "Config files" {
    foreach ($configCase in $configCases) {
        It "imports $($configCase.Name) with no JSON errors" -TestCases $configCase {
            param([string]$Name, [string]$Path)

            try {
                Get-Content -Path $Path -Raw | ConvertFrom-Json | Out-Null
            } catch {
                throw "Failed to import ${Name}: $_"
            }
        }
    }
}

Describe "Applications config" {
    $testCase = @{ Path = (Join-Path $configRoot "applications.json") }

    It "contains at least one application" -TestCases $testCase {
        param([string]$Path)

        $applications = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $applicationEntries = @($applications.PSObject.Properties)

        if ($applicationEntries.Count -eq 0) {
            throw "applications.json does not contain any application entries."
        }
    }

    It "contains required display fields and at least one install source" -TestCases $testCase {
        param([string]$Path)

        $applications = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $requiredFields = @("category", "content", "description", "link")
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $applications.PSObject.Properties) {
            $entryFields = @($entry.Value.PSObject.Properties.Name)

            foreach ($field in $requiredFields) {
                if ($entryFields -notcontains $field -or [string]::IsNullOrWhiteSpace([string]$entry.Value.$field)) {
                    $invalidEntries.Add("$($entry.Name) missing $field")
                }
            }

            $hasInstallSource = $false
            foreach ($sourceField in @("winget", "choco")) {
                if ($entryFields -contains $sourceField -and -not [string]::IsNullOrWhiteSpace([string]$entry.Value.$sourceField)) {
                    $hasInstallSource = $true
                }
            }

            if (-not $hasInstallSource) {
                $invalidEntries.Add("$($entry.Name) missing winget/choco install source")
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }
}

Describe "Tweaks config" {
    $testCase = @{ Path = (Join-Path $configRoot "tweaks.json") }

    It "contains undo metadata for registry and service actions" -TestCases $testCase {
        param([string]$Path)

        $tweaks = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $invalidTweaks = New-Object System.Collections.Generic.List[string]

        foreach ($tweak in $tweaks.PSObject.Properties) {
            foreach ($registryEntry in @($tweak.Value.registry)) {
                if ($null -eq $registryEntry) { continue }

                if ($registryEntry.PSObject.Properties.Name -notcontains "OriginalValue" -or
                    [string]::IsNullOrWhiteSpace([string]$registryEntry.OriginalValue)) {
                    $invalidTweaks.Add("$($tweak.Name),registry")
                }
            }

            foreach ($serviceEntry in @($tweak.Value.service)) {
                if ($null -eq $serviceEntry) { continue }

                if ($serviceEntry.PSObject.Properties.Name -notcontains "OriginalType" -or
                    [string]::IsNullOrWhiteSpace([string]$serviceEntry.OriginalType)) {
                    $invalidTweaks.Add("$($tweak.Name),service")
                }
            }
        }

        if ($invalidTweaks.Count -gt 0) {
            throw ($invalidTweaks -join "`n")
        }
    }
}
