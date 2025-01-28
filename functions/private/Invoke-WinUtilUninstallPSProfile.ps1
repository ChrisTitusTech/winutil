function Invoke-WinUtilUninstallPSProfile {
    <#
    .SYNOPSIS
        # Uninstalls the CTT PowerShell profile then restores the original profile.
    #>

    Invoke-WPFRunspace -ArgumentList $PROFILE -DebugPreference $DebugPreference -ScriptBlock {
        # Remap the automatic built-in $PROFILE variable to the parameter named $PSProfile.
        param ($PSProfile)

        # Helper function used to uninstall a specific Nerd Fonts font package.
        function Uninstall-NerdFonts {
            # Define the parameters block for the Uninstall-NerdFonts function.
            param (
                [string]$FontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts",
                [string]$FontFamilyName = "CaskaydiaCoveNerdFont"
            )

            # Get the list of installed fonts as specified by the FontFamilyName parameter.
            $Fonts = Get-ChildItem $FontsPath -Recurse -Filter "*.ttf" | Where-Object { $_.Name -match $FontFamilyName }

            # Check if the specified fonts are currently installed on the system.
            if ($Fonts) {
                # Let the user know that the Nerd Fonts are currently being uninstalled.
                Write-Host "===> Uninstalling: Nerd Fonts... <===" -ForegroundColor Yellow

                # Loop over the font files and remove each installed font file one-by-one.
                $Fonts | ForEach-Object {
                    # Check if the font file exists on the disk before attempting to remove it.
                    if (Test-Path "$($_.FullName)") {
                        # Remove the found font files from the disk; uninstalling the font.
                        Remove-Item "$($_.FullName)"
                    }
                }
            }

            # Let the user know that the Nerd Fonts package has been uninstalled from the system.
            if (-not $Fonts) {
                Write-Host "===> Successfully Uninstalled: Nerd Fonts. <===" -ForegroundColor Yellow
            }

        }

        # Helper function used to uninstall a specific Nerd Fonts font corresponding registry keys.
        function Uninstall-NerdFontRegKeys {
            # Define the parameters block for the Uninstall-NerdFontsRegKey function.
            param (
                [string]$FontsRegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
                [string]$FontFamilyName = "CaskaydiaCove"
            )

            try {
                # Get all properties (font registrations) from the registry path
                $registryProperties = Get-ItemProperty -Path $FontsRegPath

                # Filter and remove properties that match the font family name
                $registryProperties.PSObject.Properties |
                Where-Object { $_.Name -match $FontFamilyName } |
                ForEach-Object {
                    If ($_.Name -like "*$FontFamilyName*") {
                        Remove-ItemProperty -path $FontsRegPath -Name $_.Name -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                Write-Host "Error removing registry keys: $($_.exception.message)" -ForegroundColor Red
            }
        }

        # Check if Chris Titus Tech's PowerShell profile is currently available in the PowerShell profile folder.
        if (Test-Path $PSProfile -PathType Leaf) {
            # Set the GitHub repo path used for looking up the name of Chris Titus Tech's powershell-profile repo.
            $GitHubRepoPath = "ChrisTitusTech/powershell-profile"

            # Get the unique identifier used to test for the presence of Chris Titus Tech's PowerShell profile.
            $PSProfileIdentifier = (Invoke-RestMethod "https://api.github.com/repos/$GitHubRepoPath").full_name

            # Check if Chris Titus Tech's PowerShell profile is currently installed in the PowerShell profile folder.
            if ((Get-Content $PSProfile) -match $PSProfileIdentifier) {
                # Attempt to uninstall Chris Titus Tech's PowerShell profile from the PowerShell profile folder.
                try {
                    # Get the content of the backup PowerShell profile and store it in-memory.
                    $PSProfileContent = Get-Content "$PSProfile.bak"

                    # Store the flag used to check if OhMyPosh is in use by the backup PowerShell profile.
                    $OhMyPoshInUse = $PSProfileContent -match "oh-my-posh init"

                    # Check if OhMyPosh is not currently in use by the backup PowerShell profile.
                    if (-not $OhMyPoshInUse) {
                        # If OhMyPosh is currently installed attempt to uninstall it from the system.
                        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
                            # Let the user know that OhMyPosh is currently being uninstalled from their system.
                            Write-Host "===> Uninstalling: OhMyPosh... <===" -ForegroundColor Yellow

                            # Attempt to uninstall OhMyPosh from the system with the WinGet package manager.
                            winget uninstall -e --id JanDeDobbeleer.OhMyPosh
                        }
                    } else {
                        # Let the user know that the uninstallation of OhMyPosh has been skipped because it is in use.
                        Write-Host "===> Skipped Uninstall: OhMyPosh In-Use. <===" -ForegroundColor Yellow
                    }
                } catch {
                    # Let the user know that an error was encountered when uninstalling OhMyPosh.
                    Write-Host "Failed to uninstall OhMyPosh. Error: $_" -ForegroundColor Red
                }

                # Attempt to uninstall the specified Nerd Fonts package from the system.
                try {
                    # Specify the directory that the specified font package will be uninstalled from.
                    [string]$FontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

                    # Specify the name of the font package that is to be uninstalled from the system.
                    [string]$FontFamilyName = "CaskaydiaCoveNerdFont"

                    # Call the function used to uninstall the specified Nerd Fonts package from the system.
                    Uninstall-NerdFonts -FontsPath $FontsPath -FontFamilyName $FontFamilyName

                } catch {
                    # Let the user know that an error was encountered when uninstalling Nerd Fonts.
                    Write-Host "Failed to uninstall Nerd Fonts. Error: $_" -ForegroundColor Red
                }

                # Attempt to uninstall the specified Nerd Fonts registry keys from the system.
                try {
                    # Specify the registry path that the specified font registry keys will be uninstalled from.
                    [string]$FontsRegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

                    # Specify the name of the font registry keys that is to be uninstalled from the system.
                    [string]$FontFamilyName = "CaskaydiaCove"

                    # Call the function used to uninstall the specified Nerd Fonts registry keys from the system.
                    Uninstall-NerdFontRegKeys -FontsPath $FontsRegPath -FontFamilyName $FontFamilyName

                } catch {
                    # Let the user know that an error was encountered when uninstalling Nerd Font registry keys.
                    Write-Host "Failed to uninstall Nerd Font Registry Keys. Error: $_" -ForegroundColor Red
                }

                # Attempt to uninstall the Terminal-Icons PowerShell module from the system.
                try {
                    # Get the content of the backup PowerShell profile and store it in-memory.
                    $PSProfileContent = Get-Content "$PSProfile.bak"

                    # Store the flag used to check if Terminal-Icons is in use by the backup PowerShell profile.
                    $TerminalIconsInUse = $PSProfileContent -match "Import-Module" -and $PSProfileContent -match "Terminal-Icons"

                    # Check if Terminal-Icons is not currently in use by the backup PowerShell profile.
                    if (-not $TerminalIconsInUse) {
                        # If Terminal-Icons is currently installed attempt to uninstall it from the system.
                        if (Get-Module -ListAvailable Terminal-Icons) {
                            # Let the user know that Terminal-Icons is currently being uninstalled from their system.
                            Write-Host "===> Uninstalling: Terminal-Icons... <===" -ForegroundColor Yellow

                            # Attempt to uninstall Terminal-Icons from the system with Uninstall-Module.
                            Uninstall-Module -Name Terminal-Icons
                        }
                    } else {
                        # Let the user know that the uninstallation of Terminal-Icons has been skipped because it is in use.
                        Write-Host "===> Skipped Uninstall: Terminal-Icons In-Use. <===" -ForegroundColor Yellow
                    }
                } catch {
                    # Let the user know that an error was encountered when uninstalling Terminal-Icons.
                    Write-Host "Failed to uninstall Terminal-Icons. Error: $_" -ForegroundColor Red
                }

                # Attempt to uninstall the Zoxide application from the system.
                try {
                    # Get the content of the backup PowerShell profile and store it in-memory.
                    $PSProfileContent = Get-Content "$PSProfile.bak"

                    # Store the flag used to check if Zoxide is in use by the backup PowerShell profile.
                    $ZoxideInUse = $PSProfileContent -match "zoxide init"

                    # Check if Zoxide is not currently in use by the backup PowerShell profile.
                    if (-not $ZoxideInUse) {
                        # If Zoxide is currently installed attempt to uninstall it from the system.
                        if (Get-Command zoxide -ErrorAction SilentlyContinue) {
                            # Let the user know that Zoxide is currently being uninstalled from their system.
                            Write-Host "===> Uninstalling: Zoxide... <===" -ForegroundColor Yellow

                            # Attempt to uninstall Zoxide from the system with the WinGet package manager.
                            winget uninstall -e --id ajeetdsouza.zoxide
                        }
                    } else {
                        # Let the user know that the uninstallation of Zoxide been skipped because it is in use.
                        Write-Host "===> Skipped Uninstall: Zoxide In-Use. <===" -ForegroundColor Yellow
                    }
                } catch {
                    # Let the user know that an error was encountered when uninstalling Zoxide.
                    Write-Host "Failed to uninstall Zoxide. Error: $_" -ForegroundColor Red
                }

                # Attempt to uninstall the CTT PowerShell profile from the system.
                try {
                    # Try and remove the CTT PowerShell Profile file from the disk with Remove-Item.
                    Remove-Item $PSProfile

                    # Let the user know that the CTT PowerShell profile has been uninstalled from the system.
                    Write-Host "Profile has been uninstalled. Please restart your shell to reflect the changes!" -ForegroundColor Magenta
                } catch {
                    # Let the user know that an error was encountered when uninstalling the profile.
                    Write-Host "Failed to uninstall profile. Error: $_" -ForegroundColor Red
                }

                # Attempt to move the user's original PowerShell profile backup back to its original location.
                try {
                    # Check if the backup PowerShell profile exists before attempting to restore the backup.
                    if (Test-Path "$PSProfile.bak") {
                        # Restore the backup PowerShell profile and move it to its original location.
                        Move-Item "$PSProfile.bak" $PSProfile

                        # Let the user know that their PowerShell profile backup has been successfully restored.
                        Write-Host "===> Restored Profile Backup. <===" -ForegroundColor Yellow
                    }
                } catch {
                    # Let the user know that an error was encountered when restoring the profile backup.
                    Write-Host "Failed to restore profile backup. Error: $_" -ForegroundColor Red
                }

                # Silently cleanup the oldprofile.ps1 file that was created when the CTT PowerShell profile was installed.
                Remove-Item "$env:USERPROFILE\oldprofile.ps1" | Out-Null
            } else {
                # Let the user know that the CTT PowerShell profile is not installed and that the uninstallation was skipped.
                Write-Host "===> Chris Titus Tech's PowerShell Profile Not Found. Skipped Uninstallation. <===" -ForegroundColor Magenta
            }
        } else {
            # Let the user know that no PowerShell profile was found and that the uninstallation was skipped.
            Write-Host "===> No PowerShell Profile Found. Skipped Uninstallation. <===" -ForegroundColor Magenta
        }
    }
}

