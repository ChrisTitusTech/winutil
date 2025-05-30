function Show-WPFInstallAppBusy {
    <#
    .SYNOPSIS
        Displays a busy overlay in the install app area of the WPF form.
        This is used to indicate that an install or uninstall is in progress.
    .PARAMETER text
        The text to display in the busy overlay. Defaults to "Installing apps...".
    #>
    param (
        $text = "Installing apps..."
    )
    $sync.form.Dispatcher.Invoke([action]{
        $sync.InstallAppAreaOverlay.Visibility = [Windows.Visibility]::Visible
        $sync.InstallAppAreaOverlayText.Text = $text
        $sync.InstallAppAreaBorder.IsEnabled = $false
        $sync.InstallAppAreaScrollViewer.Effect.Radius = 5
        })
    }
