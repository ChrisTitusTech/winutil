BeforeAll {
    Add-Type -AssemblyName PresentationFramework
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    foreach ($file in @(
        "functions/private/Initialize-InstallAppEntry.ps1",
        "functions/private/Get-WinUtilAppEntryHandlers.ps1",
        "functions/private/Get-WinUtilEntryToolTip.ps1",
        "functions/public/Invoke-WPFRunspace.ps1"
    )) {
        . (Join-Path $repoRoot $file)
    }
}

Describe "App favicon loading" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            Form = [Windows.Window]::new()
            configs = @{ applicationsHashtable = @{
                TestApp = [pscustomobject]@{ content = "Test app"; description = "Test"; link = "https://example.com/" }
            } }
            selectedApps = @()
        })
        $script:panel = [Windows.Controls.WrapPanel]::new()
        Mock Invoke-WPFRunspace { throw "Favicon loading must not occupy the shared job pool" }
    }

    AfterEach {
        if ($script:sync.Form) { $script:sync.Form.Close() }
    }

    It "starts native image loading while creating a usable entry without queuing a job" {
        $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        $logo = $checkbox.Content.Children[0].Children[1]

        $script:panel.Children.Count | Should -Be 1
        $checkbox.Content.Children[1].Text | Should -Be "Test app"
        $logo.Source | Should -BeOfType ([Windows.Media.Imaging.BitmapImage])
        $logo.Source.CreateOptions | Should -Be ([Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache)
        $logo.Source.UriSource.AbsoluteUri | Should -Be "https://www.google.com/s2/favicons?sz=64&domain_url=https%3A%2F%2Fexample.com%2F"
        Should -Invoke Invoke-WPFRunspace -Times 0
    }

    It "creates fresh images when windows reopen in the same process" {
        $previous = $null
        foreach ($iteration in 1..13) {
            $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
            $bitmap = $checkbox.Content.Children[0].Children[1].Source
            $bitmap | Should -BeOfType ([Windows.Media.Imaging.BitmapImage])
            [object]::ReferenceEquals($previous, $bitmap) | Should -BeFalse
            $bitmap.CreateOptions | Should -Be ([Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache)
            $previous = $bitmap
            $script:sync.Form.Close()
            $script:sync.Form = [Windows.Window]::new()
            $script:panel = [Windows.Controls.WrapPanel]::new()
        }
        Should -Invoke Invoke-WPFRunspace -Times 0
    }

    It "shows the letter fallback when WPF reports a download failure" {
        $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        $icon = $checkbox.Content.Children[0]
        $logo = $icon.Children[1]
        $constructor = [Windows.ExceptionRoutedEventArgs].GetConstructors(
            [Reflection.BindingFlags]'Instance, NonPublic')[0]
        $failureEvent = $constructor.Invoke(@([Windows.Controls.Image]::ImageFailedEvent, $logo, [Exception]::new("Download failed")))
        $logo.RaiseEvent($failureEvent)

        $logo.Visibility | Should -Be "Collapsed"
        $icon.Children[0].Visibility | Should -Be "Visible"
        $script:panel.Children.Count | Should -Be 1
    }

    It "keeps the letter fallback for apps without a website" {
        $script:sync.configs.applicationsHashtable.TestApp.link = $null
        $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        $icon = $checkbox.Content.Children[0]
        $icon.Children.Count | Should -Be 1
        $icon.Children[0].Text | Should -Be "T"
        $icon.Children[0].Visibility | Should -Be "Visible"
        Should -Invoke Invoke-WPFRunspace -Times 0
    }
}
