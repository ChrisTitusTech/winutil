function Invoke-WinUtilpsProfile {
    <#
    .SYNOPSIS
        Installs & applies the CTT Powershell Profile
    #>
    Invoke-WPFRunspace -Argumentlist $PROFILE -DebugPreference $DebugPreference -ScriptBlock {
        param ( $psprofile)
        function Invoke-PSSetup {
            $url = "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $psprofile -ErrorAction SilentlyContinue
            Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
            $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                    write-host "===> Installing Profile.. <===" -ForegroundColor Yellow
                    # Starting new hidden shell process bc setup does not work in a runspace
                    Start-Process -FilePath "pwsh" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"Invoke-Expression (Invoke-WebRequest `'https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1`')`"" -WindowStyle Hidden -Wait
                    Write-Host "Profile has been installed. Please restart your shell to reflect changes!" -ForegroundColor Magenta
                    write-host "===> Finished <===" -ForegroundColor Yellow
            } else {
                Write-Host "Profile is up to date" -ForegroundColor Green
            }
        }

        if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Invoke-PSSetup
            }
            else {
                write-host "Profile requires Powershell 7, which is currently installed but not used!" -ForegroundColor Red
                # Load the necessary assembly for Windows Forms
                Add-Type -AssemblyName System.Windows.Forms
                # Display the Yes/No message box
                $question = [System.Windows.Forms.MessageBox]::Show("Profile requires Powershell 7, which is currently installed but not used! Do you want to install Profile for Powershell 7?", "Question",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question)

                # Check the result
                if ($question -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Invoke-PSSetup
                }
                else {
                    Write-Host "Not proceeding with the profile setup!"
                }
            }
        }
        else {
            write-host "Profile requires Powershell 7, which is not installed!" -ForegroundColor Red
        }
    }
}
