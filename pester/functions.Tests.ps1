#===========================================================================
# Tests - Functions
#===========================================================================

Describe "Functions"{

    Get-ChildItem .\functions -Recurse -File | ForEach-Object {

        context "$($psitem.BaseName)" {
            BeforeEach -Scriptblock {
                . $fullname
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
