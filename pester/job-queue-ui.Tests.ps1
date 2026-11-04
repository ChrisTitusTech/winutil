# Native WPF queue layout and routed-event checks. No system-changing jobs run here.
BeforeAll {
    Add-Type -AssemblyName PresentationFramework
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $script:repoRoot 'functions/private/Start-WinUtilNextQueuedJob.ps1')
    . (Join-Path $script:repoRoot 'functions/private/Invoke-WinutilThemeChange.ps1')
    function Write-WinUtilLog { param($Message, $Level, $Component) }
}

Describe 'Native job queue controls' {
    BeforeEach {
        [xml]$xaml = Get-Content (Join-Path $script:repoRoot 'xaml/inputXML.xaml') -Raw
        $form = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
        $script:sync = [hashtable]::Synchronized(@{
            Form = $form
            preferences = @{}
            configs = @{ themes = Get-Content (Join-Path $script:repoRoot 'config/themes.json') -Raw | ConvertFrom-Json }
            ActiveJob = 'Harmless placeholder'
            JobQueue = [Collections.Generic.List[object]]::new()
            JobQueueButton = $form.FindName('JobQueueButton')
            JobQueueCount = $form.FindName('JobQueueCount')
            JobQueueRunning = $form.FindName('JobQueueRunning')
            JobQueueItems = $form.FindName('JobQueueItems')
            # Open state only: measure the actual XAML child without displaying a popup in CI.
            JobQueuePopup = [pscustomobject]@{ IsOpen = $true }
        })
        $script:queueBorder = $form.FindName('JobQueuePopup').Child
    }

    AfterEach {
        $script:sync.Form.Close()
        Remove-Variable sync, queueBorder -Scope Script
    }

    It 'keeps the running header visible while every queued row remains reachable (<Theme>)' -TestCases @(
        @{ Theme = 'Light' }
        @{ Theme = 'Dark' }
    ) {
        param($Theme)
        Invoke-WinutilThemeChange -theme $Theme
        foreach ($index in 1..35) {
            $script:sync.JobQueue.Add([pscustomobject]@{ Id = "$index"; Name = "Harmless queued job $index" })
        }
        Update-WinUtilJobQueueUI
        $script:queueBorder.Measure([Windows.Size]::new(262, [double]::PositiveInfinity))
        $script:queueBorder.Arrange([Windows.Rect]::new(0, 0, $script:queueBorder.DesiredSize.Width, $script:queueBorder.DesiredSize.Height))
        $script:queueBorder.UpdateLayout()
        $scroll = $script:sync.JobQueueItems.Parent
        $scroll | Should -BeOfType ([Windows.Controls.ScrollViewer])
        $scroll.ViewportHeight | Should -BeGreaterThan 0
        $scroll.ViewportHeight | Should -BeLessOrEqual 240
        $scroll.ExtentHeight | Should -BeGreaterThan $scroll.ViewportHeight
        $scroll.ComputedVerticalScrollBarVisibility | Should -Be ([Windows.Visibility]::Visible)
        $script:sync.JobQueueItems.Children.Count | Should -Be 35
        $headerParent = $script:sync.JobQueueRunning.Parent
        $headerParent | Should -Be $scroll.Parent
        $headerOffset = $script:sync.JobQueueRunning.TranslatePoint([Windows.Point]::new(0, 0), $script:queueBorder).Y
        $scroll.ScrollToEnd()
        $script:queueBorder.UpdateLayout()
        $scroll.VerticalOffset | Should -BeGreaterThan 0
        $script:sync.JobQueueRunning.TranslatePoint([Windows.Point]::new(0, 0), $script:queueBorder).Y | Should -Be $headerOffset
        $script:sync.JobQueueItems.Children[34].Children[0].Text | Should -Be 'Harmless queued job 35'
    }

    It 'routes row buttons by stable job identity through reorder and cancellation' {
        Invoke-WinutilThemeChange -theme Dark
        foreach ($index in 1..3) {
            $script:sync.JobQueue.Add([pscustomobject]@{ Id = "$index"; Name = "Job$index" })
        }
        Update-WinUtilJobQueueUI
        $script:sync.JobQueueItems.Children[0].Children[1].IsEnabled | Should -BeFalse
        $script:sync.JobQueueItems.Children[2].Children[2].IsEnabled | Should -BeFalse
        $script:sync.JobQueueItems.Children[1].Children[1].RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        @($script:sync.JobQueue.Name) | Should -Be @('Job2', 'Job1', 'Job3')
        $script:sync.JobQueueItems.Children[0].Children[2].RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        @($script:sync.JobQueue.Name) | Should -Be @('Job1', 'Job2', 'Job3')
        $script:sync.JobQueueItems.Children[1].Children[3].RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        @($script:sync.JobQueue.Name) | Should -Be @('Job1', 'Job3')
        $script:sync.JobQueueCount.Text | Should -Be '2'
        $script:sync.ActiveJob | Should -Be 'Harmless placeholder'
    }
}