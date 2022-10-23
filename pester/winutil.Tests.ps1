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
    $global:application = get-content ./config/applications.json | ConvertFrom-Json 
    $global:preset = get-content ./config/preset.json | ConvertFrom-Json 
    $global:feature = get-content ./config/feature.json | ConvertFrom-Json 
    $global:tweaks = get-content ./config/tweaks.json | ConvertFrom-Json 

    #GUI
    $global:sync = [Hashtable]::Synchronized(@{})
    $global:inputXML = get-content MainWindow.xaml
    $global:inputXML = $global:inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    [xml]$global:XAML = $global:inputXML
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $global:reader = (New-Object System.Xml.XmlNodeReader $global:xaml) 
    $global:sync["Form"] = [Windows.Markup.XamlReader]::Load( $global:reader )
    $global:xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}

    #Variables to compare GUI to config files
    $Global:GUIFeatureCount = ($global:feature.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count
    $Global:GUITabCount = ($global:sync["TabNav"].Items.name).count
    $Global:GUIApplicationCount = ($global:application.install.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count
    $Global:GUITweaksCount = ($global:tweaks.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count

#endregion Load Variables needed for testing 

#===========================================================================
# Tests - Json
#===========================================================================

Describe "Json Files" {
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

#===========================================================================
# Tests - GUI
#===========================================================================

Describe "GUI" {

    Context "XML" {
        It "Imports with no errors" {
            $global:XAML | should -Not -BeNullOrEmpty
        }
        It "Title should be $global:FormName" {
            $global:XAML.window.Title | should -Be $global:FormName
        }
    }

    Context "Form" {
        It "Imports with no errors" {
            $global:sync["Form"] | should -Not -BeNullOrEmpty
        }
        It "Title should match XML" {
            $global:sync["Form"].title | should -Be $global:XAML.window.Title
        }
        It "Tabs should be $Global:GUITabCount" {
            ($global:sync.keys | Where-Object {$psitem -like "Tab?"}).count | should -Be $Global:GUITabCount
        }
        It "Features should be $Global:GUIFeatureCount" {
            ($global:sync.keys | Where-Object {
                $psitem -like "*feature*" -and 
                $psitem -notlike "FeatureInstall"
            }).count | should -Be $Global:GUIFeatureCount
        }
        It "Applications should be $Global:GUIApplicationCount" {
            ($global:sync.keys | Where-Object {
                $psitem -like "*Install*" -and 
                $psitem -notlike "Install" -and
                $psitem -notlike "InstallUpgrade" -and
                $psitem -notlike "featureInstall"
            }).count | should -Be $Global:GUIApplicationCount
        }
        It "Tweaks should be $Global:GUITweaksCount" {
            ($global:sync.keys | Where-Object {
                $psitem -like "*tweaks*" -and 
                $psitem -notlike "tweaksbutton" 
            }).count | should -Be $Global:GUITweaksCount
        }
    } 
}
