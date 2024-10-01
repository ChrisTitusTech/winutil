function Invoke-WinUtilInstallPSProfile {
    <#
    .SYNOPSIS
        Backs up your original profile then installs and applies the CTT PowerShell profile
    #>

    Invoke-WPFRunspace -ArgumentList $PROFILE -DebugPreference $DebugPreference -ScriptBlock {
        param ($PSProfile)
        function Invoke-PSSetup {
            $url = "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $OldHash = Get-FileHash $PSProfile -ErrorAction SilentlyContinue
            Invoke-RestMethod $url -OutFile "$env:TEMP/Microsoft.PowerShell_profile.ps1"
            $NewHash = Get-FileHash "$env:TEMP/Microsoft.PowerShell_profile.ps1"
            if (!(Test-Path "$PSProfile.hash")) {
                $NewHash.Hash | Out-File "$PSProfile.hash"
            }

            if ($NewHash.Hash -ne $OldHash.Hash) {
                if (Test-Path "$env:USERPROFILE\oldprofile.ps1") {
                    Write-Host "===> Backup File Exists... <===" -ForegroundColor Yellow
                    Write-Host "===> Moving Backup File... <===" -ForegroundColor Yellow
                    Copy-Item "$env:USERPROFILE\oldprofile.ps1" "$PSProfile.bak"
                    Write-Host "===> Profile Backup: Done. <===" -ForegroundColor Yellow
                } else {
                    if ((Test-Path $PSProfile) -and (-not (Test-Path "$PSProfile.bak"))) {
                        Write-Host "===> Backing Up Profile... <===" -ForegroundColor Yellow
                        Copy-Item -Path $PSProfile -Destination "$PSProfile.bak"
                        Write-Host "===> Profile Backup: Done. <===" -ForegroundColor Yellow
                    }
                }

                Write-Host "===> Installing Profile... <===" -ForegroundColor Yellow
                # Starting new hidden shell process because setup does not work in a runspace
                Start-Process -FilePath "pwsh" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"Invoke-Expression (Invoke-WebRequest `'https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1`')`"" -WindowStyle Hidden -Wait
                Write-Host "Profile has been installed. Please restart your shell to reflect the changes!" -ForegroundColor Magenta
                Write-Host "===> Finished Profile Setup <===" -ForegroundColor Yellow
            } else {
                Write-Host "Profile is up to date" -ForegroundColor Magenta
            }
        }

        if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Invoke-PSSetup
            }
            else {
                Write-Host "Profile requires Powershell 7, which is currently installed but not used!" -ForegroundColor Red
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
                    Write-Host "Not proceeding with the profile setup!" -ForegroundColor Magenta
                }
            }
        }
        else {
            Write-Host "Profile requires Powershell 7, which is not installed!" -ForegroundColor Red
        }
    }
}
