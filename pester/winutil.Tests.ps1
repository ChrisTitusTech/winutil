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
    $global:configs = @{}

    (
        "applications", 
        "tweaks",
        "preset", 
        "feature"
    ) | ForEach-Object {
        $global:configs["$PSItem"] = Get-Content .\config\$PSItem.json | ConvertFrom-Json
    }

    #GUI
    $global:inputXML = get-content MainWindow.xaml
    $global:inputXML = $global:inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    [xml]$global:XAML = $global:inputXML
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $global:reader = (New-Object System.Xml.XmlNodeReader $global:xaml) 
    $global:Form  = [Windows.Markup.XamlReader]::Load( $global:reader )
    $global:xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "Global:WPF$($_.Name)" -Value $global:Form.FindName($_.Name) -Scope global }

    #Variables to compare GUI to config files
    $Global:GUIFeatureCount = ( $global:configs.feature.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count
    $Global:GUIApplicationCount = ($global:configs.applications.install.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count
    $Global:GUITweaksCount = ($global:configs.tweaks.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"}).count

    #dotsource original script to pull in all variables and ensure no errors
    $script = Get-Content .\winutil.ps1
    $output = $script[0..($script.count - 3)] | Out-File .\pester.ps1    

#endregion Load Variables needed for testing 

#===========================================================================
# Tests - Config Files
#===========================================================================

Describe "Config Files" {
    Context "Application installs" {
        It "Imports with no errors" {
            $global:configs.Applications | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $winget = $global:configs.applications.install.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $winget.name | should -BeLike "*Install*"
            $winget.winget | should -Not -BeNullOrEmpty
        }
    } 

    Context "Preset" {
        It "Imports with no errors" {
            $global:configs.preset | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $preset = $global:configs.preset.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $preset.name | should -Not -BeNullOrEmpty
            $preset.Value | should -BeLike "*Tweaks*"
        }
    } 

    Context "feature" {
        It "Imports with no errors" {
            $global:configs.feature | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $feature = $global:configs.feature.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $feature.name | should -BeLike "*Feature*"
            $feature.Value | should -Not -BeNullOrEmpty
        }
    } 
    
    Context "tweaks" {
        It "Imports with no errors" {
            $global:configs.tweaks | should -Not -BeNullOrEmpty
        }
        It "Json should be in correct format" {
            $tweaks = $global:configs.tweaks.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value
            $tweaks.name | should -BeLike "*Tweaks*"
            $tweaks.Value.registry | should -Not -BeNullOrEmpty
            $tweaks.Value.Service | should -Not -BeNullOrEmpty
            $tweaks.Value.ScheduledTask | should -Not -BeNullOrEmpty
            $tweaks.Value.Appx | should -Not -BeNullOrEmpty
            $tweaks.Value.InvokeScript | should -Not -BeNullOrEmpty
        }
        It "Original Values should be set" {
            $tweaks = $global:configs.tweaks.psobject.members | Where-Object {$psitem.MemberType -eq "NoteProperty"} | Select-Object Name,Value

            Foreach($tweak in $tweaks){
                if($tweak.value.registry){

                    $values = $tweak.value | Select-Object -ExpandProperty registry

                    Foreach ($value in $values){
                        $value.OriginalValue | should -Not -BeNullOrEmpty
                    }  
                }
                if($tweak.value.Service){

                    $values = $tweak.value | Select-Object -ExpandProperty Service

                    Foreach ($value in $values){
                        $value.OriginalType | should -Not -BeNullOrEmpty
                    }  
                }
                if($tweak.value.ScheduledTask){

                    $values = $tweak.value | Select-Object -ExpandProperty ScheduledTask

                    Foreach ($value in $values){
                        $value.OriginalState | should -Not -BeNullOrEmpty
                    }  
                }
            }
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
            $global:Form | should -Not -BeNullOrEmpty
        }
        It "Title should match XML" {
            $global:Form.title | should -Be $global:XAML.window.Title
        }
        It "Features should be $Global:GUIFeatureCount" {
            (get-variable | Where-Object {$psitem.name -like "*feature*" -and $psitem.value.GetType().name -eq "CheckBox"}).count | should -Be $Global:GUIFeatureCount
        }
        It "Applications should be $Global:GUIApplicationCount" {
            (get-variable | Where-Object {$psitem.name -like "*install*" -and $psitem.value.GetType().name -eq "CheckBox"}).count | should -Be $Global:GUIApplicationCount
        }
        It "Tweaks should be $Global:GUITweaksCount" {
            (get-variable | Where-Object {$psitem.name -like "*tweaks*" -and $psitem.value.GetType().name -eq "CheckBox"}).count | should -Be $Global:GUITweaksCount
        }
    } 
}

#===========================================================================
# Tests - GUI
#===========================================================================

Describe "GUI Functions" {

    It "GUI should load with no errors" {
        . .\pester.ps1 
        $WPFTab1BT | should -Not -BeNullOrEmpty
        $WPFundoall | should -Not -BeNullOrEmpty
        $WPFPanelDISM | should -Not -BeNullOrEmpty
        $WPFPanelAutologin | should -Not -BeNullOrEmpty
        $WPFUpdatesdefault | should -Not -BeNullOrEmpty
        $WPFFixesUpdate | should -Not -BeNullOrEmpty
        $WPFUpdatesdisable | should -Not -BeNullOrEmpty
        $WPFUpdatessecurity | should -Not -BeNullOrEmpty
        $WPFFeatureInstall | should -Not -BeNullOrEmpty
        $WPFundoall | should -Not -BeNullOrEmpty
        $WPFDisableDarkMode | should -Not -BeNullOrEmpty
        $WPFEnableDarkMode | should -Not -BeNullOrEmpty
        $WPFtweaksbutton | should -Not -BeNullOrEmpty
        $WPFminimal | should -Not -BeNullOrEmpty
        $WPFlaptop | should -Not -BeNullOrEmpty
        $WPFdesktop | should -Not -BeNullOrEmpty
        $WPFInstallUpgrade | should -Not -BeNullOrEmpty
        $WPFinstall | should -Not -BeNullOrEmpty
    }

    It "Get-CheckBoxes Install should return data" {
        . .\pester.ps1 

        $WPFInstallvc2015_32.ischecked = $true
        (Get-CheckBoxes -Group WPFInstall) | should -Not -BeNullOrEmpty
        $WPFInstallvc2015_32.ischecked | should -be $false
    }
}