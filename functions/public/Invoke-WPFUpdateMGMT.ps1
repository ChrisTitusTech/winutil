
function Invoke-WinUtilUpdateInstall {

    <#
    .SYNOPSIS
        Installs Windows updates using the Initialize-WindowsUpdateModule and Install-WindowsUpdate cmdlets.

    .PARAMETER Params
        A hashtable containing the parameters for the Install-WindowsUpdate cmdlet.

    #>

    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )

    try {
        Initialize-WindowsUpdateModule
        Install-WindowsUpdate @Params
        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
    }
    catch {
        Write-Host "Error installing updates: $_" -ForegroundColor Red
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    }
}

function Invoke-WPFUpdateMGMT {

    <#
    .SYNOPSIS
        Manages Windows Update Installation

    .PARAMETER Selected
        A switch parameter that indicates whether to install only selected updates.

    .PARAMETER All
        A switch parameter that indicates whether to install all available updates.

    #>

    param (
        [switch]$Selected,
        [switch]$All
    )

    # Prepare common installation parameters
    $params = @{
        Confirm = $false
        IgnoreReboot = $true
        IgnoreRebootRequired = $true
    }

    if ($sync["WPFUpdateVerbose"].IsChecked) {
        $params['Verbose'] = $true
    }

    try {
        if ($All) {
            Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo"
            Invoke-WinUtilUpdateControls -state $false
            Invoke-WPFRunspace -ArgumentList $params -DebugPreference $DebugPreference -ScriptBlock {
                param ($params)

                try {
                    Write-Host "Installing all available updates..."
                    Invoke-WinUtilUpdateInstall -Params $params
                    Write-Host "All available updates installed successfully"
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
                } catch {
                    Write-Host "Error installing updates: $_" -ForegroundColor Red
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
                }
            }
            Invoke-WinUtilUpdateControls -state $true
        } elseif ($Selected -and $sync["WPFUpdatesList"].SelectedItems.Count -gt 0) {
            Write-Host "Installing selected updates..."

            # Get selected updates
            $selectedUpdates = $sync["WPFUpdatesList"].SelectedItems | ForEach-Object {
                [PSCustomObject]@{
                        ComputerName = $_.ComputerName
                        Title = $_.LongTitle
                        KB = $_.KB
                    }
                }

            # Install selected updates
            Invoke-WPFRunspace -ParameterList @(("selectedUpdates", $selectedUpdates),("params", $params)) -DebugPreference $DebugPreference -ScriptBlock {
                param ($selectedUpdates, $params)

                $sync.form.Dispatcher.Invoke([action] {
                    Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo"
                    Invoke-WinUtilUpdateControls -state $false
                })

                foreach ($update in $selectedUpdates) {
                    Write-Host "Installing update $($update.Title) on $($update.ComputerName)"

                    # Prepare update-specific parameters
                    $updateParams = $params.Clone()
                    $updateParams['ComputerName'] = $update.ComputerName

                    # Install update based on KB or Title
                    if ($update.KB) {
                        Get-WindowsUpdate -KBArticleID $update.KB -Install @updateParams
                    } else {
                        Get-WindowsUpdate -Title $update.Title -Install @updateParams
                    }
                }

                $sync.form.Dispatcher.Invoke([action] {
                    Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
                    Invoke-WinUtilUpdateControls -state $true
                })
                Write-Host "Selected updates installed successfully"
            }
        } else {
            Write-Host "No updates selected"
        }

    } catch {
        Write-Host "Error installing updates: $_" -ForegroundColor Red
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    }
}
