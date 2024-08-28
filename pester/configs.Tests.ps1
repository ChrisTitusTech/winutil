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
    BeforeAll {
        $script:configSchemas = @{
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

        function Test-Schema {
            param (
                $Object,
                $Schema
            )

            $errors = @()

            $Object.PSObject.Properties | ForEach-Object {
                $propName = $_.Name
                $propValue = $_.Value

                $propSchema = $Schema.Properties[$propName]
                if (-not $propSchema) {
                    $errors += "Property '$propName' is not defined in the schema"
                    return
                }

                switch ($propSchema.Type) {
                    "String" { 
                        if ($propValue -isnot [string]) {
                            $errors += "Property '$propName' should be a string but is $($propValue.GetType())"
                        }
                    }
                    "Object" { 
                        if ($propValue -isnot [PSCustomObject]) {
                            $errors += "Property '$propName' should be an object but is $($propValue.GetType())"
                        } else {
                            $errors += Test-Schema -Object $propValue -Schema $propSchema
                        }
                    }
                }
            }

            foreach ($requiredProp in $Schema.Required) {
                if (-not $Object.PSObject.Properties.Name.Contains($requiredProp)) {
                    $errors += "Required property '$requiredProp' is missing"
                }
            }

            return $errors
        }
    }

    Context "Config File Structure" {
        It "Should import all config files without errors" {
            $global:importedConfigs | Should -Not -BeNullOrEmpty -Because "No config files were imported successfully"
        }

        It "Should have the correct structure for all configs" {
            $results = $configSchemas.Keys | ForEach-Object -Parallel {
                $configName = $_
                $importedConfigs = $using:global:importedConfigs
                $config = $importedConfigs[$configName]
                $schema = $using:configSchemas[$configName]
                
                if (-not $config) {
                    return "Config file '$configName' is missing or empty"
                }

                & $using:Test-Schema -Object $config -Schema $schema
            } -ThrottleLimit 4

            $results | Should -BeNullOrEmpty -Because "The following schema violations were found: $($results -join '; ')"
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