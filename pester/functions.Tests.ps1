#===========================================================================
# Tests - Functions
#===========================================================================

# Get all .ps1 files in the functions folder
$ps1Files = Get-ChildItem -Path ./functions -Filter *.ps1

# Loop through each file
foreach ($file in $ps1Files) {
    # Define the test name
    $testName = "Syntax check for $($file.Name)"

    # Define the test script
    $testScript = {
        # Import the script
        . $file.FullName

        # Check if any errors occurred
        $scriptError = $error[0]
        $scriptError | Should -Be $null
    }

    # Add the test to the Pester test suite
    Describe $testName $testScript
}

Describe "Functions"{

    Get-ChildItem .\functions -Recurse -File | ForEach-Object {

        context "$($psitem.BaseName)" {
            BeforeEach -Scriptblock {
                . $psitem.FullName
            }

            It "Imports with no errors" -TestCases @{
                basename = $($psitem.BaseName)
                fullname = $psitem.FullName
            } {
                Get-ChildItem function:\$basename | should -Not -BeNullOrEmpty
            } 
        }
    }
}
