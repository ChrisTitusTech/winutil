# Enable verbose output
$VerbosePreference = "Continue"

# Import Config Files
$global:importedConfigs = @{}
Get-ChildItem .\config -Filter *.json | ForEach-Object {
    try {
        $global:importedConfigs[$_.BaseName] = Get-Content $_.FullName | ConvertFrom-Json
        Write-Verbose "Successfully imported config file: $($_.FullName)"
    } catch {
        Write-Error "Failed to import config file: $($_.FullName). Error: $_"
    }
}

Describe "Config Files Validation" {
    $configTemplates = @{
        applications = @("winget", "choco", "category", "content", "description", "link")
        tweaks = @("registry", "service", "ScheduledTask")
    }

    Context "Config File Structure" {
        It "Should import all config files without errors" {
            $global:importedConfigs | Should -Not -BeNullOrEmpty -Because "No config files were imported successfully"
            Write-Verbose "Imported configs: $($global:importedConfigs.Keys -join ', ')"
        }

        foreach ($configName in $configTemplates.Keys) {
            It "Should have the correct structure for $configName" {
                $global:importedConfigs.ContainsKey($configName) | Should -BeTrue -Because "Config file '$configName' is missing"
                $config = $global:importedConfigs[$configName]
                $config | Should -Not -BeNullOrEmpty -Because "Config file '$configName' is empty"

                $properties = $config | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
                foreach ($prop in $properties) {
                    $itemProperties = $config.$prop | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
                    $missingProperties = Compare-Object $configTemplates[$configName] $itemProperties | Where-Object { $_.SideIndicator -eq "<=" } | Select-Object -ExpandProperty InputObject
                    $missingProperties | Should -BeNullOrEmpty -Because "Item '$prop' in '$configName' config is missing properties: $($missingProperties -join ', ')"
                    if ($missingProperties) {
                        Write-Verbose "Missing properties in ${configName}['${prop}']: $($missingProperties -join ', ')"
                    }
                }
            }
        }
    }

    Context "Tweaks Configuration" {
        It "Should have original values for all tweaks" {
            $tweaks = $global:importedConfigs.tweaks
            $tweaks | Should -Not -BeNullOrEmpty -Because "Tweaks configuration is missing or empty"

            $originals = @{
                registry = "OriginalValue"
                service = "OriginalType"
                ScheduledTask = "OriginalState"
            }

            foreach ($tweak in ($tweaks | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)) {
                foreach ($type in $originals.Keys) {
                    $totalCount = ($tweaks.$tweak.$type).Count
                    $originalCount = ($tweaks.$tweak.$type.$($originals[$type]) | Where-Object { $_ }).Count
                    $originalCount | Should -Be $totalCount -Because "Tweak '$tweak' of type '$type' is missing some original values"
                    if ($originalCount -ne $totalCount) {
                        Write-Verbose "Tweak '$tweak' of type '$type' has $originalCount original values out of $totalCount total values"
                    }
                }
            }
        }
    }

    Context "Applications Configuration" {
        It "Should have all required fields for each application" {
            $apps = $global:importedConfigs.applications
            $apps | Should -Not -BeNullOrEmpty -Because "Applications configuration is missing or empty"

            foreach ($app in ($apps | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)) {
                foreach ($field in $configTemplates.applications) {
                    $apps.$app.$field | Should -Not -BeNullOrEmpty -Because "Application '$app' is missing the '$field' field"
                    if (-not $apps.$app.$field) {
                        Write-Verbose "Application '$app' is missing the '$field' field"
                    }
                }
            }
        }
    }
}

# Summarize test results
$testResults = Invoke-Pester -PassThru
if ($testResults.FailedCount -gt 0) {
    Write-Error "Tests failed. $($testResults.FailedCount) out of $($testResults.TotalCount) tests failed."
    exit 1
} else {
    Write-Output "All tests passed successfully!"
}