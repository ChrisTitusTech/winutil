# Import Config Files
$global:importedconfigs = @{}
Get-ChildItem .\config | Where-Object {$_.Extension -eq ".json"} | ForEach-Object {
    $global:importedconfigs[$psitem.BaseName] = Get-Content $psitem.FullName | ConvertFrom-Json
}


#===========================================================================
# Tests - Application Installs
#===========================================================================

Describe "Config Files" -ForEach @(
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
) {
    Context "$name config file" {
        It "Imports with no errors" {
            $global:importedconfigs.$name | should -Not -BeNullOrEmpty
        }
        if ($config) {
            It "Imports should be the correct structure" {
                $applications = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                $template = $config | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                $result = New-Object System.Collections.Generic.List[System.Object]
                Foreach ($application in $applications) {
                    $compare = $global:importedconfigs.$name.$application | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
                    if (-not $compare) {
                        throw "Comparison object for application '$application' is null."
                    }
                    if (-not $template) {
                        throw "Template object for application '$application' is null."
                    }
                    if ($(Compare-Object $compare $template) -ne $null) {
                        $result.Add($application)
                    }
                }

                $result | Select-String "WPF*" | should -BeNullOrEmpty
            }
        }
        if($undo) {
            It "Toggle DWord and QWord values should be numeric or RemoveEntry" {
                $invalid = New-Object System.Collections.Generic.List[string]
                $tweaks = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name

                foreach ($tweak in $tweaks) {
                    $entry = $global:importedconfigs.$name.$tweak
                    if ($entry.Type -ne 'Toggle' -or -not $entry.registry) {
                        continue
                    }

                    foreach ($reg in $entry.registry) {
                        foreach ($property in @('Value', 'OriginalValue')) {
                            $value = $reg.$property
                            if ($null -eq $value) { continue }
                            if ($value -eq '<RemoveEntry>') { continue }
                            if ($reg.Type -in @('DWord', 'QWord')) {
                                if ($value -notmatch '^-?(0x[0-9a-fA-F]+|\d+)$') {
                                    $invalid.Add("$tweak.$property=$value")
                                }
                            }
                        }
                    }
                }

                $invalid.Count | Should -Be 0
            }

            It "Toggle Value should differ from OriginalValue when both are set" {
                $invalid = New-Object System.Collections.Generic.List[string]
                $tweaks = $global:importedconfigs.$name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name

                foreach ($tweak in $tweaks) {
                    $entry = $global:importedconfigs.$name.$tweak
                    if ($entry.Type -ne 'Toggle' -or -not $entry.registry) {
                        continue
                    }

                    foreach ($reg in $entry.registry) {
                        if ($null -eq $reg.Value -or $null -eq $reg.OriginalValue) { continue }
                        if ($reg.Value -eq '<RemoveEntry>' -or $reg.OriginalValue -eq '<RemoveEntry>') { continue }
                        if ("$($reg.Value)" -eq "$($reg.OriginalValue)") {
                            $invalid.Add("$tweak=$($reg.Value)")
                        }
                    }
                }

                $invalid.Count | Should -Be 0
            }

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
                $result | Select-String "WPF*" | should -BeNullOrEmpty
            }
        }

    }
}
