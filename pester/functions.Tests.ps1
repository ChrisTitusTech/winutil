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
            It "Contains Description" -TestCases @{
                basename = $($psitem.BaseName)
                fullname = $psitem.FullName
            } {
                get-help $basename -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Description | should -Not -BeNullOrEmpty
            }
        }
    }
}
