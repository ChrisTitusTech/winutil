function Invoke-WPFUnInstall {
    <#

    .SYNOPSIS
        Uninstalls the selected programs

    #>

    if($sync.ProcessRunning){
        $msg = "[Invoke-WPFUnInstall] Install process is currently running"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $WingetInstall = (Get-WinUtilCheckBoxes)["Install"]

    if ($wingetinstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageboxTitle = "Are you sure?"
    $Messageboxbody = ("This will uninstall the following applications: `n $WingetInstall")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    $confirm = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

    if($confirm -eq "No"){return}

    Invoke-WPFRunspace -ArgumentList $WingetInstall -DebugPreference $DebugPreference -ScriptBlock {
        param($WingetInstall, $DebugPreference)

        try{
            $sync.ProcessRunning = $true

            # Install all selected programs in new window
            Install-WinUtilProgramWinget -ProgramsToInstall $WingetInstall -Manage "Uninstalling"

            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Uninstalls are Finished "
            $Messageboxbody = ("Done")
            $MessageIcon = [System.Windows.MessageBoxImage]::Information

            [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

            Write-Host "==========================================="
            Write-Host "--       Uninstalls have finished       ---"
            Write-Host "==========================================="
        }
        Catch {
            Write-Host "==========================================="
            Write-Host "--       Winget failed to install       ---"
            Write-Host "==========================================="
        }
        $sync.ProcessRunning = $False
    }
}