#===========================================================================
# Tests - Functions
#===========================================================================
Describe "Comprehensive Checks for PS1 Files in Functions Folder" {
    BeforeAll {
        # Get all .ps1 files in the functions folder
        $ps1Files = Get-ChildItem -Path ./functions -Filter *.ps1 -Recurse
    }

    foreach ($file in $ps1Files) {
        Context "Checking $($file.Name)" {
            It "Should import without errors" {
                { . $file.FullName } | Should -Not -Throw
            }

            It "Should have no syntax errors" {
                $syntaxErrors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $file.FullName -Raw), [ref]$syntaxErrors)
                $syntaxErrors.Count | Should -Be 0
            }

            It "Should not use deprecated cmdlets or aliases" {
                $content = Get-Content -Path $file.FullName -Raw
                # Example check for a known deprecated cmdlet or alias
                $content | Should -Not -Match 'DeprecatedCmdlet'
                # Add more checks as needed
            }

            It "Should follow naming conventions for functions" {
                $functions = (Get-Command -Path $file.FullName).Name
                foreach ($function in $functions) {
                    $function | Should -Match '^[a-z]+(-[a-z]+)*$' # Enforce lower-kebab-case
                }
            }

            It "Should define mandatory parameters for all functions" {
                . $file.FullName
                $functions = (Get-Command -Path $file.FullName).Name
                foreach ($function in $functions) {
                    $parameters = (Get-Command -Name $function).Parameters.Values
                    $mandatoryParams = $parameters | Where-Object { $_.Attributes.Mandatory -eq $true }
                    $mandatoryParams.Count | Should -BeGreaterThan 0
                }
            }

            It "Should have all functions available after import" {
                . $file.FullName
                $functions = (Get-Command -Path $file.FullName).Name
                foreach ($function in $functions) {
                    { Get-Command -Name $function -CommandType Function } | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
