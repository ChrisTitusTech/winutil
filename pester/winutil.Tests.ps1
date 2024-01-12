# Load Variables needed for testing

./Compile.ps1

$script = Get-Content .\winutil.ps1 -ErrorAction Stop
# Remove the part of the script that shows the form, leaving only the variable and function declarations
$script[0..($script.count - 3)] | Out-File .\pester.ps1 -ErrorAction Stop

Describe "Syntax" {
    Context "pester.ps1" {
        It "does not contain syntax errors" {
            try {
                . ./pester.ps1
            }
            catch {
                if ([System.Console]::IsOutputRedirected -eq $false) {
                    Write-Host "Error: $_"
                }
                throw $_
            }
        }
    }
}