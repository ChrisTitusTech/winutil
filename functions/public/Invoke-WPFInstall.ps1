function Invoke-WPFInstall {
    param (
        [Parameter(Mandatory=$false)]
        [PSObject[]]$PackagesToInstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ })
    )
    <#
    .SYNOPSIS
        Installs the selected programs using winget, if one or more of the selected programs are already installed on the system, winget will try and perform an upgrade if there's a newer version to install.
    #>

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFInstall] An Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($PackagesToInstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install or upgrade"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $ManagerPreference = $sync["ManagerPreference"]

    Invoke-WPFRunspace -ParameterList @(("PackagesToInstall", $PackagesToInstall),("ManagerPreference", $ManagerPreference)) -DebugPreference $DebugPreference -ScriptBlock {
        param($PackagesToInstall, $ManagerPreference, $DebugPreference)

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToInstall -Preference $ManagerPreference

        $packagesWinget = $packagesSorted[[PackageManagers]::Winget]
        $packagesChoco = $packagesSorted[[PackageManagers]::Choco]
        $wasProcessCancelled = $false

        try {
            $sync.ProcessRunning = $true
            if($packagesWinget.Count -gt 0 -and $packagesWinget -ne "0") {
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement
                Add-Type -assembly System.Windows.Forms
                $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine')
                $user = $env:USERNAME

                Get-LocalUser | Where-Object Enabled -eq $true | ForEach-Object {
                        $validPassword = $false
                        while (-not $validPassword) {
                            try {
                                $myPasswordIsBlank = $PrincipalContext.ValidateCredentials($user, $null)
                                $validPassword = $true
                            } catch {
                                $form = New-Object System.Windows.Forms.Form
                                $form.Text = "Set password for $user"
                                $form.Size = New-Object System.Drawing.Size(500, 200)

                                $label = New-Object System.Windows.Forms.Label
                                $label.Text = 'Admin mode install failed. Set a USER password for login and user-based installation.'
                                $label.Size = New-Object System.Drawing.Size(480, 60)
                                $label.Location = New-Object System.Drawing.Point(10, 10)
                                $form.Controls.Add($label)

                                $passwordBox = New-Object System.Windows.Forms.TextBox
                                $passwordBox.Size = New-Object System.Drawing.Size(380, 20)
                                $passwordBox.UseSystemPasswordChar = $true
                                $passwordBox.Location = New-Object System.Drawing.Point(10, 125)
                                $form.Controls.Add($passwordBox)

                                $button = New-Object System.Windows.Forms.Button
                                $button.Text = 'Submit'
                                $button.Size = New-Object System.Drawing.Size(75, 23)
                                $button.Location = New-Object System.Drawing.Point(400, 125)
                                $button.Add_Click({
                                    $password = $passwordBox.Text | ConvertTo-SecureString -AsPlainText -Force
                                    if ($password) {
                                        try {
                                            Set-LocalUser -Name $user -Password $password
                                            $validPassword = $PrincipalContext.ValidateCredentials($user, $passwordBox.Text)
                                            if ($validPassword) {
                                                $form.Close()
                                            } else {
                                                [System.Windows.Forms.MessageBox]::Show('Invalid password! Please try again.')
                                            }
                                        } catch {
                                            [System.Windows.Forms.MessageBox]::Show('Error setting password!')
                                        }
                                    } else {
                                        [System.Windows.Forms.MessageBox]::Show('No password entered!')
                                    }
                                })
                                $form.Controls.Add($button)
                                $cancel =  = New-Object System.Windows.Forms.Button
                                $cancel.Text = 'Cancel'
                                $cancel.Size = New-Object System.Drawing.Size(75, 23)
                                $cancel.Location = New-Object System.Drawing.Point(25, 125)
                                $button.Add_Click({
                                    $wasProcessCancelled = $true
                                    break
                                })
                                $form.ShowDialog() | Out-Null
                            }
                        }
                }
                if($wasProcessCancelled) {
                    Show-WPFInstallAppBusy -text "Skipping Winget Apps..."
                }else{
                    Show-WPFInstallAppBusy -text "Installing apps..."
                    Install-WinUtilWinget
                    Install-WinUtilProgramWinget -Action Install -Programs $packagesWinget
                }
            }
            if($packagesChoco.Count -gt 0) {
                Install-WinUtilChoco
                Install-WinUtilProgramChoco -Action Install -Programs $packagesChoco
            }
            Hide-WPFInstallAppBusy
            Write-Host "==========================================="
            Write-Host "--      Installs have finished          ---"
            Write-Host "==========================================="
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
        } catch {
            Write-Host "==========================================="
            Write-Host "Error: $_"
            Write-Host "==========================================="
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
        $sync.ProcessRunning = $False
    }
}
