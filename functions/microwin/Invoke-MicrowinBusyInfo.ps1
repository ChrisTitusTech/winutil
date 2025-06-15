function Invoke-MicrowinBusyInfo {
    <#
    .DESCRIPTION
    Function to display the busy info for the Microwin process
    #>
    [CmdletBinding(DefaultParameterSetName='done')]
    param(
        [Parameter(ParameterSetName='wip', Mandatory, Position = 0)]
        [Parameter(ParameterSetName='warning', Mandatory, Position = 0)]
        [Parameter(ParameterSetName='done', Mandatory, Position = 0)]
        [Parameter(ParameterSetName='hide', Mandatory, Position = 0)]
        [ValidateSet('wip', 'warning', 'done', 'hide')]
        [string]$action,

        [Parameter(ParameterSetName='wip', Mandatory, Position = 1)]
        [Parameter(ParameterSetName='warning', Mandatory, Position = 1)]
        [Parameter(ParameterSetName='done', Mandatory, Position = 1)]
        [string]$message,

        [Parameter(ParameterSetName='wip', Position = 2)] [bool]$interactive = $false
    )

    switch ($action) {
        "wip" {
            $sync.form.Dispatcher.BeginInvoke([action]{
                $sync.MicrowinBusyIndicator.Visibility="Visible"
                $finalMessage = ""
                if ($interactive -eq $false) {
                    $finalMessage += "Please wait. "
                }
                $finalMessage += $message
                $sync.BusyText.Text = $finalMessage
                $sync.BusyIcon.Foreground="#FFA500"
                $sync.BusyText.Foreground="#FFA500"
            })
        }
        "warning" {
            $sync.form.Dispatcher.BeginInvoke([action]{
                $sync.MicrowinBusyIndicator.Visibility="Visible"
                $sync.BusyText.Text=$message
                $sync.BusyText.Foreground="#FF0000"
                $sync.BusyIcon.Foreground="#FF0000"
            })
        }
        "done" {
            $sync.form.Dispatcher.BeginInvoke([action]{
                $sync.MicrowinBusyIndicator.Visibility="Visible"
                $sync.BusyText.Text=$message
                $sync.BusyText.Foreground="#00FF00"
                $sync.BusyIcon.Foreground="#00FF00"
            })
        }
        "hide" {
            $sync.form.Dispatcher.BeginInvoke([action]{
                $sync.MicrowinBusyIndicator.Visibility="Hidden"
                $sync.BusyText.Foreground=$sync.Form.Resources.MicrowinBusyColor
                $sync.BusyIcon.Foreground=$sync.Form.Resources.MicrowinBusyColor
            })
        }
    }

    # Force the UI to process pending messages
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 50
}
