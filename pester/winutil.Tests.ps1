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
        "preset"
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

    #dotsource original script to pull in all variables and ensure no errors
    $script = Get-Content .\winutil.ps1
    $output = $script[0..($script.count - 14)] | Out-File .\pester.ps1    


#endregion Load Variables needed for testing 

#===========================================================================
# Tests - Application Installs
#===========================================================================

Describe "Application Installs" {
    Context "Application installs" {
        It "Imports with no errors" {
            $global:configs.Applications | should -Not -BeNullOrEmpty
        }
    }
    Context "Winget Install" {
        $global:configs.applications | Get-Member -MemberType NoteProperty  | ForEach-Object {
            $TestCase = @{ name = $psitem.name }
            It "$($psitem.name) should include Winget Install" -TestCases $TestCase{
                param($name)
                $null -eq $global:configs.applications.$name.winget | should -Befalse -because "$name Did not include a Winget Install"
            } 
        }
    }
    Context "GUI Applications Checkbox" {
        (get-variable | Where-Object {$psitem.name -like "*install*" -and $psitem.value.GetType().name -eq "CheckBox"}).name -replace 'Global:','' | ForEach-Object {

            $TestCase = @{ name = $psitem }
            It "$($psitem) should include application.json " -TestCases $TestCase{
                param($name)
                $null -eq $global:configs.applications.$name | should -Befalse -because "$name Does not have entry in applications.json"
            } 
        }
    } 
}

#===========================================================================
# Tests - Tweak Presets
#===========================================================================

Describe "Tweak Presets" {
    Context "Json Import" {
        It "Imports with no errors" {
            $global:configs.preset | should -Not -BeNullOrEmpty
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
    } 
}

#===========================================================================
# Tests - Functions
#===========================================================================

Describe "Functions" {
    BeforeEach -Scriptblock {
        . ./pester.ps1
        $x = 0
        while($sync.ConfigLoaded -ne $True -or $x -eq 100){
            start-sleep -Milliseconds 100
            $x ++
        }
    }

    It "Get-InstallerProcess should return the correct values" {
        Get-InstallerProcess | should -Befalse
        $process = Start-Process powershell.exe -ArgumentList "-c start-sleep 5" -PassThru 
        Get-InstallerProcess $process | should -Not -Befalse
    }

    It "Runspace background load should have data" {
        $sync.configs.applications | should -Not -BeNullOrEmpty
        $sync.configs.tweaks | should -Not -BeNullOrEmpty
        $sync.configs.preset | should -Not -BeNullOrEmpty
        $sync.configs.feature | should -Not -BeNullOrEmpty
        $sync.ComputerInfo | should -Not -BeNullOrEmpty
    }

}

#===========================================================================
# Tests - GUI Functions
#===========================================================================

Describe "GUI Functions" {
    BeforeEach -Scriptblock {
        . ./pester.ps1
        $x = 0
        while($sync.ConfigLoaded -ne $True -or $x -eq 100){
            start-sleep -Milliseconds 100
            $x ++
        }
    }

    It "GUI should load with no errors" {
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
        $WPFtweaksbutton | should -Not -BeNullOrEmpty
        $WPFminimal | should -Not -BeNullOrEmpty
        $WPFlaptop | should -Not -BeNullOrEmpty
        $WPFdesktop | should -Not -BeNullOrEmpty
        $WPFInstallUpgrade | should -Not -BeNullOrEmpty
        $WPFinstall | should -Not -BeNullOrEmpty
    }

    Context "Get-CheckBoxes" {
        It "Get-CheckBoxes Install should return data" {

            $TestCheckBoxes = @(
                "WPFInstallvc2015_32"
                "WPFInstallvscode"
                "WPFInstallgit"
            )
            
            $OutputResult = New-Object System.Collections.Generic.List[System.Object]
            $TestCheckBoxes | ForEach-Object {

                $global:configs.applications.$psitem.winget -split ";" | ForEach-Object {
                    $OutputResult.Add($psitem)
                }
            }
            $OutputResult = Sort-Object -InputObject $OutputResult

            $TestCheckBoxes | ForEach-Object {(Get-Variable $PSItem).value.ischecked = $true}
            $Output = Get-CheckBoxes -Group WPFInstall | Sort-Object
            $Output | should -Not -BeNullOrEmpty -Because "Output did not contain applications to install"
            $Output | Should -Not -Be $OutputResult -Because "Output contains duplicate values"
            $Output | Should -Be $($OutputResult | Select-Object -Unique | Sort-Object) -Because "Output doesn't match"
            $TestCheckBoxes | ForEach-Object {(Get-Variable $PSItem).value.ischecked | should -be $false}
        }
    }
    Context "Set-Presets" {
        $global:configs.preset | Get-Member -MemberType NoteProperty | ForEach-Object {
            $TestCase = @{ name = $psitem.name }
            It "preset $($psitem.name) should modify the correct values" -TestCases $TestCase {
                param($name)
                Set-Presets $name
                get-variable $global:configs.preset.$name | Select-Object -ExpandProperty value | Select-Object -ExpandProperty ischecked | Where-Object {$psitem -eq $false} | should -BeNullOrEmpty
            }
        }
    }
}
