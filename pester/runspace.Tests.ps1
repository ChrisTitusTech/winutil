#region Configurable Variables

    <#
        .NOTES
        Use this section to configure testing variables. IE if the number of tabs change in the GUI update that variable here.
        All variables need to be global to be passed between contexts

    #>

    $global:FormName = "Chris Titus Tech's Windows Utility"

#endregion Configurable Variables

#region Load Variables needed for testing

    #Config Files
    $global:importedconfigs = @{}
    Get-ChildItem .\config | Where-Object {$_.Extension -eq ".json"} | ForEach-Object {
        $global:importedconfigs[$psitem.BaseName] = Get-Content $psitem.FullName | ConvertFrom-Json
    }


#endregion Load Variables needed for testing 

#===========================================================================
# Tests - Application Installs
#===========================================================================

Describe "Config Files" -ForEach @(
    @{ 
        name = "applications"
        config = $('{
            "winget": "value",
            "choco": "value"
          }' | ConvertFrom-Json)
    },
    @{ 
        name = "tweaks"
        undo = $true
    }
){
    Context "$name config file" {
        It "Imports with no errors" {
            $global:importedconfigs.$name | should -Not -BeNullOrEmpty
        }
        if ($config){
            It "Imports should be the correct structure" {
                $applications = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                $template = $config | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                $result = New-Object System.Collections.Generic.List[System.Object]
                Foreach ($application in $applications) {
                    $compare = $global:importedconfigs.$name.$application | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                    if ($(Compare-Object $compare $template) -ne $null){
                        $result.Add($application)
                    }
                }
    
                $result | Select-String "WPF*" | should -BeNullOrEmpty
            }
        }
        if($undo){
            It "Tweaks should contain original Value" {
                $tweaks = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                $result = New-Object System.Collections.Generic.List[System.Object]

                foreach ($tweak in $tweaks){
                    $Originals = @(
                        @{ 
                            name = "registry" 
                            value = "OriginalValue"
                        },
                        @{ 
                            name = "service" 
                            value = "OriginalType"
                        },                        
                        @{ 
                            name = "ScheduledTask" 
                            value = "OriginalState"
                        }
                    )
                    Foreach ($original in $Originals){
                        $TotalCount = ($global:importedconfigs.$name.$tweak.$($original.name)).count
                        $OriginalCount = ($global:importedconfigs.$name.$tweak.$($original.name).$($original.value) | Where-Object {$_}).count
                        if($TotalCount -ne $OriginalCount){
                            $result.Add("$Tweak,$($original.name)")
                        }
                    }
                }
                $result | Select-String "WPF*" | should -BeNullOrEmpty
            }
        }

    }
}


#===========================================================================
# Tests - Functions
#===========================================================================

Describe "Functions" -ForEach @(Get-ChildItem .\functions -Recurse -File){

    BeforeEach -Scriptblock {
        . $psitem.FullName
    }
    
    Context "$($psitem.BaseName)" {
        It "Imports with no errors" {
            Get-ChildItem function:\$($psitem.BaseName) | should -Not -BeNullOrEmpty
        }
        It "Contains Description" {
            get-help $($psitem.BaseName) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Description | should -Not -BeNullOrEmpty
        }
    }
}
