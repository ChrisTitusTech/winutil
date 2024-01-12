# Load Variables needed for testing

./Compile.ps1

$script = Get-Content .\winutil.ps1 -ErrorAction Stop
# Remove the part of the script that shows the form, leaving only the variable and function declarations
$script[0..($script.count - 3)] | Out-File .\pester.ps1 -ErrorAction Stop


BeforeAll {
    # Execute the truncated script, bringing the variables into the current scope
    . .\pester.ps1

    # Fix GUI errors on Unit Tests
    Mock -CommandName 'UI.RawUI.WindowTitle' -MockWith {}
    Mock -CommandName 'UI.RawUI.CursorPosition' -MockWith {}
    Mock -CommandName 'UI.RawUI.WindowSize' -MockWith {}
    Mock -CommandName 'UI.RawUI.ForegroundColor' -MockWith {}
    Mock -CommandName 'UI.RawUI.BackgroundColor' -MockWith {}
    Mock -CommandName 'UI.RawUI.BufferSize' -MockWith {}
    Mock -CommandName 'UI.RawUI.KeyAvailable' -MockWith {}
    Mock -CommandName 'UI.RawUI.ReadKey' -MockWith {}
    Mock -CommandName 'Write-Progress' -MockWith {}
    Mock -CommandName 'Write-Host' -MockWith {}
    Mock -CommandName 'Write-Verbose' -MockWith {}
    Mock -CommandName 'Write-Warning' -MockWith {}
    Mock -CommandName 'Write-Error' -MockWith {}
    Mock -CommandName 'Write-Debug' -MockWith {}
    Mock -CommandName 'Write-Output' -MockWith {}
    Mock -CommandName 'Write-Information' -MockWith {}
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
