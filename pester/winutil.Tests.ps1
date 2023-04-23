#region Load Variables needed for testing

    ./Compile.ps1

    $script = Get-Content .\winutil.ps1
    $script[0..($script.count - 21)] | Out-File .\pester.ps1    


#endregion Load Variables needed for testing 

BeforeAll {
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
