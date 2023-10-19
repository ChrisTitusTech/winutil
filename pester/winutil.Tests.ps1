# Load Variables needed for testing

./Compile.ps1

$script = Get-Content .\winutil.ps1
# Remove the part of the script that shows the form, leaving only the variable and function declarations
$script[0..($script.count - 21)] | Out-File .\pester.ps1


BeforeAll {
    # Execute the truncated script, bringing the variabes into the current scope
    . .\pester.ps1
}

Describe "GUI" {
    Context "XML" {
        It "Imports with no errors" {
            $inputXML | should -Not -BeNullOrEmpty
        }
    }

    Context "Form" {
        It "Imports with no errors" {
            $sync.Form | should -Not -BeNullOrEmpty
        }
    }
}
