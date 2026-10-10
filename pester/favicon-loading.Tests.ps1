BeforeAll {
    Add-Type -AssemblyName PresentationFramework
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    foreach ($file in @(
        "functions/private/Initialize-InstallAppEntry.ps1",
        "functions/private/Get-WinUtilAppEntryHandlers.ps1",
        "functions/private/Get-WinUtilEntryToolTip.ps1",
        "functions/private/Start-WinUtilFaviconLoading.ps1",
        "functions/public/Invoke-WPFRunspace.ps1",
        "functions/public/Invoke-WPFUIThread.ps1"
    )) {
        . (Join-Path $repoRoot $file)
    }

    $encoder = [Windows.Media.Imaging.PngBitmapEncoder]::new()
    $pixel = [Windows.Media.Imaging.BitmapSource]::Create(
        1, 1, 96, 96, [Windows.Media.PixelFormats]::Bgra32, $null, [byte[]]@(0, 0, 255, 255), 4)
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($pixel))
    $stream = [IO.MemoryStream]::new()
    $encoder.Save($stream)
    $script:pngBytes = $stream.ToArray()
    $stream.Dispose()
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
        $script:pendingIcon = $null
        Mock Invoke-WPFRunspace {
            param($ArgumentList, $ScriptBlock)
            $script:entryCountAtDownload = $script:panel.Children.Count
            $script:pendingIcon = $ArgumentList
            $script:downloadBody = $ScriptBlock
        }
    }

    It "adds a usable app entry before starting the download and keeps its fallback visible" {
        $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp

        $script:entryCountAtDownload | Should -Be 1
        $checkbox.Content.Children[1].Text | Should -Be "Test app"
        $script:pendingIcon.Fallback.Text | Should -Be "T"
        $script:pendingIcon.Fallback.Visibility | Should -Be "Visible"
        $script:pendingIcon.Image.Visibility | Should -Be "Collapsed"
        $script:pendingIcon.Image.Source | Should -BeNullOrEmpty
    }

    It "loads a frozen bitmap that remains readable after its stream closes" {
        $null = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        Complete-WinUtilFaviconLoading -Image $script:pendingIcon.Image -Fallback $script:pendingIcon.Fallback -Bytes $script:pngBytes

        $bitmap = $script:pendingIcon.Image.Source
        $bitmap.IsFrozen | Should -BeTrue
        $bitmap.PixelWidth | Should -Be 1
        $pixels = [byte[]]::new(4)
        $bitmap.CopyPixels($pixels, 4, 0)
        $pixels | Should -Be @([byte]0, [byte]0, [byte]255, [byte]255)
        $script:pendingIcon.Image.Visibility | Should -Be "Visible"
        $script:pendingIcon.Fallback.Visibility | Should -Be "Collapsed"
    }

    It "keeps an app available when the downloaded bytes are not an image" {
        $checkbox = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        { Complete-WinUtilFaviconLoading -Image $script:pendingIcon.Image -Fallback $script:pendingIcon.Fallback -Bytes ([byte[]]@(1, 2, 3)) } |
            Should -Not -Throw

        $script:panel.Children.Count | Should -Be 1
        $checkbox.Content.Children[1].Text | Should -Be "Test app"
        $script:pendingIcon.Image.Source | Should -BeNullOrEmpty
        $script:pendingIcon.Fallback.Visibility | Should -Be "Visible"
    }

    It "keeps the fallback when the download fails without posting a UI update" {
        Mock Invoke-WPFUIThread {}
        $null = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        $script:pendingIcon.Url = "unsupported-favicon-scheme://example"
        { & $script:downloadBody $script:pendingIcon } | Should -Not -Throw

        Should -Invoke Invoke-WPFUIThread -Times 0
        $script:pendingIcon.Fallback.Visibility | Should -Be "Visible"
        $script:panel.Children.Count | Should -Be 1
    }

    It "ignores an icon that finishes after the interface is gone" {
        $null = Initialize-InstallAppEntry -TargetElement $script:panel -AppKey TestApp
        $script:sync.Form = $null
        Complete-WinUtilFaviconLoading -Image $script:pendingIcon.Image -Fallback $script:pendingIcon.Fallback -Bytes $script:pngBytes

        $script:pendingIcon.Image.Source | Should -BeNullOrEmpty
        $script:pendingIcon.Fallback.Visibility | Should -Be "Visible"
    }
}
