function Invoke-WinUtilM365Debloat {
    <#
    .SYNOPSIS
        Removes selected Microsoft 365 apps using Office Deployment Tool.

    .DESCRIPTION
        Detects installed Click-to-Run Office product and architecture, downloads Office
        Deployment Tool (winget with web fallback), then runs ODT configure with ExcludeApp entries.
    #>

    $ErrorActionPreference = "Stop"

    function Get-WinUtilWingetPath {
        $cmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source) {
            return $cmd.Source
        }

        $candidates = @(
            "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*_x64__8wekyb3d8bbwe\winget.exe",
            "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*_x86__8wekyb3d8bbwe\winget.exe",
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
        )

        foreach ($pattern in $candidates) {
            $match = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

            if ($match) {
                return $match.FullName
            }
        }

        return $null
    }

    function Get-WinUtilOdtUrl {
        $odtUrlFileRaw = "https://raw.githubusercontent.com/szymon-tulodziecki/M365-Debloater/main/odt_url.txt"
        try {
            $response = Invoke-WebRequest -Uri $odtUrlFileRaw -UseBasicParsing
            return [string]$response.Content
        } catch {
            return $null
        }
    }

    $productIdMap = @{
        "O365ProPlusRetail" = "O365ProPlusRetail"
        "O365BusinessRetail" = "O365BusinessRetail"
        "ProPlus2019Retail" = "ProPlus2019Retail"
        "ProPlus2024Volume" = "ProPlus2024Volume"
    }

    # Matches the app mapping from the M365 Debloater implementation.
    $excludeAppIds = @(
        "Lync",
        "Teams",
        "OneDrive",
        "Outlook",
        "Publisher",
        "Access",
        "OneNote",
        "Bing"
    )

    $detectedProductId = "O365BusinessRetail"
    $detectedArch = "64"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

    if (-not (Test-Path $regPath)) {
        Write-Warning "Microsoft 365 Click-to-Run was not detected on this system."
        return
    }

    try {
        $releaseIds = [string](Get-ItemPropertyValue -Path $regPath -Name "ProductReleaseIds" -ErrorAction SilentlyContinue)
        $platform = [string](Get-ItemPropertyValue -Path $regPath -Name "Platform" -ErrorAction SilentlyContinue)
        $version = [string](Get-ItemPropertyValue -Path $regPath -Name "VersionToReport" -ErrorAction SilentlyContinue)

        if ($platform -and $platform.Equals("x86", [System.StringComparison]::OrdinalIgnoreCase)) {
            $detectedArch = "32"
        }

        foreach ($key in $productIdMap.Keys) {
            if ($releaseIds -and $releaseIds.IndexOf($key, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $detectedProductId = $productIdMap[$key]
                break
            }
        }

        Write-Host "Detected M365 product: $detectedProductId | $platform | v$version"
    } catch {
        Write-Warning "Office detection from registry failed. Falling back to defaults."
    }

    $odtDir = Join-Path $env:TEMP "odt"
    $odtDownloadDir = Join-Path $env:TEMP "WinUtil-M365\odt-download"
    $xmlPath = Join-Path $env:TEMP "winutil_m365_odt_config.xml"
    $wingetPath = $null
    $downloadedExe = $null

    try {
        Write-Host "Preparing Office Deployment Tool..."

        if (Test-Path $odtDir) {
            Remove-Item -Path $odtDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $odtDownloadDir) {
            Remove-Item -Path $odtDownloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Path $odtDir -Force | Out-Null
        New-Item -ItemType Directory -Path $odtDownloadDir -Force | Out-Null

        $wingetPath = Get-WinUtilWingetPath
        if ($wingetPath) {
            Write-Host "Downloading ODT using winget..."
            & $wingetPath download --id Microsoft.Office.DeploymentTool --location $odtDownloadDir --accept-source-agreements --accept-package-agreements | Out-Null

            if ($LASTEXITCODE -eq 0) {
                $downloadedExe = Get-ChildItem -Path $odtDownloadDir -Filter "officedeploymenttool*.exe" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
            } else {
                Write-Warning "winget download failed with exit code: $LASTEXITCODE. Falling back to direct download."
            }
        } else {
            Write-Warning "winget.exe was not found. Falling back to direct download."
        }

        if (-not $downloadedExe) {
            $odtUrlRaw = Get-WinUtilOdtUrl
            $odtUrl = if ($odtUrlRaw) { $odtUrlRaw.Trim() } else { "" }
            if ([string]::IsNullOrWhiteSpace($odtUrl)) {
                throw "Could not resolve ODT download URL from odt_url.txt"
            }

            $fallbackExe = Join-Path $odtDownloadDir "officedeploymenttool.exe"
            Write-Host "Downloading ODT from URL fallback..."
            Invoke-WebRequest -Uri $odtUrl -OutFile $fallbackExe -UseBasicParsing
            $downloadedExe = Get-Item -Path $fallbackExe -ErrorAction Stop
        }

        Start-Process -FilePath $downloadedExe.FullName -ArgumentList "/extract:`"$odtDir`" /quiet" -Wait

        $odtSetupPath = Join-Path $odtDir "setup.exe"
        if (-not (Test-Path $odtSetupPath)) {
            throw "setup.exe was not found after ODT extraction."
        }

        Write-Host "Generating ODT configuration..."
        $excludeAppXml = ($excludeAppIds | ForEach-Object {
            "      <ExcludeApp ID=`"$_`" />"
        }) -join "`r`n"

        $xmlContent = @"
<Configuration>
  <Add OfficeClientEdition="$detectedArch" Channel="Current">
    <Product ID="$detectedProductId">
      <Language ID="MatchOS" />
$excludeAppXml
    </Product>
  </Add>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

        Set-Content -Path $xmlPath -Value $xmlContent -Encoding ascii

        Write-Host "Running ODT configuration..."
        $odtProcess = Start-Process -FilePath $odtSetupPath -ArgumentList "/configure `"$xmlPath`"" -Wait -PassThru

        if ($odtProcess.ExitCode -ne 0) {
            throw "ODT exited with code: $($odtProcess.ExitCode)"
        }

        Write-Host "Microsoft 365 debloat finished successfully. A reboot is recommended." -ForegroundColor Green
    } catch {
        Write-Warning "M365 debloat failed: $($_.Exception.Message)"
    } finally {
        if (Test-Path $xmlPath) {
            Remove-Item -Path $xmlPath -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $odtDownloadDir) {
            Remove-Item -Path $odtDownloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
