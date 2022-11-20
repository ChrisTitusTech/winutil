
#region Configurable Variables

    <#
        .NOTES
        Use this section to configure testing variables. IE if the number of tabs change in the GUI update that variable here.
        All variables need to be global to be passed between contexts

    #>


#endregion Configurable Variables

#region Load Variables needed for testing

    #Config Files
    $global:configs = @{}

    (
        "applications"
    ) | ForEach-Object {
        $global:configs["$PSItem"] = Get-Content .\config\$PSItem.json | ConvertFrom-Json
    }

#endregion Load Variables needed for testing 

#===========================================================================
# Tests - Config Files
#===========================================================================

Describe "Config Files" {
    Context "Application installs" {
        It "Imports with no errors" {
            $global:configs.Applications | should -Not -BeNullOrEmpty
        }
        $global:configs.applications.install | Get-Member -MemberType NoteProperty  | ForEach-Object {
            $TestCase = @{ name = $psitem.name }
            It "$($psitem.name) should include Winget Install" -TestCases $TestCase{
                param($name)
                $null -eq $global:configs.applications.install.$name.winget | should -Befalse -because "$name Did not include a Winget Install"
            } 
        }
    } 
}