# Enable verbose output
$VerbosePreference = "Continue"

# Import Config Files
$global:importedConfigs = @{}
$configFiles = Get-ChildItem .\config -Filter *.json -ErrorAction SilentlyContinue
if ($configFiles) {
    foreach ($file in $configFiles) {
        try {
            $global:importedConfigs[$file.BaseName] = Get-Content $file.FullName | ConvertFrom-Json
            Write-Verbose "Successfully imported config file: $($file.FullName)"
        } catch {
            Write-Error "Failed to import config file: $($file.FullName). Error: $_"
        }
    }
} else {
    Write-Warning "No config files found in the .\config directory"
}

Describe "Config Files Validation" {
    $configSchemas = @{
        applications = @{
            Type = "Object"
            Properties = @{
                winget = @{ Type = "String" }
                choco = @{ Type = "String" }
                category = @{ Type = "String" }
                content = @{ Type = "String" }
                description = @{ Type = "String" }
                link = @{ Type = "String" }
            }
            Required = @("winget", "choco", "category", "content", "description", "link")
        }
        tweaks = @{
            Type = "Object"
            Properties = @{
                registry = @{
                    Type = "Object"
                    Properties = @{
                        Path = @{ Type = "String" }
                        Name = @{ Type = "String" }
                        Type = @{ Type = "String" }
                        Value = @{ Type = "String" }
                        OriginalValue = @{ Type = "String" }
                    }
                    Required = @("Path", "Name", "Type", "Value", "OriginalValue")
                }
                service = @{
                    Type = "Object"
                    Properties = @{
                        Name = @{ Type = "String" }
                        StartupType = @{ Type = "String" }
                        OriginalType = @{ Type = "String" }
                    }
                    Required = @("Name", "StartupType", "OriginalType")
                }
                ScheduledTask = @{
                    Type = "Object"
                    Properties = @{
                        Name = @{ Type = "String" }
                        State = @{ Type = "String" }
                        OriginalState = @{ Type = "String" }
                    }
                    Required = @("Name", "State", "OriginalState")
                }
            }
        }
    }

    Context "Config File Structure" {
        It "Should import all config files without errors" {
            $global:importedConfigs | Should -Not -BeNullOrEmpty -Because "No config files were imported successfully"
            Write-Verbose "Imported configs: $($global:importedConfigs.Keys -join ', ')"
        }

        foreach ($configName in $configSchemas.Keys) {
            It "Should have the correct structure for $configName" {
                $global:importedConfigs | Should -Not -BeNullOrEmpty
                $global:importedConfigs.ContainsKey($configName) | Should -BeTrue -Because "Config file '$configName' is missing"
                $config = $global:importedConfigs[$configName]
                $config | Should -Not -BeNullOrEmpty -Because "Config file '$configName' is empty"

                $schema = $configSchemas[$configName]
                
                function Test-Schema {
                    param (
                        $Object,
                        $Schema
                    )

                    $Object.PSObject.Properties | ForEach-Object {
                        $propName = $_.Name
                        $propValue = $_.Value

                        $propSchema = $Schema.Properties[$propName]
                        $propSchema | Should -Not -BeNullOrEmpty -Because "Property '$propName' is not defined in the schema"

                        switch ($propSchema.Type) {
                            "String" { $propValue | Should -BeOfType [string] }
                            "Object" { 
                                $propValue | Should -BeOfType [PSCustomObject]
                                Test-Schema -Object $propValue -Schema $propSchema
                            }
                        }
                    }

                    foreach ($requiredProp in $Schema.Required) {
                        $Object.PSObject.Properties.Name | Should -Contain $requiredProp -Because "Required property '$requiredProp' is missing"
                    }
                }

                Test-Schema -Object $config -Schema $schema
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