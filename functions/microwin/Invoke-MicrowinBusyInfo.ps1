function Invoke-MicrowinBusyInfo {
    <#
    .DESCRIPTION
    Function to display the busy info for the Microwin process
    #>
    param(
        [string]$wip,
        [string]$warning,
        [string]$done,
        [string]$hide
    )
    if($wip) {
        $sync.form.Dispatcher.BeginInvoke([action]{
            $sync.MicrowinBusyIndicator.Visibility="Visible"
            $sync.BusyText.Text= "$wip (not interactive)"
            $sync.BusyIcon.Foreground="#FFA500"
            $sync.BusyText.Foreground="#FFA500"
        })
    } elseif($warning) {
        $sync.form.Dispatcher.BeginInvoke([action]{
            $sync.MicrowinBusyIndicator.Visibility="Visible"
            $sync.BusyText.Text=$warning
            $sync.BusyText.Foreground="#FF0000"
            $sync.BusyIcon.Foreground="#FF0000"
        })
    }
    elseif($done) {
        $sync.form.Dispatcher.BeginInvoke([action]{
            $sync.MicrowinBusyIndicator.Visibility="Visible"
            $sync.BusyText.Text=$done
            $sync.BusyText.Foreground="#00FF00"
            $sync.BusyIcon.Foreground="#00FF00"
        })
    }
    elseif($hide) {
        $sync.form.Dispatcher.BeginInvoke([action]{
            $sync.MicrowinBusyIndicator.Visibility="Hidden"
            $sync.BusyText.Foreground=$sync.Form.Resources.MicrowinBusyColor
            $sync.BusyIcon.Foreground=$sync.Form.Resources.MicrowinBusyColor
        })
    } else {
        Write-Error "Invalid parameter"
    }

    # Force the UI to process pending messages
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 50
}
