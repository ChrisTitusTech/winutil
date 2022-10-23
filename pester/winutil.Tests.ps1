$global:application = get-content ../config/applications.json | ConvertFrom-Json 
$global:preset = get-content ../config/preset.json | ConvertFrom-Json 
$global:feature = get-content ../config/feature.json | ConvertFrom-Json 
$global:tweaks = get-content ../config/tweaks.json | ConvertFrom-Json 

Describe "Appliactions" {
    Context "Application installs" {
        It "Imports with no errors" {
            $global:application | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $winget = $global:application.install.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $winget.name | should -BeLike "*Install*"
            $winget.winget | should -Not -BeNullOrEmpty
        }
    } 
}

Describe "Preset" {
    Context "Preset" {
        It "Imports with no errors" {
            $global:preset | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $preset = $global:preset.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $preset.name | should -Not -BeNullOrEmpty
            $preset.Value | should -BeLike "*Tweaks*"
        }
    } 
}

Describe "feature" {
    Context "feature" {
        It "Imports with no errors" {
            $global:feature | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $feature = $global:feature.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $feature.name | should -BeLike "*Feature*"
            $feature.Value | should -Not -BeNullOrEmpty
        }
    } 
}

Describe "tweaks" {
    Context "tweaks" {
        It "Imports with no errors" {
            $global:tweaks | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $tweaks = $global:tweaks.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $tweaks.name | should -BeLike "*Tweaks*"
            $tweaks.Value.registry | should -Not -BeNullOrEmpty
            $tweaks.Value.Service | should -Not -BeNullOrEmpty
            $tweaks.Value.ScheduledTask | should -Not -BeNullOrEmpty
            $tweaks.Value.Appx | should -Not -BeNullOrEmpty
            $tweaks.Value.InvokeScript | should -Not -BeNullOrEmpty
        }
    } 
}