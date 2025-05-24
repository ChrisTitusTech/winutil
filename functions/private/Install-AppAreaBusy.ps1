function Show-WPFInstallAppBusy {
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

function Hide-WPFInstallAppBusy {
    $sync.form.Dispatcher.Invoke([action]{
        $sync.InstallAppAreaOverlay.Visibility = [Windows.Visibility]::Collapsed
        $sync.InstallAppAreaBorder.IsEnabled = $true
        $sync.InstallAppAreaScrollViewer.Effect.Radius = 0
    })
}
