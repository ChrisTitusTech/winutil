BeforeAll {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    foreach ($file in @(
        "functions/private/Initialize-InstallAppEntries.ps1",
        "functions/private/Get-WinUtilAppIcon.ps1",
        "functions/private/Get-WinUtilAppEntryHandlers.ps1",
        "functions/private/Get-WinUtilAppEntryFromElement.ps1",
        "functions/private/Get-WinUtilEntryToolTip.ps1",
        "functions/public/Invoke-WPFRunspace.ps1"
    )) {
        . (Join-Path $repoRoot $file)
    }
    function Invoke-WPFSelectedCheckboxesUpdate { param($type, $checkboxName) }

    # 1x1 transparent PNG
    $script:pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
}

Describe "App entries" {
    BeforeEach {
        $script:WinUtilAppIconCache = $null
        $script:sync = [Hashtable]::Synchronized(@{
            Form = [Windows.Window]::new()
            configs = @{
                applicationsHashtable = @{
                    WPFInstallTestApp = [pscustomobject]@{ content = "Test app"; description = "Test"; link = "https://example.com/"; foss = $false }
                }
                icons = [pscustomobject]@{ TestApp = $script:pixel }
            }
            selectedApps = @()
        })
        $script:panel = [Windows.Controls.WrapPanel]::new()
        Mock Invoke-WPFRunspace { throw "Entries must not occupy the shared job pool" }
    }

    AfterEach {
        if ($script:sync.Form) { $script:sync.Form.Close() }
    }

    Context "with a bundled icon" {
        It "draws the icon as a frozen bitmap with no download" {
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $content = $checkbox.Content
            $logo = $content.Children[0].Child.Children[1]

            $script:panel.Children.Count | Should -Be 1
            $script:panel.Children[0].Tag | Should -Be "WPFInstallTestApp"
            $content.Children[1].Text | Should -Be "Test app"
            $logo.Source | Should -BeOfType ([Windows.Media.Imaging.BitmapSource])
            $logo.Source.IsFrozen | Should -BeTrue
            $logo.Source.Decoder.GetType().Name | Should -Be "PngBitmapDecoder"
            $content.Children[0].Child.Children[0].Visibility | Should -Be "Collapsed"
            Should -Invoke Invoke-WPFRunspace -Times 0
        }

        It "decodes each icon once and shares it between entries" {
            $script:sync.configs.applicationsHashtable.WPFInstallOther = $script:sync.configs.applicationsHashtable.WPFInstallTestApp
            $first = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $second = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp

            [object]::ReferenceEquals($first.Content.Children[0].Child.Children[1].Source, $second.Content.Children[0].Child.Children[1].Source) | Should -BeTrue
        }

        It "returns the check boxes in the order of the keys and places every card" {
            foreach ($name in "B", "C") {
                $script:sync.configs.applicationsHashtable["WPFInstall$name"] = [pscustomobject]@{ content = "App $name"; description = ""; link = ""; foss = $false }
            }
            $checkBoxes = @(Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallC, WPFInstallTestApp, WPFInstallB)

            $checkBoxes.Tag | Should -Be @("WPFInstallC", "WPFInstallTestApp", "WPFInstallB")
            @($script:panel.Children.Tag) | Should -Be @("WPFInstallC", "WPFInstallTestApp", "WPFInstallB")
        }

        It "keeps names that need escaping intact" {
            $script:sync.configs.applicationsHashtable.WPFInstallTestApp.content = 'R&D "Tool" <beta>'
            $script:sync.configs.applicationsHashtable.WPFInstallTestApp.description = "Fast & `"free`"`nsecond line"
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp

            $checkbox.Content.Children[1].Text | Should -Be 'R&D "Tool" <beta>'
            $script:panel.Children[0].ToolTip | Should -Be "Fast & `"free`"`nsecond line`n`nPreset key: WPFInstallTestApp"
        }

        It "marks free and open source apps with the corner badge only" {
            $script:sync.configs.applicationsHashtable.WPFInstallB = [pscustomobject]@{ content = "Free app"; description = ""; link = ""; foss = $true }
            Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp, WPFInstallB | Out-Null

            $script:panel.Children[0].Child.Children.Count | Should -Be 1
            $script:panel.Children[1].Child.Children.Count | Should -Be 2
            $script:panel.Children[1].Child.Children[1] | Should -BeOfType ([Windows.Controls.Viewbox])
        }

        It "checks an app that was already selected" {
            $script:sync.selectedApps = @("WPFInstallTestApp")
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp

            $checkbox.IsChecked | Should -BeTrue
        }

        It "needs no handler of its own: the category panel's shared handlers see the check box change" {
            $handlers = Get-WinUtilAppEntryHandlers
            $script:panel.AddHandler([Windows.Controls.Primitives.ToggleButton]::CheckedEvent, $handlers.Checked)
            $script:panel.AddHandler([Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, $handlers.Unchecked)
            Mock Invoke-WPFSelectedCheckboxesUpdate { }
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp

            $checkbox.IsChecked = $true
            $script:panel.Children[0].ReadLocalValue([Windows.Controls.Border]::BackgroundProperty) | Should -Not -Be ([Windows.DependencyProperty]::UnsetValue)
            $checkbox.IsChecked = $false

            Should -Invoke Invoke-WPFSelectedCheckboxesUpdate -Times 1 -Exactly -ParameterFilter { $type -eq "Add" -and $checkboxName -eq "WPFInstallTestApp" }
            Should -Invoke Invoke-WPFSelectedCheckboxesUpdate -Times 1 -Exactly -ParameterFilter { $type -eq "Remove" -and $checkboxName -eq "WPFInstallTestApp" }
            $script:panel.Children[0].ReadLocalValue([Windows.Controls.Border]::BackgroundProperty) | Should -Be ([Windows.DependencyProperty]::UnsetValue)
        }
    }

    Context "without a bundled icon" {
        It "keeps the letter tile, without asking the favicon service, when an app is listed with no icon" {
            $script:sync.configs.icons = [pscustomobject]@{ TestApp = "" }
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $icon = $checkbox.Content.Children[0].Child

            $icon.Children[1].Source | Should -BeNullOrEmpty
            $icon.Children[0].Text | Should -Be "T"
            $icon.Children[0].Visibility | Should -Be "Visible"
        }

        It "falls back to the favicon service for an app that is not listed" {
            $script:sync.configs.icons = [pscustomobject]@{}
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $logo = $checkbox.Content.Children[0].Child.Children[1]

            $logo.Source | Should -BeOfType ([Windows.Media.Imaging.BitmapImage])
            $logo.Source.CreateOptions | Should -Be ([Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache)
            $logo.Source.UriSource.AbsoluteUri | Should -Be "https://www.google.com/s2/favicons?sz=64&domain_url=https%3A%2F%2Fexample.com%2F"
            Should -Invoke Invoke-WPFRunspace -Times 0
        }

        It "falls back to the favicon service when a bundled icon cannot be decoded" {
            $script:sync.configs.icons = [pscustomobject]@{ TestApp = "bm90IGEgcG5n" }
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp

            $checkbox.Content.Children[0].Child.Children[1].Source.UriSource.AbsoluteUri | Should -BeLike "https://www.google.com/s2/favicons*"
        }

        It "shows the letter fallback when WPF reports a download failure" {
            $script:sync.configs.icons = [pscustomobject]@{}
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $icon = $checkbox.Content.Children[0].Child
            $logo = $icon.Children[1]
            $constructor = [Windows.ExceptionRoutedEventArgs].GetConstructors(
                [Reflection.BindingFlags]'Instance, NonPublic')[0]
            $failureEvent = $constructor.Invoke(@([Windows.Controls.Image]::ImageFailedEvent, $logo, [Exception]::new("Download failed")))
            $logo.RaiseEvent($failureEvent)

            $logo.Visibility | Should -Be "Collapsed"
            $icon.Children[0].Visibility | Should -Be "Visible"
        }

        It "keeps the letter fallback for apps without a website" {
            $script:sync.configs.icons = [pscustomobject]@{}
            $script:sync.configs.applicationsHashtable.WPFInstallTestApp.link = $null
            $checkbox = Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys WPFInstallTestApp
            $icon = $checkbox.Content.Children[0].Child

            $icon.Children[0].Text | Should -Be "T"
            $icon.Children[0].Visibility | Should -Be "Visible"
            $icon.Children[1].Source | Should -BeNullOrEmpty
        }
    }

    Context "the shipped icon set" {
        It "bundles a decodable 64px icon for every listed application" {
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
            $applications = Get-Content (Join-Path $repoRoot "config/applications.json") -Raw | ConvertFrom-Json
            $script:sync.configs.icons = Get-Content (Join-Path $repoRoot "config/icons.json") -Raw | ConvertFrom-Json

            $problems = foreach ($key in $applications.PSObject.Properties.Name) {
                if (-not $script:sync.configs.icons.PSObject.Properties[$key]) { "$key has no entry in icons.json"; continue }
                $icon = Get-WinUtilAppIcon -Key $key
                if ($icon -is [Windows.Media.Imaging.BitmapSource]) {
                    if ($icon.PixelWidth -ne 64 -or $icon.PixelHeight -ne 64) { "$key icon is $($icon.PixelWidth)x$($icon.PixelHeight), not 64x64" }
                } elseif ($icon -ne $false) {
                    "$key icon could not be decoded"
                }
            }
            $problems | Should -BeNullOrEmpty
        }

        It "builds every application's entry in one parse" {
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
            $applications = Get-Content (Join-Path $repoRoot "config/applications.json") -Raw | ConvertFrom-Json
            $hashtable = @{}
            foreach ($property in $applications.PSObject.Properties) { $hashtable["WPFInstall$($property.Name)"] = $property.Value }
            $script:sync.configs.applicationsHashtable = $hashtable
            $script:sync.configs.icons = Get-Content (Join-Path $repoRoot "config/icons.json") -Raw | ConvertFrom-Json

            $checkBoxes = @(Initialize-InstallAppEntries -TargetElement $script:panel -AppKeys @($hashtable.Keys))

            $checkBoxes.Count | Should -Be $hashtable.Count
            $script:panel.Children.Count | Should -Be $hashtable.Count
        }
    }
}
