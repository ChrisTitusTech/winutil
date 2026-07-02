#===========================================================================
# Tests - Functions
#===========================================================================

$functionRoot = Join-Path $PSScriptRoot "..\functions"
$functionCases = @(
    Get-ChildItem -Path $functionRoot -Filter *.ps1 -Recurse | ForEach-Object {
        @{
            Name = $_.Name
            Path = $_.FullName
        }
    }
)

Describe "Function source files" {
    foreach ($functionCase in $functionCases) {
        Context "Checking $($functionCase.Path)" {
            It "has no parser errors" -TestCases $functionCase {
                param([string]$Path)

                $tokens = $null
                $syntaxErrors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$syntaxErrors) | Out-Null

                if ($syntaxErrors.Count -ne 0) {
                    throw ($syntaxErrors | Out-String)
                }
            }

            It "defines top-level functions with approved verb-noun names" -TestCases $functionCase {
                param([string]$Path)

                $tokens = $null
                $syntaxErrors = $null
                $approvedVerbs = (Get-Verb).Verb
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$syntaxErrors)
                if ($syntaxErrors.Count -ne 0) {
                    throw ($syntaxErrors | Out-String)
                }

                $topLevelFunctions = @(
                    $ast.EndBlock.Statements |
                        Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] }
                )

                if ($topLevelFunctions.Count -eq 0) {
                    throw "No top-level function was found in $Path."
                }

                foreach ($function in $topLevelFunctions) {
                    if ($function.Name -notmatch '^[A-Za-z]+-[A-Za-z0-9]+$') {
                        throw "Function '$($function.Name)' does not use Verb-Noun naming."
                    }

                    $verb = ($function.Name -split '-', 2)[0]
                    if ($approvedVerbs -notcontains $verb) {
                        throw "Function '$($function.Name)' does not use an approved PowerShell verb."
                    }
                }
            }

            It "imports without throwing" -TestCases $functionCase {
                param([string]$Path)

                try {
                    . $Path
                } catch {
                    throw "Failed to import ${Path}: $_"
                }
            }
        }
    }
}
