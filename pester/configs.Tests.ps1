# Import Config Files
$global:importedconfigs = @{}
Get-ChildItem .\config | Where-Object {$_.Extension -eq ".json"} | ForEach-Object {
    try {
        $global:importedconfigs[$psitem.BaseName] = Get-Content $psitem.FullName | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to import config file: $($psitem.FullName). Error: $_"
    }
}


#===========================================================================
# Tests - Application Installs
#===========================================================================

$configurations = @(
    @{
        name = "applications"
        config = $('{
            "winget": "value",
            "choco": "value",
            "category": "value",
            "content": "value",
            "description": "value",
            "link": "value"
          }' | ConvertFrom-Json)
    },
    @{
        name = "tweaks"
        undo = $true
    }
)

foreach ($configuration in $configurations) {
    Describe "Config Files - $($configuration.name)" {
        $name = $configuration.name
        $config = $configuration.config
        $undo = $configuration.undo

        Context "$name config file" {
            It "Imports with no errors" {
                $global:importedconfigs | Should -Not -BeNullOrEmpty -Because "The imported configs should not be null or empty"
                $global:importedconfigs.ContainsKey($name) | Should -BeTrue -Because "The configuration '$name' should exist in the imported configs"
                $global:importedconfigs[$name] | Should -Not -BeNullOrEmpty -Because "The configuration '$name' should not be null or empty"
            }
            
            if ($config -and $global:importedconfigs -and $global:importedconfigs.ContainsKey($name)) {
                It "Imports should be the correct structure" {
                    $applications = $global:importedconfigs[$name] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                    $template = $config | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                    $result = New-Object System.Collections.Generic.List[System.Object]
                    Foreach ($application in $applications) {
                        $compare = $global:importedconfigs[$name].$application | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                        if ($(Compare-Object $compare $template)) {
                            $result.Add($application)
                        }
                    }

                    $result | Where-Object { $_ -like "WPF*" } | Should -BeNullOrEmpty
                }
            }
            
            if ($undo -and $global:importedconfigs -and $global:importedconfigs.ContainsKey($name)) {
                It "Tweaks should contain original Value" {
                    $tweaks = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                    $result = New-Object System.Collections.Generic.List[System.Object]

                    foreach ($tweak in $tweaks) {
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
                        Foreach ($original in $Originals) {
                            $TotalCount = ($global:importedconfigs.$name.$tweak.$($original.name)).count
                            $OriginalCount = ($global:importedconfigs.$name.$tweak.$($original.name).$($original.value) | Where-Object {$_}).count
                            if($TotalCount -ne $OriginalCount) {
                                $result.Add("$Tweak,$($original.name)")
                            }
                        }
                    }
                    $result | Where-Object { $_ -like "WPF*" } | Should -BeNullOrEmpty
                }
            }
        }
    }
}
