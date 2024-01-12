# Load Variables needed for testing

./Compile.ps1

$script = Get-Content .\winutil.ps1 -ErrorAction Stop
# Remove the part of the script that shows the form, leaving only the variable and function declarations
$script[0..($script.count - 3)] | Out-File .\pester.ps1 -ErrorAction Stop


BeforeAll {
    # Start the transcript
    $transcriptPath = "./Winutil.log"
    Start-Transcript -Path $transcriptPath -NoClobber -Append

    # Execute the truncated script, bringing the variables into the current scope
    . .\pester.ps1
}

AfterAll {
    # Stop the transcript
    Stop-Transcript
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
