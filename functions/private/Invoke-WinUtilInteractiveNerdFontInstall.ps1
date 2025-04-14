function Invoke-WinUtilInteractiveNerdFontInstall {
    [CmdletBinding()]
    param()

    dynamicparam {
        $url = 'https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/lib/fonts.json'
        $cacheFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'winutil-nerd-fonts.json')
        $cacheDuration = [TimeSpan]::FromMinutes(2)

        function Get-FontsListFromWeb {
            try {
                $fonts = (Invoke-RestMethod -Uri $url -ErrorAction Stop -Verbose:$false -Debug:$false).fonts
                $releaseUrl = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
                foreach ($font in $fonts) {
                    $font.PSObject.Properties.Add([psnoteproperty]::new("releaseUrl", $releaseUrl))
                }
                return $fonts
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        # Check if cache exists and is valid
        $useCache = $false
        if (Test-Path $cacheFilePath) {
            $cacheAge = [DateTime]::Now - (Get-Item $cacheFilePath).LastWriteTime
            if ($cacheAge -lt $cacheDuration) {
                $useCache = $true
            }
        }

        # Get fonts list either from cache or web
        try {
            if ($useCache) {
                $fonts = Get-Content $cacheFilePath -Raw | ConvertFrom-Json
            }
            else {
                $fonts = Get-FontsListFromWeb
                $fonts | ConvertTo-Json -Depth 10 | Set-Content $cacheFilePath -Force
            }
        }
        catch {
            Write-Warning "Failed to get fonts list: $_"
            return
        }

        # Create the runtime parameter dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false # Changed to false to allow interactive mode
        $ParameterAttribute.Position = 0
        
        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)
        
        # Generate and set the ValidateSet 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($fonts.name)
        $AttributeCollection.Add($ValidateSetAttribute)
        
        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('FontName', [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add('FontName', $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $FontName = $PsBoundParameters['FontName']
        $fontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        
        # Create fonts directory if it doesn't exist
        if (-not (Test-Path $fontsPath)) {
            New-Item -Path $fontsPath -ItemType Directory -Force | Out-Null
        }

        # If no font name provided, show interactive menu
        if (-not $FontName) {
            Write-Host "`nAvailable Nerd Fonts:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $fonts.Count; $i++) {
                Write-Host "$($i + 1). $($fonts[$i].name)"
            }

            do {
                $selection = Read-Host "`nEnter the number of the font to install (or 'q' to quit)"
                
                if ($selection -eq 'q') {
                    return
                }

                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $fonts.Count) {
                    $FontName = $fonts[$index].name
                    break
                }
                else {
                    Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                }
            } while ($true)
        }

        $selectedFont = $fonts | Where-Object { $_.name -eq $FontName }
    }

    process {
        try {
            Write-Host "`nInstalling $FontName..." -ForegroundColor Yellow

            # Create temp directory
            $tempDir = Join-Path $env:TEMP "WinUtilNerdFonts"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Get latest release info
            $latestRelease = Invoke-RestMethod -Uri $selectedFont.releaseUrl
            $downloadUrl = $latestRelease.assets | 
                Where-Object { $_.name -like "*$($selectedFont.name)*" } |
                Select-Object -ExpandProperty browser_download_url -First 1

            if (-not $downloadUrl) {
                Write-Error "Could not find download URL for $FontName"
                return
            }

            # Download font
            $zipPath = Join-Path $tempDir "$($selectedFont.name).zip"
            Write-Host "Downloading from $downloadUrl..."
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

            # Extract and install fonts
            Write-Host "Extracting and installing fonts..."
            Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
            
            # Get all .ttf and .otf files
            $fontFiles = Get-ChildItem -Path $tempDir -Recurse -Include "*.ttf","*.otf"
            
            foreach ($fontFile in $fontFiles) {
                $destination = Join-Path $fontsPath $fontFile.Name
                Copy-Item -Path $fontFile.FullName -Destination $destination -Force
                
                # Add font to registry
                $fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
                $fontRegistryName = "$($fontFile.BaseName) (TrueType)"
                New-ItemProperty -Path $fontRegistryPath -Name $fontRegistryName -Value $fontFile.Name -PropertyType String -Force | Out-Null
            }

            Write-Host "Successfully installed $FontName!" -ForegroundColor Green

            # Ask if user wants to install another font
            $installMore = Read-Host "`nWould you like to install another font? (y/n)"
            if ($installMore -eq 'y') {
                Invoke-WinUtilInteractiveNerdFontInstall
            }
        }
        catch {
            Write-Error "Error installing font: $_"
            Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        }
        finally {
            # Cleanup
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
    }
}

Export-ModuleMember -Function Invoke-WinUtilInteractiveNerdFontInstall
