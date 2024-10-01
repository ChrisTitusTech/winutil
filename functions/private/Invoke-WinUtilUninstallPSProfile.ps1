function Invoke-WinUtilUninstallPSProfile {
    <#
    .SYNOPSIS
        # Uninstalls the CTT PowerShell profile then restores the original profile
    #>

    Invoke-WPFRunspace -ArgumentList $PROFILE -DebugPreference $DebugPreference -ScriptBlock {
        # PSProfile parameter
        param ($PSProfile)

        # Function to uninstall Nerd Fonts
        function Uninstall-NerdFonts {
            param (
                [string]$FontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts",
                [string]$FontFamilyName = "CaskaydiaCoveNerdFont"
            )

            $Fonts = Get-ChildItem $FontsPath -Recurse -Filter "*.ttf" | Where-Object { $_.Name -match $FontFamilyName }
            if ($Fonts) {
                Write-Host "===> Uninstalling Nerd Fonts... <===" -ForegroundColor Yellow
                $Fonts | ForEach-Object {
                    if (Test-Path "$($_.FullName)") {
                        Remove-Item "$($_.FullName)"
                    }
                }
            } else {
                Write-Host "===> Already Uninstalled Nerd Fonts. <===" -ForegroundColor Yellow
            }
        }

        # Check if profile is installed
        $PSProfileHash = Get-Content "$PSProfile.hash"
        if ((Get-FileHash $PSProfile).Hash -eq $PSProfileHash) {
            # Uninstall OhMyPosh
            try {
                if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
                    Write-Host "===> Uninstalling OhMyPosh... <===" -ForegroundColor Yellow
                    winget uninstall -e --id JanDeDobbeleer.OhMyPosh
                }
            } catch {
                Write-Error "Failed to uninstall OhMyPosh. Error: $_" -ForegroundColor Red
            }

            # Uninstall Nerd Fonts
            try {
                [string]$FontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
                [string]$FontFamilyName = "CaskaydiaCoveNerdFont"
                Uninstall-NerdFonts -FontsPath $FontsPath -FontFamilyName $FontFamilyName
            } catch {
                Write-Error "Failed to uninstall Nerd Fonts. Error: $_" -ForegroundColor Red
            }

            # Uninstall Terminal-Icons
            try {
                if (Get-Module -ListAvailable Terminal-Icons) {
                    Write-Host "===> Uninstalling Terminal-Icons... <===" -ForegroundColor Yellow
                    Uninstall-Module -Name Terminal-Icons
                }
            } catch {
                Write-Error "Failed to uninstall Terminal-Icons. Error: $_" -ForegroundColor Red
            }

            # Uninstall Zoxide
            try {
                if (Get-Command zoxide -ErrorAction SilentlyContinue) {
                    Write-Host "===> Uninstalling Zoxide... <===" -ForegroundColor Yellow
                    winget uninstall -e --id ajeetdsouza.zoxide
                }
            } catch {
                Write-Error "Failed to uninstall Zoxide. Error: $_" -ForegroundColor Red
            }

            # Uninstall CTT PowerShell profile
            try {
                Remove-Item $PSProfile
                Write-Host "Profile has been uninstalled. Please restart your shell to reflect the changes!" -ForegroundColor Magenta
            } catch {
                Write-Error "Failed to uninstall profile. Error: $_" -ForegroundColor Red
            }

            # Restore PowerShell profile backup
            try {
                if (Test-Path "$PSProfile.bak") {
                    Move-Item "$PSProfile.bak" $PSProfile
                    Write-Host "===> Restored Profile Backup. <===" -ForegroundColor Yellow
                }
            } catch {
                Write-Error "Failed to restore profile backup. Error: $_" -ForegroundColor Red
            }

            # Silently cleanup $PSProfile.hash file
            Remove-Item "$PSProfile.hash" | Out-Null
        } else {
            Write-Host "===> Already Uninstalled CTT PowerShell Profile. <===" -ForegroundColor Magenta
        }
    }
}